import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../models/pdf_attachment_model.dart';
import '../models/pdf_edit_models.dart';
import '../services/pdf_editing_service.dart';
import '../services/pdf_storage_service.dart';

/// Comprehensive PDF Editor Screen with rich text editing, formatting, and all features
class PdfEditorScreen extends StatefulWidget {
  final String pdfId;
  final String noteId;

  const PdfEditorScreen({
    Key? key,
    required this.pdfId,
    required this.noteId,
  }) : super(key: key);

  @override
  State<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends State<PdfEditorScreen> with SingleTickerProviderStateMixin {
  final quill.QuillController _quillController = quill.QuillController.basic();
  late TabController _tabController;
  PDFViewController? _pdfViewController;
  
  PdfAttachmentModel? _attachment;
  bool _isLoading = true;
  String? _error;
  
  // Text elements from PDF
  final List<PdfTextElement> _textElements = [];
  
  // Edit history for undo/redo
  final List<PdfEditHistory> _editHistory = [];
  final int _currentHistoryIndex = -1;
  
  // Formatting state
  double _fontSize = 12.0;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  Color _textColor = Colors.black;
  String _alignment = 'left';
  
  // Signatures and images
  final List<PdfSignature> _signatures = [];
  final List<PdfImageElement> _images = [];
  
  // Page tracking
  int _currentPage = 1;
  int _totalPages = 0;
  final String _fontFamily = 'Helvetica';
  bool _isSaving = false;

  // Undo/Redo stacks
  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPdfForEditing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _loadPdfForEditing() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final attachment = PdfStorageService.getPdfAttachment(widget.pdfId);
      if (attachment == null) {
        throw Exception('PDF not found');
      }

      // Extract text from PDF
      final extractedText = await PdfEditingService.extractPlainText(widget.pdfId);
      
      // Load into Quill editor
      final doc = quill.Document();
      doc.insert(0, extractedText);
      _quillController.document = doc;

      // Extract text elements for advanced editing
      final textElements = await PdfEditingService.extractTextElements(widget.pdfId);
      _textElements.clear();
      textElements.forEach((pageNum, elements) {
        _textElements.addAll(elements);
      });

      setState(() {
        _attachment = attachment;
        _totalPages = attachment.pageCount;
        _isLoading = false;
      });

      // Create auto-backup version
      await PdfEditingService.createVersionBackup(widget.pdfId, isAutoBackup: true);
    } catch (e) {
      setState(() {
        _error = 'Failed to load PDF for editing: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEditedPdf() async {
    setState(() => _isSaving = true);

    try {
      // Get edited text from Quill
      final plainText = _quillController.document.toPlainText();

      // Convert to text elements
      final Map<int, List<PdfTextElement>> pageElements = {};
      final lines = plainText.split('\n');
      
      double yPosition = 50.0;
      final elements = <PdfTextElement>[];
      
      for (var line in lines) {
        if (line.trim().isEmpty) {
          yPosition += 15.0;
          continue;
        }

        elements.add(PdfTextElement(
          pageNumber: _currentPage,
          text: line,
          x: 50.0,
          y: yPosition,
          width: 500.0,
          height: 20.0,
          fontSize: _fontSize,
          fontFamily: _fontFamily,
          color: '#${_textColor.value.toRadixString(16).substring(2)}',
          isBold: _isBold,
          isItalic: _isItalic,
          isUnderline: _isUnderline,
          alignment: _alignment,
        ));

        yPosition += 25.0;
      }

      pageElements[_currentPage] = elements;

      // Create new PDF with edited content
      final newPdfFile = await PdfEditingService.createPdfFromElements(
        pdfId: widget.pdfId,
        pageElements: pageElements,
        signatures: _signatures.isEmpty ? null : _signatures,
        images: _images.isEmpty ? null : _images,
      );

      // Update attachment
      final updatedAttachment = _attachment!.copyWith(
        filePath: newPdfFile.path,
        fileSize: await newPdfFile.length(),
      );
      await PdfStorageService.updatePdfAttachment(updatedAttachment);

      // Add to edit history
      _editHistory.add(PdfEditHistory(
        pdfId: widget.pdfId,
        action: 'text_edit',
        data: {'description': 'PDF edited and saved'},
        description: 'Edited PDF content',
      ));

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save PDF: $e')),
        );
      }
    }
  }

