import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import '../models/pdf_attachment_model.dart';
import '../providers/pdf_provider.dart';
import '../services/pdf_storage_service.dart';
import '../services/pdf_text_extraction_service.dart';
import 'pdf_editor_screen.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfId;
  final String noteId;

  const PdfViewerScreen({
    Key? key,
    required this.pdfId,
    required this.noteId,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfAttachmentModel? _attachment;
  bool _isLoading = true;
  String? _error;
  bool _showAnnotationTools = false;
  String _selectedAnnotationType = 'highlight';
  Color _selectedColor = Colors.yellow;
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  int _totalPages = 0;
  String? _pdfPassword;
  bool _toolbarVisible = true;
  final TextEditingController _nameController = TextEditingController();
  String _signaturePath = '';
  
  // Available signature fonts with Google Fonts
  final List<String> _signatureFonts = [
    'Dancing Script',
    'Great Vibes',
    'Allura',
    'Parisienne',
    'Sacramento',
    'Tangerine',
    'Satisfy',
    'Kaushan Script',
  ];
  
  String _selectedFont = 'Dancing Script';
  
  // Signature mode: 'text' or 'image'
  String _signatureMode = 'text';
  File? _uploadedSignatureImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  void _toggleToolbarVisibility() {
    setState(() {
      _toolbarVisible = !_toolbarVisible;
    });
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final attachment = PdfStorageService.getPdfAttachment(widget.pdfId);
      if (attachment == null) {
        setState(() {
          _error = 'PDF not found in database';
          _isLoading = false;
        });
        return;
      }

      // Quick file existence check without decompression
      final file = File(attachment.filePath);
      if (!await file.exists()) {
        setState(() {
          _error = 'PDF file not found at: ${attachment.filePath}';
          _isLoading = false;
        });
        return;
      }

      // Get password if PDF is encrypted
      if (attachment.isEncrypted) {
        _pdfPassword = await PdfStorageService.getPdfPassword(widget.pdfId);
        
        // If no password stored, prompt user
        if (_pdfPassword == null || _pdfPassword!.isEmpty) {
          final enteredPassword = await _showPasswordDialog();
          if (enteredPassword == null || enteredPassword.isEmpty) {
            // User cancelled or entered empty password
            setState(() {
              _error = 'Password required to open this PDF';
              _isLoading = false;
            });
            if (mounted) {
              Navigator.pop(context);
            }
            return;
          }
          _pdfPassword = enteredPassword;
          // Store password in background (non-blocking)
          PdfStorageService.storePdfPassword(widget.pdfId, enteredPassword);
        }
      }

      // Show PDF immediately
      setState(() {
        _attachment = attachment;
        _isLoading = false;
      });

      // Mark as opened in background (non-blocking)
      _markAsOpenedInBackground();
    } catch (e) {
      setState(() {
        _error = 'Failed to load PDF: $e';
        _isLoading = false;
      });
    }
  }
  
  // Mark PDF as opened in background without blocking UI
  void _markAsOpenedInBackground() {
    Future(() async {
      try {
        final provider = Provider.of<PdfProvider>(context, listen: false);
        await provider.markPdfAsOpened(widget.pdfId);
      } catch (e) {
        // Provider not available, skip marking as opened
      }
    });
  }

  void _handlePasswordError() async {
    // Prompt for password again immediately
    final enteredPassword = await _showPasswordDialog(isRetry: true);
    if (enteredPassword != null && enteredPassword.isNotEmpty) {
      setState(() {
        _pdfPassword = enteredPassword;
        _error = null;
      });
      // Store password in background (non-blocking)
      PdfStorageService.storePdfPassword(widget.pdfId, enteredPassword);
      // Reload the PDF immediately
      _loadPdf();
    } else {
      setState(() {
        _error = 'This PDF is password-protected. Please enter the correct password.';
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open PDF: Incorrect or missing password'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
  
  Future<String?> _showPasswordDialog({bool isRetry = false}) async {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isRetry ? '🔒 Incorrect Password' : '🔒 Password Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRetry
                  ? 'The password you entered is incorrect. Please try again.'
                  : 'This PDF is password-protected. Please enter the password to open it.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                hintText: 'Enter password',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.isNotEmpty) {
                Navigator.pop(context, passwordController.text);
              }
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchInPdf(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final provider = Provider.of<PdfProvider>(context, listen: false);
      final results = await provider.searchInPdf(
        widget.pdfId,
        query,
      );
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_attachment == null) return;

    try {
      final file = File(_attachment!.filePath);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: _attachment!.fileName,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share PDF: $e')),
      );
    }
  }

  Future<void> _openPdfEditor() async {
    if (_attachment == null) return;

    try {
      // Navigate to PDF editor
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfEditorScreen(
            pdfId: widget.pdfId,
            noteId: widget.noteId,
          ),
        ),
      );

      // Reload PDF if edited
      if (result == true) {
        _loadPdf();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open editor: $e')),
      );
    }
  }

  Future<void> _extractTextToNote() async {
    if (_attachment == null) return;

    try {
      String? text = _attachment!.extractedText;
      
      if (text == null || text.isEmpty) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        text = await PdfTextExtractionService.extractTextFromPdf(
          File(_attachment!.filePath),
        );

        Navigator.pop(context); // Close loading dialog
      }

      if (text.isNotEmpty) {
        Navigator.pop(context, text); // Return text to note editor
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to extract text: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading PDF...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _attachment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PDF Error'),
          backgroundColor: Colors.red,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Failed to Open PDF',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'PDF not found',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _toolbarVisible
          ? AppBar(
              title: Text(_attachment!.fileName),
              actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchResults = [];
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openPdfEditor,
            tooltip: 'Edit PDF',
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: _extractTextToNote,
            tooltip: 'Extract text to note',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'annotations':
                  setState(() {
                    _showAnnotationTools = !_showAnnotationTools;
                  });
                  break;
                case 'info':
                  _showPdfInfo();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'annotations',
                child: Row(
                  children: [
                    Icon(_showAnnotationTools ? Icons.edit_off : Icons.edit),
                    const SizedBox(width: 8),
                    Text(_showAnnotationTools ? 'Hide Annotations' : 'Show Annotations'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('PDF Info'),
                  ],
                ),
              ),
            ],
          ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton(
        onPressed: _showSignatureDialog,
        tooltip: 'Add Signature',
        child: const Icon(Icons.edit_document),
      ),
      body: Column(
        children: [
          if (_isSearching && _toolbarVisible)
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search in PDF...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: _searchInPdf,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${_searchResults.length} results'),
                ],
              ),
            ),
          if (_showAnnotationTools && _toolbarVisible)
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Annotation: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Highlight'),
                      selected: _selectedAnnotationType == 'highlight',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedAnnotationType = 'highlight');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Underline'),
                      selected: _selectedAnnotationType == 'underline',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedAnnotationType = 'underline');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Comment'),
                      selected: _selectedAnnotationType == 'comment',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedAnnotationType = 'comment');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildColorPicker(),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleToolbarVisibility,
                child: SfPdfViewer.file(
                  File(_attachment!.filePath),
                  key: ValueKey(_attachment!.id),
                  controller: _pdfViewerController,
                  password: _pdfPassword ?? '',
                  maxZoomLevel: 6,
                  enableDoubleTapZooming: true,
                  pageSpacing: 8,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  canShowPasswordDialog: false,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    setState(() {
                      _totalPages = details.document.pages.count;
                      _currentPage = _pdfViewerController.pageNumber;
                    });
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                      _totalPages = _pdfViewerController.pageCount;
                    });
                  },
                  onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                    // Handle password-related errors
                    if (details.description.toLowerCase().contains('password') || 
                        details.description.toLowerCase().contains('encrypted')) {
                      _handlePasswordError();
                    } else {
                      setState(() {
                        _error = 'Failed to load PDF: ${details.description}';
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            Container(
              height: 150,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      child: Text('${result.pageNumber}'),
                    ),
                    title: Text(
                      result.context,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () async {
                      _pdfViewerController.jumpToPage(result.pageNumber);
                    },
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: _attachment != null && _toolbarVisible
          ? Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _totalPages > 0
                        ? 'Page $_currentPage / $_totalPages'
                        : 'Pages: ${_attachment!.pageCount}',
                  ),
                  Text('Size: ${_attachment!.fileSizeFormatted}'),
                  if (_attachment!.isEncrypted)
                    const Icon(Icons.lock, size: 16),
                  if (_attachment!.isCompressed)
                    const Icon(Icons.compress, size: 16),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.purple,
    ];

    return PopupMenuButton<Color>(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _selectedColor,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onSelected: (color) {
        setState(() => _selectedColor = color);
      },
      itemBuilder: (context) => colors.map((color) {
        return PopupMenuItem<Color>(
          value: color,
          child: Container(
            width: 100,
            height: 30,
            color: color,
          ),
        );
      }).toList(),
    );
  }

  void _showPdfInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('File Name', _attachment!.fileName),
            _buildInfoRow('Pages', '${_attachment!.pageCount}'),
            _buildInfoRow('Size', _attachment!.fileSizeFormatted),
            _buildInfoRow('Uploaded', _formatDate(_attachment!.uploadedAt)),
            if (_attachment!.lastOpenedAt != null)
              _buildInfoRow('Last Opened', _formatDate(_attachment!.lastOpenedAt!)),
            _buildInfoRow('Encrypted', _attachment!.isEncrypted ? 'Yes' : 'No'),
            _buildInfoRow('Compressed', _attachment!.isCompressed ? 'Yes' : 'No'),
            if (_attachment!.annotations.isNotEmpty)
              _buildInfoRow('Annotations', '${_attachment!.annotations.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Generate signature from name with selected Google Font
  Future<Uint8List> _generateSignature(String name) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(300, 140);
    
    // Draw signature background
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Adjust font size based on name length
    const baseFontSize = 48.0;
    final fontSize = name.length > 15 
        ? baseFontSize * 0.7 
        : name.length > 10 
          ? baseFontSize * 0.85 
          : baseFontSize;
    
    // Get Google Font text style based on selected font
    TextStyle textStyle;
    switch (_selectedFont) {
      case 'Dancing Script':
        textStyle = GoogleFonts.dancingScript(
          fontSize: fontSize,
          color: Colors.black,
          fontWeight: FontWeight.w600,
        );
        break;
      case 'Great Vibes':
        textStyle = GoogleFonts.greatVibes(
          fontSize: fontSize,
          color: Colors.black,
        );
        break;
      case 'Allura':
        textStyle = GoogleFonts.allura(
          fontSize: fontSize,
          color: Colors.black,
        );
        break;
      case 'Parisienne':
        textStyle = GoogleFonts.parisienne(
          fontSize: fontSize,
          color: Colors.black,
        );
        break;
      case 'Sacramento':
        textStyle = GoogleFonts.sacramento(
          fontSize: fontSize,
          color: Colors.black,
        );
        break;
      case 'Tangerine':
        textStyle = GoogleFonts.tangerine(
          fontSize: fontSize * 1.2,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        );
        break;
      case 'Satisfy':
        textStyle = GoogleFonts.satisfy(
          fontSize: fontSize,
          color: Colors.black,
        );
        break;
      case 'Kaushan Script':
        textStyle = GoogleFonts.kaushanScript(
          fontSize: fontSize,
          color: Colors.black,
        );
        break;
      default:
        textStyle = GoogleFonts.dancingScript(
          fontSize: fontSize,
          color: Colors.black,
        );
    }
    
    final textSpan = TextSpan(text: name, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(minWidth: 0, maxWidth: size.width - 40);
    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    
    textPainter.paint(canvas, offset);
    
    // Add a subtle underline
    final lineY = offset.dy + textPainter.height + 4;
    final linePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(offset.dx, lineY),
      Offset(offset.dx + textPainter.width, lineY),
      linePaint,
    );
    
    // Convert to image
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  // Save signature to temporary file
  Future<String> _saveSignature(Uint8List signatureData) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(signatureData);
    return file.path;
  }

  // Pick signature image from gallery or camera with cropping
  Future<void> _pickSignatureImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        // Crop the image
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressQuality: 100,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Signature',
              toolbarColor: Theme.of(context).colorScheme.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              hideBottomControls: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
            IOSUiSettings(
              title: 'Crop Signature',
              aspectRatioLockEnabled: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
            WebUiSettings(
              context: context,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _uploadedSignatureImage = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick/crop image: $e')),
        );
      }
    }
  }

  // Show signature dialog
  Future<void> _showSignatureDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Add Signature'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode selector tabs
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'text',
                          label: Text('Text Signature'),
                          icon: Icon(Icons.text_fields),
                        ),
                        ButtonSegment<String>(
                          value: 'image',
                          label: Text('Upload Image'),
                          icon: Icon(Icons.image),
                        ),
                      ],
                      selected: {_signatureMode},
                      onSelectionChanged: (Set<String> newSelection) {
                        dialogSetState(() {
                          _signatureMode = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Text signature mode
                    if (_signatureMode == 'text') ...[
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          dialogSetState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      // Font selection dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFont,
                        decoration: const InputDecoration(
                          labelText: 'Signature Style',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.font_download),
                        ),
                        items: _signatureFonts.map((String font) {
                          TextStyle fontStyle;
                          switch (font) {
                            case 'Dancing Script':
                              fontStyle = GoogleFonts.dancingScript(fontSize: 16);
                              break;
                            case 'Great Vibes':
                              fontStyle = GoogleFonts.greatVibes(fontSize: 18);
                              break;
                            case 'Allura':
                              fontStyle = GoogleFonts.allura(fontSize: 18);
                              break;
                            case 'Parisienne':
                              fontStyle = GoogleFonts.parisienne(fontSize: 16);
                              break;
                            case 'Sacramento':
                              fontStyle = GoogleFonts.sacramento(fontSize: 18);
                              break;
                            case 'Tangerine':
                              fontStyle = GoogleFonts.tangerine(fontSize: 20, fontWeight: FontWeight.bold);
                              break;
                            case 'Satisfy':
                              fontStyle = GoogleFonts.satisfy(fontSize: 16);
                              break;
                            case 'Kaushan Script':
                              fontStyle = GoogleFonts.kaushanScript(fontSize: 16);
                              break;
                            default:
                              fontStyle = GoogleFonts.dancingScript(fontSize: 16);
                          }
                          return DropdownMenuItem<String>(
                            value: font,
                            child: Text(font, style: fontStyle),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            dialogSetState(() {
                              _selectedFont = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _nameController.text.isNotEmpty
                            ? FutureBuilder<Uint8List>(
                                future: _generateSignature(_nameController.text),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done &&
                                      snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.contain,
                                    );
                                  }
                                  return const Center(child: CircularProgressIndicator());
                                },
                              )
                            : const Center(child: Text('Your signature will appear here')),
                      ),
                    ],
                    
                    // Image signature mode
                    if (_signatureMode == 'image') ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _pickSignatureImage(ImageSource.gallery);
                                dialogSetState(() {});
                              },
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _pickSignatureImage(ImageSource.camera);
                                dialogSetState(() {});
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Re-crop button
                      if (_uploadedSignatureImage != null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final CroppedFile? croppedFile = await ImageCropper().cropImage(
                                  sourcePath: _uploadedSignatureImage!.path,
                                  compressQuality: 100,
                                  uiSettings: [
                                    AndroidUiSettings(
                                      toolbarTitle: 'Re-crop Signature',
                                      toolbarColor: Theme.of(context).colorScheme.primary,
                                      toolbarWidgetColor: Colors.white,
                                      initAspectRatio: CropAspectRatioPreset.original,
                                      lockAspectRatio: false,
                                      hideBottomControls: false,
                                      aspectRatioPresets: [
                                        CropAspectRatioPreset.original,
                                        CropAspectRatioPreset.square,
                                        CropAspectRatioPreset.ratio3x2,
                                        CropAspectRatioPreset.ratio4x3,
                                        CropAspectRatioPreset.ratio16x9,
                                      ],
                                    ),
                                    IOSUiSettings(
                                      title: 'Re-crop Signature',
                                      aspectRatioLockEnabled: false,
                                      aspectRatioPresets: [
                                        CropAspectRatioPreset.original,
                                        CropAspectRatioPreset.square,
                                        CropAspectRatioPreset.ratio3x2,
                                        CropAspectRatioPreset.ratio4x3,
                                        CropAspectRatioPreset.ratio16x9,
                                      ],
                                    ),
                                    WebUiSettings(
                                      context: context,
                                    ),
                                  ],
                                );

                                if (croppedFile != null) {
                                  dialogSetState(() {
                                    _uploadedSignatureImage = File(croppedFile.path);
                                  });
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to re-crop: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.crop),
                            label: const Text('Re-crop Signature'),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _uploadedSignatureImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _uploadedSignatureImage!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('No signature image selected'),
                                    SizedBox(height: 4),
                                    Text(
                                      'Choose from gallery or camera',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Add to PDF'),
                  onPressed: (_signatureMode == 'text' && _nameController.text.isEmpty) ||
                          (_signatureMode == 'image' && _uploadedSignatureImage == null)
                      ? null
                      : () async {
                          if (_signatureMode == 'text') {
                            final signatureData = await _generateSignature(_nameController.text);
                            _signaturePath = await _saveSignature(signatureData);
                          } else {
                            // Use uploaded image directly
                            _signaturePath = _uploadedSignatureImage!.path;
                          }
                          
                          if (mounted) {
                            Navigator.of(context).pop();
                            _addSignatureToPdf();
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Add signature to PDF
  Future<void> _addSignatureToPdf() async {
    if (_signaturePath.isEmpty || _attachment == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Load the PDF document
      final File pdfFile = File(_attachment!.filePath);
      final PdfDocument document = PdfDocument(inputBytes: await pdfFile.readAsBytes());
      
      // Get the last page
      final PdfPage page = document.pages[document.pages.count - 1];
      
      // Add signature to the bottom right corner
      final PdfBitmap signature = PdfBitmap(await File(_signaturePath).readAsBytes());
      page.graphics.drawImage(
        signature,
        Rect.fromLTWH(
          page.getClientSize().width - 320, // 320 = image width + margin
          page.getClientSize().height - 160, // 160 = image height + margin
          300, // image width (updated to match new signature size)
          140, // image height (updated to match new signature size)
        ),
      );

      // Save the document
      final String outputPath = path.join(
        (await getTemporaryDirectory()).path,
        'signed_${path.basename(_attachment!.filePath)}',
      );
      
      final File signedPdf = File(outputPath);
      await signedPdf.writeAsBytes(await document.save());
      document.dispose();

      // Replace the original file with the signed version
      await pdfFile.delete();
      await signedPdf.copy(pdfFile.path);
      
      // Update the UI
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        setState(() {
          // Refresh the PDF viewer
          _pdfViewerController.jumpToPage(_pdfViewerController.pageNumber);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signature added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add signature: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