  Future<void> _addSignature() async {
    try {
      final signature = await PdfEditingService.addSignature(
        pageNumber: _currentPage,
        x: 100.0,
        y: 600.0,
        width: 150.0,
        height: 50.0,
      );

      setState(() {
        _signatures.add(signature);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signature added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add signature: $e')),
      );
    }
  }

  Future<void> _addImage() async {
    try {
      final image = await PdfEditingService.addImage(
        pageNumber: _currentPage,
        x: 100.0,
        y: 400.0,
        width: 200.0,
        height: 150.0,
      );

      setState(() {
        _images.add(image);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add image: $e')),
      );
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;

    final lastState = _undoStack.removeLast();
    _redoStack.add(_captureCurrentState());
    _restoreState(lastState);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    final nextState = _redoStack.removeLast();
    _undoStack.add(_captureCurrentState());
    _restoreState(nextState);
  }

  Map<String, dynamic> _captureCurrentState() {
    return {
      'text': _quillController.document.toPlainText(),
      'fontSize': _fontSize,
      'isBold': _isBold,
      'isItalic': _isItalic,
      'isUnderline': _isUnderline,
      'textColor': _textColor.value,
      'alignment': _alignment,
    };
  }

  void _restoreState(Map<String, dynamic> state) {
    setState(() {
      final doc = quill.Document();
      doc.insert(0, state['text']);
      _quillController.document = doc;
      _fontSize = state['fontSize'];
      _isBold = state['isBold'];
      _isItalic = state['isItalic'];
      _isUnderline = state['isUnderline'];
      _textColor = Color(state['textColor']);
      _alignment = state['alignment'];
    });
  }

  void _applyFormatting() {
    _undoStack.add(_captureCurrentState());
    _redoStack.clear();
    setState(() {});
  }

  Future<void> _showVersionHistory() async {
    final versions = await PdfEditingService.getVersions(widget.pdfId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Version History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: versions.length,
            itemBuilder: (context, index) {
              final version = versions[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${version.versionNumber}')),
                title: Text('Version ${version.versionNumber}'),
                subtitle: Text(_formatDate(version.createdAt)),
                trailing: IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () async {
                    await PdfEditingService.restoreFromVersion(
                      widget.pdfId,
                      version.versionNumber,
                    );
                    Navigator.pop(context);
                    _loadPdfForEditing();
                  },
                ),
              );
            },
          ),
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

  Future<void> _checkGrammar() async {
    final text = _quillController.document.toPlainText();
    final suggestions = PdfEditingService.checkGrammar(text);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grammar Check'),
        content: suggestions.isEmpty
            ? const Text('No issues found!')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: suggestions
                    .map((s) => ListTile(
                          leading: const Icon(Icons.warning, color: Colors.orange),
                          title: Text(s),
                        ))
                    .toList(),
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

  Future<void> _generateSummary() async {
    try {
      final summary = await PdfEditingService.generateSummary(widget.pdfId);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF Summary'),
          content: SingleChildScrollView(
            child: Text(summary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate summary: $e')),
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

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${_attachment?.fileName ?? "PDF"}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.picture_as_pdf), text: 'PDF View'),
            Tab(icon: Icon(Icons.edit), text: 'Edit Text'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoStack.isEmpty ? null : _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redoStack.isEmpty ? null : _redo,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showVersionHistory,
            tooltip: 'Version History',
          ),
          IconButton(
            icon: const Icon(Icons.spellcheck),
            onPressed: _checkGrammar,
            tooltip: 'Grammar Check',
          ),
          IconButton(
            icon: const Icon(Icons.summarize),
            onPressed: _generateSummary,
            tooltip: 'Generate Summary',
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveEditedPdf,
            tooltip: 'Save PDF',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PDF View Tab
          _buildPdfView(),
          // Editor Tab
          _buildEditorView(),
        ],
      ),
    );
  }

  Widget _buildPdfView() {
    if (_attachment == null) {
      return const Center(child: Text('No PDF loaded'));
    }

    return PDFView(
      filePath: _attachment!.filePath,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
        });
      },
      onViewCreated: (PDFViewController controller) {
        _pdfViewController = controller;
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = page! + 1;
        });
      },
    );
  }

  Widget _buildEditorView() {
    return Column(
      children: [
        // Formatting toolbar
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Font size
                DropdownButton<double>(
                  value: _fontSize,
                  items: [8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0]
                      .map((size) => DropdownMenuItem(
                            value: size,
                            child: Text('${size.toInt()}'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _fontSize = value);
                      _applyFormatting();
                    }
                  },
                ),
                const SizedBox(width: 8),
                // Bold
                IconButton(
                  icon: const Icon(Icons.format_bold),
                  color: _isBold ? Colors.blue : null,
                  onPressed: () {
                    setState(() => _isBold = !_isBold);
                    _applyFormatting();
                  },
                ),
                // Italic
                IconButton(
                  icon: const Icon(Icons.format_italic),
                  color: _isItalic ? Colors.blue : null,
                  onPressed: () {
                    setState(() => _isItalic = !_isItalic);
                    _applyFormatting();
                  },
                ),
                // Underline
                IconButton(
                  icon: const Icon(Icons.format_underline),
                  color: _isUnderline ? Colors.blue : null,
                  onPressed: () {
                    setState(() => _isUnderline = !_isUnderline);
                    _applyFormatting();
                  },
                ),
                const VerticalDivider(),
                // Alignment
                IconButton(
                  icon: const Icon(Icons.format_align_left),
                  color: _alignment == 'left' ? Colors.blue : null,
                  onPressed: () {
                    setState(() => _alignment = 'left');
                    _applyFormatting();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.format_align_center),
                  color: _alignment == 'center' ? Colors.blue : null,
                  onPressed: () {
                    setState(() => _alignment = 'center');
                    _applyFormatting();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.format_align_right),
                  color: _alignment == 'right' ? Colors.blue : null,
                  onPressed: () {
                    setState(() => _alignment = 'right');
                    _applyFormatting();
                  },
                ),
                const VerticalDivider(),
                // Color picker
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Pick Text Color'),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: _textColor,
                            onColorChanged: (color) {
                              setState(() => _textColor = color);
                              _applyFormatting();
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _textColor,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const VerticalDivider(),
                // Add signature
                IconButton(
                  icon: const Icon(Icons.draw),
                  onPressed: _addSignature,
                  tooltip: 'Add Signature',
                ),
                // Add image
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _addImage,
                  tooltip: 'Add Image',
                ),
              ],
            ),
          ),
        ),
        // Editor
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: _quillController.document.isEmpty()
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No text extracted from PDF.\nThe PDF might be image-based or empty.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: quill.QuillEditor(
                        controller: _quillController,
                        scrollController: ScrollController(),
                        focusNode: FocusNode(),
                      ),
                    ),
                  ),
          ),
        ),
        // Status bar
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Page $_currentPage of $_totalPages'),
              Text('Signatures: ${_signatures.length} | Images: ${_images.length}'),
              Text('Edits: ${_editHistory.length}'),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
