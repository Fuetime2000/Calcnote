import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:calcnote/src/core/controllers/markdown_text_editing_controller.dart';
import 'package:calcnote/src/core/utils/calculation_utils.dart';
import 'package:calcnote/src/core/widgets/rich_text_toolbar.dart';
import 'package:calcnote/src/features/notes/models/note_model.dart';
import 'package:calcnote/src/features/notes/providers/note_provider.dart';
import 'package:calcnote/src/features/ai/providers/ai_provider.dart';
import 'package:calcnote/src/features/notes/utils/note_theme_utils.dart';
import 'package:calcnote/src/features/pdf/providers/pdf_provider.dart';
import 'package:calcnote/src/features/pdf/screens/pdf_viewer_screen.dart';
import 'package:calcnote/src/features/pdf/screens/recent_pdfs_screen.dart';
import 'package:calcnote/src/features/pdf/services/pdf_storage_service.dart';
import 'package:calcnote/src/features/reminders/widgets/reminder_dialog.dart';

// Helper class for PDF content parsing
class _ContentMatch {
  final int start;
  final int end;
  final String type; // 'color' or 'image'
  final RegExpMatch match;
  
  _ContentMatch(this.start, this.end, this.type, this.match);
}

class _TableEditorScreen extends StatefulWidget {
  const _TableEditorScreen();

  @override
  State<_TableEditorScreen> createState() => _TableEditorScreenState();
}

class _TableEditorScreenState extends State<_TableEditorScreen> {
  static const int _maxRows = 30;
  static const int _maxColumns = 12;

  bool _hasHeader = true;
  int _selectedRow = 0;
  int _selectedColumn = 0;

  late List<List<String>> _data;
  late List<List<TextEditingController>> _controllers;
  late List<List<FocusNode>> _focusNodes;

  @override
  void initState() {
    super.initState();
    _data = [
      ['H1', 'H2'],
      ['', ''],
      ['', ''],
    ];
    _controllers = _createControllers(_data);
    _focusNodes = _createFocusNodes(_data);
  }

  @override
  void dispose() {
    for (final row in _controllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    for (final row in _focusNodes) {
      for (final n in row) {
        n.dispose();
      }
    }
    super.dispose();
  }

  List<List<TextEditingController>> _createControllers(List<List<String>> data) {
    return List.generate(
      data.length,
      (r) => List.generate(
        data[r].length,
        (c) => TextEditingController(text: data[r][c]),
      ),
    );
  }

  List<List<FocusNode>> _createFocusNodes(List<List<String>> data) {
    return List.generate(
      data.length,
      (r) => List.generate(data[r].length, (c) => FocusNode()),
    );
  }

  void _rebuildControllersFromData() {
    for (final row in _controllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    for (final row in _focusNodes) {
      for (final n in row) {
        n.dispose();
      }
    }
    _controllers = _createControllers(_data);
    _focusNodes = _createFocusNodes(_data);
  }

  List<List<String>> _controllersToData() {
    return List.generate(
      _controllers.length,
      (r) => List.generate(_controllers[r].length, (c) => _controllers[r][c].text),
    );
  }

  void _addColumn() {
    if (_data.isEmpty) return;
    if (_data.first.length >= _maxColumns) return;

    _data = [for (final row in _controllersToData()) [...row, '']];
    _rebuildControllersFromData();
    setState(() {});
  }

  void _addRow() {
    if (_data.length >= _maxRows) return;
    final columns = _data.isNotEmpty ? _data.first.length : 2;
    _data = [..._controllersToData(), List<String>.filled(columns, '')];
    _rebuildControllersFromData();
    setState(() {});
  }

  void _removeColumn() {
    if (_data.isEmpty || _data.first.length <= 1) return;
    final col = _selectedColumn.clamp(0, _data.first.length - 1);
    final current = _controllersToData();
    _data = [
      for (final row in current)
        [
          for (int c = 0; c < row.length; c++)
            if (c != col) row[c]
        ]
    ];
    _selectedColumn = 0;
    _rebuildControllersFromData();
    setState(() {});
  }

  void _removeRow() {
    if (_data.length <= 1) return;
    final rowIndex = _selectedRow.clamp(0, _data.length - 1);
    final current = _controllersToData();
    _data = [
      for (int r = 0; r < current.length; r++)
        if (r != rowIndex) current[r]
    ];
    _selectedRow = 0;
    _rebuildControllersFromData();
    setState(() {});
  }

  void _copyCell() {
    final row = _selectedRow.clamp(0, _controllers.length - 1);
    final col = _selectedColumn.clamp(0, _controllers[row].length - 1);
    final value = _controllers[row][col].text;
    Clipboard.setData(ClipboardData(text: value));
  }

  Future<void> _cutCell() async {
    final row = _selectedRow.clamp(0, _controllers.length - 1);
    final col = _selectedColumn.clamp(0, _controllers[row].length - 1);
    final value = _controllers[row][col].text;
    await Clipboard.setData(ClipboardData(text: value));
    _controllers[row][col].text = '';
    setState(() {});
  }

  Future<void> _pasteCell() async {
    final data = await Clipboard.getData('text/plain');
    final paste = data?.text;
    if (paste == null) return;
    final row = _selectedRow.clamp(0, _controllers.length - 1);
    final col = _selectedColumn.clamp(0, _controllers[row].length - 1);
    _controllers[row][col].text = paste;
    setState(() {});
  }

  String _toMarkdown() {
    final cells = _controllersToData();
    if (cells.isEmpty || cells.first.isEmpty) return '';
    final columns = cells.first.length;

    String cell(String value) => ' ${value.replaceAll('\n', ' ').trim()} ';
    String rowLine(List<String> values) => '|${values.map(cell).join('|')}|';

    final buffer = StringBuffer();
    if (_hasHeader) {
      buffer.writeln(rowLine(cells.first));
      buffer.writeln(rowLine(List<String>.generate(columns, (_) => '---')));
      for (int r = 1; r < cells.length; r++) {
        buffer.writeln(rowLine(cells[r]));
      }
    } else {
      for (final row in cells) {
        buffer.writeln(rowLine(row));
      }
    }
    return buffer.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Table'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              final markdown = _toMarkdown();
              Navigator.of(context).pop(markdown);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _copyCell,
                    child: const Text('Copy'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _cutCell,
                    child: const Text('Cut'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _pasteCell,
                    child: const Text('Paste'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _addColumn,
                    child: const Text('Add column'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _addRow,
                    child: const Text('Add row'),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (value) {
                      if (value == 'remove_column') {
                        _removeColumn();
                      } else if (value == 'remove_row') {
                        _removeRow();
                      } else if (value == 'toggle_header') {
                        setState(() => _hasHeader = !_hasHeader);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle_header',
                        child: Text(_hasHeader ? 'Disable header' : 'Enable header'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'remove_column',
                        child: Text('Remove column'),
                      ),
                      const PopupMenuItem(
                        value: 'remove_row',
                        child: Text('Remove row'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: TableBorder.all(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                  children: List.generate(_controllers.length, (r) {
                    return TableRow(
                      decoration: BoxDecoration(
                        color: (r == 0 && _hasHeader)
                            ? colorScheme.primaryContainer.withOpacity(0.35)
                            : null,
                      ),
                      children: List.generate(_controllers[r].length, (c) {
                        final isSelected = r == _selectedRow && c == _selectedColumn;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRow = r;
                              _selectedColumn = c;
                            });
                            _focusNodes[r][c].requestFocus();
                          },
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 140, minHeight: 56),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? colorScheme.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: TextField(
                              controller: _controllers[r][c],
                              focusNode: _focusNodes[r][c],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              maxLines: null,
                              onChanged: (_) {
                                // Keep data in sync via controllers (converted on export)
                              },
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;
  
  const NoteEditorScreen({
    super.key,
    this.note,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

/// State class for the NoteEditorScreen
class _NoteEditorScreenState extends State<NoteEditorScreen> with SingleTickerProviderStateMixin {
  // Constants
  static const _debounceDuration = Duration(seconds: 2);
  static const _defaultPadding = 16.0;
  
  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagController;
  
  // Focus Nodes
  late final FocusNode _titleFocusNode;
  late final FocusNode _contentFocusNode;
  late final FocusNode _tagFocusNode;
  
  // Animation
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  
  // State
  late NoteModel _currentNote;
  bool _isNewNote = true;
  bool _isPinned = false;
  bool _showToolbar = true;
  bool _isPreview = false;
  
  // Collections
  final List<String> _tags = [];
  final List<String> _images = []; // Store image paths
  
  // Undo/Redo History
  final List<String> _contentHistory = [];
  int _historyIndex = -1;
  bool _isUndoRedoAction = false;
  
  // Auto-save
  Timer? _debounce;
  
  // UI State
  int _wordCount = 0;
  int _charCount = 0;
  DateTime? _lastSavedTime;
  
  // AI Features
  double? _detectedSum;
  
  // Theme
  Color? _customBackgroundColor;
  String? _selectedThemeType;
  
  // Getters
  ThemeData get _theme => Theme.of(context);
  ColorScheme get _colorScheme => _theme.colorScheme;
  TextTheme get _textTheme => _theme.textTheme;

  // Removed unused regex patterns as they're not being used

  // Launch URL in browser with comprehensive error handling
  Future<void> _launchURL(String url) async {
    if (!mounted) return;
    
    try {
      // Ensure the URL has a scheme
      String urlToLaunch = url.trim();
      if (!urlToLaunch.startsWith('http://') && !urlToLaunch.startsWith('https://')) {
        urlToLaunch = 'https://$urlToLaunch';
      }
      
      final Uri uri = Uri.parse(urlToLaunch);
      
      // First try with external application
      try {
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) return; // Successfully launched
      } catch (e) {
        debugPrint('Error launching URL with external app: $e');
      }
      
      // If external app fails, try with platform default
      try {
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        
        if (launched) return; // Successfully launched
      } catch (e) {
        debugPrint('Error launching URL with platform default: $e');
      }
      
      // If we get here, both methods failed
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cannot Open URL'),
            content: Text(
              'No application found to open this URL. Please make sure you have a web browser installed.\n\nURL: $urlToLaunch',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      
    } catch (e, stackTrace) {
      debugPrint('Error in _launchURL: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while trying to open the URL'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  
  /// Get relative time since last save (e.g., "just now", "2m ago", "1h ago")
  String _getTimeSince(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 5) {
      return 'just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force rebuild when dependencies change to update theme colors
    if (_contentController.text.isNotEmpty) {
      setState(() {});
    }
  }

  // Lifecycle Methods

  @override
  void initState() {
    super.initState();
    _initializeNote();
    _initializeControllers();
    _initializeAnimation();
  }

  /// Initialize note data from widget or create a new one
  void _initializeNote() {
    if (widget.note != null) {
      _currentNote = widget.note!;
      _selectedThemeType = _currentNote.themeType;
      _customBackgroundColor = NoteThemeUtils.parseColor(_currentNote.themeColor);
    } else {
      _currentNote = NoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPinned: false,
        tags: [],
      );
    }
    _isNewNote = widget.note == null;
    _isPinned = _currentNote.isPinned;
    _tags.addAll(_currentNote.tags);
    if (_currentNote.images != null) {
      _images.addAll(_currentNote.images!);
    }
    _updateTextMetrics(_currentNote.content);
  }

  /// Initialize all text controllers and focus nodes
  void _initializeControllers() {
    try {
      _titleController = TextEditingController(text: _currentNote.title);
      _contentController = MarkdownTextEditingController(text: _currentNote.content);
      _tagController = TextEditingController();

      _titleFocusNode = FocusNode();
      _contentFocusNode = FocusNode();
      _tagFocusNode = FocusNode();

      // Add listeners with error handling
      _titleController.addListener(_onTitleChanged);
      _contentController.addListener(_onTextChanged);
      
      // Initialize history with current content
      _addToHistory(_contentController.text);
    } catch (e) {
      debugPrint('Error initializing controllers: $e');
      // Fallback initialization
      _titleController = TextEditingController();
      _contentController = MarkdownTextEditingController();
      _tagController = TextEditingController();
      _titleFocusNode = FocusNode();
      _contentFocusNode = FocusNode();
      _tagFocusNode = FocusNode();
    }
  }

  /// Initialize fade animation for screen transition
  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    // Cancel any pending auto-save
    _debounce?.cancel();

    // Dispose animations
    _animationController.dispose();

    // Dispose controllers
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();

    // Dispose focus nodes
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _tagFocusNode.dispose();

    super.dispose();
  }

  /// Handle title changes with auto-save
  void _onTitleChanged() {
    try {
      if (!mounted) return;
      _currentNote = _currentNote.copyWith(title: _titleController.text);
      _saveNote();
    } catch (e) {
      debugPrint('Error in _onTitleChanged: $e');
    }
  }

  /// Handle content changes with debounced auto-save
  void _onTextChanged() {
    try {
      if (!mounted) return;
      _updateTextMetrics(_contentController.text);
      _analyzeContentWithAI(_contentController.text);
      
      // Add to history if not an undo/redo action
      if (!_isUndoRedoAction) {
        _addToHistory(_contentController.text);
      }

      // Debounce the save operation
      _debounce?.cancel();
      _debounce = Timer(_debounceDuration, () {
        if (mounted) {
          _saveNote();
        }
      });
    } catch (e) {
      debugPrint('Error in _onTextChanged: $e');
    }
  }

  /// Update word and character count
  void _updateTextMetrics(String text) {
    setState(() {
      _charCount = text.length;
      _wordCount = text.trim().isEmpty ? 0 : text.trim().split('\s+').length;
    });
  }
  
  /// Analyze content with AI features
  void _analyzeContentWithAI(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _detectedSum = null;
      });
      return;
    }
    
    final aiProvider = context.read<AIProvider>();
    
    // Calculate sum of all numbers
    final sum = aiProvider.calculateSum(text);
    
    setState(() {
      _detectedSum = sum;
    });
  }

  /// Save the current note
  /// [showMessage] - Whether to show a snackbar message (default: false for auto-save)
  Future<void> _saveNote({bool showMessage = false}) async {
    if (!mounted) return;

    try {
      // Apply AI analysis to note
      final aiProvider = context.read<AIProvider>();
      var note = _currentNote.copyWith(
        content: _contentController.text,
        updatedAt: DateTime.now(),
        isPinned: _isPinned,
        tags: _tags,
        images: _images.isNotEmpty ? _images : null,
      );
      
      // Let AI analyze and enhance the note
      note = aiProvider.analyzeNote(note);

      final noteProvider = context.read<NoteProvider>();

      if (_isNewNote) {
        await noteProvider.createNote(note);
        if (mounted) {
          setState(() => _isNewNote = false);
          if (showMessage) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✓ Note created'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green.shade600,
              ),
            );
          }
        }
      } else {
        await noteProvider.updateNote(note);
        // Update last saved time
        if (mounted) {
          setState(() {
            _lastSavedTime = DateTime.now();
          });
        }
        // Only show message if explicitly requested (not for auto-save)
        if (mounted && showMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✓ Saved'),
              duration: const Duration(milliseconds: 800),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green.shade600,
              margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save note'),
            backgroundColor: _colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Toolbar
          _buildToolbar(),

          // Editor/Preview
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildEditorContainer(),
            ),
          ),

          // AI Insights Panel
          if (_detectedSum != null)
            _buildAIInsightsPanel(),

          // Bottom bar with word count and actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: _theme.dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '$_wordCount words • $_charCount chars',
                  style: _theme.textTheme.bodySmall?.copyWith(
                    color: _theme.hintColor,
                  ),
                ),
                const Spacer(),
                Text(
                  _lastSavedTime != null 
                      ? 'Saved ${_getTimeSince(_lastSavedTime!)}'
                      : 'Not saved yet',
                  style: _theme.textTheme.bodySmall?.copyWith(
                    color: _lastSavedTime != null ? Colors.green.shade700 : _theme.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build the app bar with a modern and stylish title area
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _theme.scaffoldBackgroundColor,
      iconTheme: IconThemeData(color: _theme.colorScheme.onSurfaceVariant),
      titleSpacing: 0,
      toolbarHeight: 88, // Increased height for more space
      title: Container(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _getThemeBackgroundColor().withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            style: _textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: _theme.colorScheme.onSurface,
              letterSpacing: 0.3,
            ),
            decoration: InputDecoration(
              hintText: 'Note Title',
              hintStyle: _textTheme.titleLarge?.copyWith(
                color: _theme.hintColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: Icon(
                  Icons.title,
                  color: _theme.colorScheme.primary,
                ),
              ),
              filled: false,
            ),
            onChanged: (value) => _onTextChanged(),
            cursorColor: _theme.colorScheme.primary,
            cursorWidth: 1.5,
            cursorHeight: 24,
          ),
        ),
      ),
      actions: [
        // Pin/Unpin button
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isPinned
                ? Icon(
                    Icons.push_pin_rounded,
                    key: const ValueKey('pinned'),
                    color: _theme.colorScheme.primary,
                  )
                : const Icon(
                    Icons.push_pin_outlined,
                    key: ValueKey('unpinned'),
                  ),
          ),
          onPressed: _togglePinStatus,
        ),
        // Theme button
        IconButton(
          icon: Icon(
            Icons.palette_outlined,
            color: _customBackgroundColor != null ? _customBackgroundColor : null,
          ),
          onPressed: _showThemeSelector,
          tooltip: 'Change Theme',
        ),
        // PDF attachment button
        if (!_isNewNote)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _attachPdf,
            tooltip: 'Attach PDF',
            color: Colors.red[700],
          ),
        // More options menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) async {
            if (value == 'table') {
              await _openTableEditor();
            } else if (value == 'delete') {
              _deleteNote();
            } else if (value == 'share_text') {
              await _shareNote();
            } else if (value == 'share_pdf') {
              await _shareAsPdf();
            } else if (value == 'download_pdf') {
              await _downloadPdf();
            } else if (value == 'set_reminder') {
              _showReminderDialog();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'table',
              child: Row(
                children: [
                  Icon(Icons.table_chart_outlined, color: Colors.blueGrey),
                  SizedBox(width: 12),
                  Text('Table'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'set_reminder',
              child: Row(
                children: [
                  Icon(Icons.alarm_add, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Set Reminder'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'share_text',
              child: Row(
                children: [
                  Icon(Icons.text_fields, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('Share as Text'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share_pdf',
              child: Row(
                children: [
                  Icon(Icons.share, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Share as PDF'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'download_pdf',
              child: Row(
                children: [
                  Icon(Icons.download, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Download PDF'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _theme.colorScheme.primary.withOpacity(0.1),
                _theme.colorScheme.primary.withOpacity(0.05),
                Colors.transparent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          height: 1.0,
        ),
      ),
    );
  }

  Future<void> _openTableEditor() async {
    if (!mounted) return;
    final String? markdown = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const _TableEditorScreen()),
    );

    if (markdown != null && markdown.trim().isNotEmpty) {
      _insertMarkdown(markdown);
    }
  }

  void _insertMarkdown(String markdown) {
    final selection = _contentController.selection;
    final text = _contentController.text;

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final safeStart = start < 0 ? 0 : start;
    final safeEnd = end < 0 ? safeStart : end;

    final toInsert = '\n$markdown\n';
    final newText = text.replaceRange(safeStart, safeEnd, toInsert);
    final newCursor = safeStart + toInsert.length;

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );

    _addToHistory(newText);
    _saveNote();
  }
  /// Toggle the pinned status of the note
  void _togglePinStatus() {
    setState(() => _isPinned = !_isPinned);
    _saveNote(showMessage: true);
  }

  

  /// Get theme background color
  Color _getThemeBackgroundColor() {
    try {
      // Start with the custom background color or theme's surface color
      Color backgroundColor = _customBackgroundColor ?? _colorScheme.surface;
      
      // Apply time-based theme if selected
      if (_selectedThemeType == 'time-based') {
        final timeTheme = NoteThemeUtils.getTimeBasedTheme();
        backgroundColor = timeTheme.backgroundColor;
      } 
      // Apply category theme if selected and no custom background color is set
      else if (_selectedThemeType != null && 
               _selectedThemeType != 'default' && 
               _customBackgroundColor == null) {
        final theme = NoteThemeUtils.themes[_selectedThemeType];
        if (theme != null) {
          backgroundColor = theme.backgroundColor;
        }
      }
      
      // Return the background color
      return backgroundColor;
    } catch (e) {
      debugPrint('Error getting theme background color: $e');
      // Explicit fallback for release mode
      return _theme.brightness == Brightness.dark 
          ? const Color(0xFF121212) 
          : const Color(0xFFFAFAFA);
    }
  }

  /// Build the editor container with shadow and rounded corners
  Widget _buildEditorContainer() {
    // Get the theme background color
    final backgroundColor = _getThemeBackgroundColor();
    
    return Container(
      margin: const EdgeInsets.all(_defaultPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: backgroundColor,
          colorScheme: Theme.of(context).colorScheme.copyWith(
            surface: backgroundColor,
            onSurface: _theme.colorScheme.onSurface,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: backgroundColor,
              child: _isPreview ? _buildPreview() : _buildEditor(),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Show theme selector dialog
  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Time-based theme
              ListTile(
                leading: Icon(NoteThemeUtils.getTimeBasedTheme().icon),
                title: const Text('Time-Based'),
                subtitle: Text(NoteThemeUtils.getTimeBasedTheme().name),
                trailing: _selectedThemeType == 'time-based' 
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedThemeType = 'time-based';
                    _customBackgroundColor = null;
                  });
                  _saveTheme();
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              // Category themes
              ...NoteThemeUtils.themes.entries.map((entry) {
                final theme = entry.value;
                return ListTile(
                  leading: Icon(theme.icon, color: theme.textColor),
                  title: Text(theme.name),
                  tileColor: theme.backgroundColor.withOpacity(0.3),
                  trailing: _selectedThemeType == entry.key
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedThemeType = entry.key;
                      _customBackgroundColor = theme.backgroundColor;
                    });
                    _saveTheme();
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
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
  
  /// Save theme to note
  void _saveTheme() {
    final colorHex = _customBackgroundColor != null 
        ? NoteThemeUtils.colorToHex(_customBackgroundColor!)
        : null;
    
    _currentNote = _currentNote.copyWith(
      themeColor: colorHex,
      themeType: _selectedThemeType,
    );
    _saveNote(showMessage: true);
  }
  
  /// Build the markdown preview
  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parse and render content with colored text support
          _buildRichPreview(_contentController.text),
        ],
      ),
    );
  }
  
  /// Build rich preview with color support and interactive checkboxes
  Widget _buildRichPreview(String content) {
    // Check if content has checkboxes
    final hasCheckboxes = content.contains(RegExp(r'- \[([ xX])\]'));
    
    // If has checkboxes, render with interactive checkboxes
    if (hasCheckboxes) {
      return _buildMixedContentPreview(content);
    }
    
    // Parse HTML color spans and convert to RichText
    final spans = <InlineSpan>[];
    final regex = RegExp(r'<span style="color:\s*([^"]+)">([^<]+)</span>');
    int lastIndex = 0;
    
    for (final match in regex.allMatches(content)) {
      // Add text before the colored span
      if (match.start > lastIndex) {
        final beforeText = content.substring(lastIndex, match.start);
        spans.add(TextSpan(
          text: beforeText,
          style: _textTheme.bodyLarge,
        ));
      }
      
      // Add colored text span
      final colorStr = match.group(1)!.trim();
      final text = match.group(2)!;
      Color? color;
      
      try {
        // Parse hex color
        if (colorStr.startsWith('#')) {
          final hexColor = colorStr.substring(1);
          color = Color(int.parse('FF$hexColor', radix: 16));
        }
      } catch (e) {
        debugPrint('Error parsing color: $e');
      }
      
      spans.add(TextSpan(
        text: text,
        style: _textTheme.bodyLarge?.copyWith(
          color: color ?? _colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < content.length) {
      final remainingText = content.substring(lastIndex);
      spans.add(TextSpan(
        text: remainingText,
        style: _textTheme.bodyLarge,
      ));
    }
    
    // If no colored text found, show markdown preview
    if (spans.isEmpty || regex.allMatches(content).isEmpty) {
      return MarkdownBody(
        data: content,
        selectable: true,
        extensionSet: md.ExtensionSet.gitHubWeb,
        styleSheet: MarkdownStyleSheet(
          p: _textTheme.bodyLarge,
          h1: _textTheme.headlineSmall,
          h2: _textTheme.titleLarge,
          h3: _textTheme.titleMedium,
          strong: const TextStyle(fontWeight: FontWeight.bold),
          em: const TextStyle(fontStyle: FontStyle.italic),
          code: TextStyle(
            backgroundColor: _colorScheme.surfaceContainerHighest.withOpacity(0.5),
            fontFamily: 'monospace',
            fontSize: _textTheme.bodyMedium?.fontSize,
          ),
        ),
        onTapLink: (text, href, title) {
          if (href != null) _launchURL(href);
        },
        imageBuilder: (uri, title, alt) {
          return _buildImageWidget(uri.toString());
        },
      );
    }
    
    // Return rich text with colors
    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }
  
  /// Build preview with mixed content (checkboxes, text, colors)
  Widget _buildMixedContentPreview(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Check if line is a checkbox
      final checkboxMatch = RegExp(r'^- \[([ xX])\] (.+)$').firstMatch(line.trim());
      
      if (checkboxMatch != null) {
        final isChecked = checkboxMatch.group(1)!.toLowerCase() == 'x';
        final taskText = checkboxMatch.group(2)!;
        
        widgets.add(
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleCheckbox(i, isChecked),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isChecked ? Colors.green : _colorScheme.onSurface,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        taskText,
                        style: _textTheme.bodyLarge?.copyWith(
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                          color: isChecked ? _colorScheme.onSurface.withOpacity(0.6) : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else if (line.trim().isNotEmpty) {
        // Regular line - render as plain text to avoid markdown conflicts
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            child: Text(
              line,
              style: _textTheme.bodyLarge,
            ),
          ),
        );
      } else {
        // Empty line
        widgets.add(const SizedBox(height: 8));
      }
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
  
  /// Toggle checkbox state
  void _toggleCheckbox(int lineIndex, bool currentlyChecked) {
    try {
      final lines = _contentController.text.split('\n');
      
      if (lineIndex < 0 || lineIndex >= lines.length) return;
      
      final line = lines[lineIndex];
      final newCheckState = currentlyChecked ? '[ ]' : '[x]';
      
      // Replace checkbox state
      lines[lineIndex] = line.replaceFirst(
        RegExp(r'\[([ xX])\]'),
        newCheckState,
      );
      
      // Update content
      _contentController.text = lines.join('\n');
      
      // Save note
      _saveNote(showMessage: true);
      
      // Show feedback
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error toggling checkbox: $e');
    }
  }
  
  /// Build image widget for preview
  Widget _buildImageWidget(String imagePath) {
    // Check if it's a local file path
    final file = File(imagePath);
    
    if (file.existsSync()) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: const Row(
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Image not found'),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
    
    // Try to find in images list
    final matchingImage = _images.firstWhere(
      (img) => img.endsWith(imagePath),
      orElse: () => '',
    );
    
    if (matchingImage.isNotEmpty) {
      return _buildImageWidget(matchingImage);
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_not_supported, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text('Image: $imagePath')),
        ],
      ),
    );
  }

  /// Build the editor - simple text field, checkboxes work in preview mode
  Widget _buildEditor() {
    final backgroundColor = _getThemeBackgroundColor();
    final textColor = _theme.brightness == Brightness.dark 
        ? Colors.white 
        : _theme.colorScheme.onSurface;
    
    return Container(
      color: backgroundColor,
      child: TextFormField(
        controller: _contentController,
        focusNode: _contentFocusNode,
        maxLines: null,
        expands: true,
        style: _textTheme.bodyLarge?.copyWith(
          color: textColor,
          height: 1.5,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: true,
          fillColor: backgroundColor,
          contentPadding: const EdgeInsets.all(16),
          hintText: 'Start writing...',
          hintStyle: _textTheme.bodyLarge?.copyWith(
            color: _theme.hintColor,
          ),
        ),
        onChanged: (value) => _onTextChanged(),
        cursorColor: _theme.colorScheme.primary,
        cursorWidth: 1.5,
        cursorRadius: const Radius.circular(2),
        keyboardType: TextInputType.multiline,
        autofocus: true,
        enableInteractiveSelection: true,
        enableSuggestions: true,
        autocorrect: true,
      ),
    );
  }

  // Build the formatting toolbar
  Widget _buildToolbar() {
    // Hide toolbar in preview mode
    if (_isPreview) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: _colorScheme.primaryContainer,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility,
                size: 18,
                color: _colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Preview Mode',
                style: TextStyle(
                  color: _colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Show toolbar in edit mode
    return RichTextToolbar(
      controller: _contentController,
      focusNode: _contentFocusNode,
      onPreviewToggle: _togglePreview,
      isPreviewMode: _isPreview,
      onImagePicked: _handleImagePicked,
      onUndo: _undo,
      onRedo: _redo,
      canUndo: _historyIndex > 0,
      canRedo: _historyIndex < _contentHistory.length - 1,
      onCalculator: _showCalculatorDialog,
    );
  }

  /// Toggle between edit and preview modes
  void _togglePreview() {
    // Save any pending changes before toggling preview
    _saveNote();
    
    // Toggle preview mode
    setState(() {
      _isPreview = !_isPreview;
    });
    
    // If switching back to edit mode, request focus
    if (!_isPreview) {
      _contentFocusNode.requestFocus();
    }
  }

  /// Show calculator dialog
  void _showCalculatorDialog() {
    final calculatorController = TextEditingController();
    String? result;
    final List<String> buttons = [
      'C', '⌫', '%', '/',
      '7', '8', '9', '×',
      '4', '5', '6', '-',
      '1', '2', '3', '+',
      '00', '0', '.', '=',
    ];

    // Preprocess the expression to replace UI symbols with calculation symbols
    String _preprocessExpression(String expr) {
      return expr.replaceAll('×', '*');
    }

    void updateCalculation(String value, {bool forceUpdate = false}) {
      if (value == 'C') {
        calculatorController.clear();
        result = null;
      } else if (value == '⌫') {
        if (calculatorController.text.isNotEmpty) {
          calculatorController.text = calculatorController.text
              .substring(0, calculatorController.text.length - 1);
        }
      } else if (value == '=') {
        if (calculatorController.text.isNotEmpty) {
          final processedExpr = _preprocessExpression(calculatorController.text);
          result = CalculationUtils.evaluateExpression(processedExpr);
          if (result?.isNotEmpty ?? false) {
            calculatorController.text = result!;
          }
          return; // Skip the auto-calculation after pressing '='
        }
      } else {
        calculatorController.text += value;
      }

      // Only update result if not forcing an update (like when pressing '=')
      if (!forceUpdate && calculatorController.text.trim().isNotEmpty) {
        try {
          final processedExpr = _preprocessExpression(calculatorController.text);
          final res = CalculationUtils.evaluateExpression(processedExpr);
          result = res.isNotEmpty ? res : null;
        } catch (e) {
          result = null;
        }
      } else if (calculatorController.text.trim().isEmpty) {
        result = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Calculator', 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: calculatorController,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          readOnly: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                          ),
                        ),
                        if (result != null && result != calculatorController.text)
                          Text(
                            '= $result',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: buttons.length,
                      itemBuilder: (BuildContext context, int index) {
                        final button = buttons[index];
                        final isOperator = ['+', '-', '×', '/', '%', '='].contains(button);
                        final isFunction = ['C', '⌫'].contains(button);
                        
                        return ElevatedButton(
                          onPressed: () {
                            updateCalculation(button);
                            (context as Element).markNeedsBuild();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFunction
                                ? Colors.grey[300]
                                : isOperator
                                    ? Colors.orange
                                    : Colors.white,
                            foregroundColor: isFunction
                                ? Colors.black
                                : isOperator
                                    ? Colors.white
                                    : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            button,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: isFunction ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          // Always use the result if available, otherwise use the current calculation
                          String textToInsert = result ?? calculatorController.text;
                          
                          // If we have a calculation in the display but no result yet, evaluate it
                          if (result == null && calculatorController.text.trim().isNotEmpty) {
                            final processedExpr = _preprocessExpression(calculatorController.text);
                            textToInsert = CalculationUtils.evaluateExpression(processedExpr) ?? calculatorController.text;
                          }
                          
                          final cursorPosition = _contentController.selection.base.offset;
                          
                          setState(() {
                            if (cursorPosition == -1) {
                              _contentController.text += ' $textToInsert ';
                            } else {
                              final newText = _contentController.text.replaceRange(
                                cursorPosition,
                                cursorPosition,
                                ' $textToInsert ',
                              );
                              _contentController.value = _contentController.value.copyWith(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: cursorPosition + textToInsert.length + 2, // +2 for the spaces
                                ),
                              );
                            }
                          });
                          
                          // Save the note with the inserted result
                          _saveNote(showMessage: true);
                          
                          // Close the dialog
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Insert Result'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the floating action button
  Widget _buildFloatingActionButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 35.0),
      child: FloatingActionButton(
        heroTag: 'toggle_preview',
        mini: true,
        onPressed: _togglePreview,
        backgroundColor: _colorScheme.primaryContainer,
        elevation: 2,
        child: Icon(
          _isPreview ? Icons.edit : Icons.preview,
          color: _colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
    );
  }

  /// Toggle the visibility of the formatting toolbar
  void _toggleToolbar() {
    setState(() {
      _showToolbar = !_showToolbar;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toolbar visibility toggled'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 70, left: 16, right: 16),
        ),
      );
    }
  }

  /// Generate a PDF document from the current note
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final title = _titleController.text.isNotEmpty ? _titleController.text : 'Untitled Note';
    final content = _contentController.text;
    
    // Get theme background color
    final backgroundColor = _getThemeBackgroundColor();
    
    // Convert Flutter background color to PDF color
    final pdfBackgroundColor = PdfColor(
      backgroundColor.red / 255.0,
      backgroundColor.green / 255.0,
      backgroundColor.blue / 255.0,
    );
    
    // Use black text for better readability in PDF
    const pdfTextColor = PdfColors.black;
    
    // Add a page to the PDF with high-quality settings
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(50),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
            italic: pw.Font.helveticaOblique(),
            boldItalic: pw.Font.helveticaBoldOblique(),
          ),
          buildBackground: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(
                color: pdfBackgroundColor,
              ),
            );
          },
        ),
        build: (pw.Context context) {
          return [
            // Title with better styling
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.grey800,
                    width: 2,
                  ),
                ),
              ),
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: pdfTextColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            pw.SizedBox(height: 16),
            // Date information
            pw.Text(
              'Created: ${_formatDate(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
            pw.SizedBox(height: 24),
            // Content with better spacing
            ..._buildPdfContent(content, pdfTextColor),
            // Footer spacing
            pw.SizedBox(height: 20),
          ];
        },
      ),
    );
    
    // Save the PDF to a temporary file
    return pdf.save();
  }
  
  /// Build PDF content with colored text, images, and checkboxes
  List<pw.Widget> _buildPdfContent(String content, PdfColor defaultTextColor) {
    return _buildPdfBlocks(content, defaultTextColor);
  }

  List<pw.Widget> _buildPdfBlocks(String content, PdfColor defaultTextColor) {
    final widgets = <pw.Widget>[];
    final lines = content.split('\n');
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      if (_isMarkdownTableLine(line.trim())) {
        final start = i;
        int end = i;
        while (end < lines.length && _isMarkdownTableLine(lines[end].trim())) {
          end++;
        }
        final tableLines = lines.sublist(start, end);
        final tableWidget = _buildPdfTableFromMarkdownLines(tableLines, defaultTextColor);
        if (tableWidget != null) {
          widgets.add(tableWidget);
          widgets.add(pw.SizedBox(height: 10));
        } else {
          // Fallback to plain text if parsing fails
          for (int k = start; k < end; k++) {
            if (lines[k].trim().isEmpty) {
              widgets.add(pw.SizedBox(height: 8));
            } else {
              widgets.addAll(_buildPdfLine(lines[k], defaultTextColor));
            }
          }
        }
        i = end;
        continue;
      }

      final checkboxMatch = RegExp(r'^- \[([ xX])\] (.+)$').firstMatch(line.trim());
      if (checkboxMatch != null) {
        final isChecked = checkboxMatch.group(1)!.toLowerCase() == 'x';
        final taskText = checkboxMatch.group(2)!;

        widgets.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 12,
                height: 12,
                margin: const pw.EdgeInsets.only(right: 8, top: 2),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: isChecked ? PdfColors.green : PdfColors.grey700,
                    width: 1.5,
                  ),
                  color: isChecked ? PdfColors.green100 : PdfColors.white,
                ),
                child: isChecked
                    ? pw.Center(
                        child: pw.Text(
                          '✓',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.green900,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              pw.Expanded(
                child: pw.Text(
                  taskText,
                  style: pw.TextStyle(
                    fontSize: 13,
                    decoration: isChecked ? pw.TextDecoration.lineThrough : null,
                    color: isChecked ? PdfColors.grey600 : defaultTextColor,
                    lineSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
        widgets.add(pw.SizedBox(height: 4));
        i++;
        continue;
      }

      if (line.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 8));
      } else {
        widgets.addAll(_buildPdfLine(line, defaultTextColor));
      }
      i++;
    }

    return widgets;
  }

  bool _isMarkdownTableLine(String trimmed) {
    if (trimmed.isEmpty) return false;
    // Basic check: pipe at start/end or multiple pipes in line
    final pipeCount = '|'.allMatches(trimmed).length;
    if (pipeCount < 2) return false;
    if (!(trimmed.contains('|'))) return false;
    return true;
  }

  pw.Widget? _buildPdfTableFromMarkdownLines(List<String> tableLines, PdfColor defaultTextColor) {
    if (tableLines.length < 2) return null;

    final parsedRows = <List<String>>[];
    for (final raw in tableLines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final cells = _splitMarkdownTableRow(line);
      if (cells.isEmpty) continue;
      parsedRows.add(cells);
    }
    if (parsedRows.length < 2) return null;

    // Detect separator line like |---|---|
    int separatorIndex = -1;
    for (int r = 0; r < parsedRows.length; r++) {
      final row = parsedRows[r];
      final isSep = row.isNotEmpty && row.every((c) {
        final t = c.replaceAll(':', '').replaceAll('-', '').trim();
        return t.isEmpty;
      });
      if (isSep) {
        separatorIndex = r;
        break;
      }
    }

    final hasHeader = separatorIndex == 1 && parsedRows.isNotEmpty;
    final rowsWithoutSep = <List<String>>[];
    for (int r = 0; r < parsedRows.length; r++) {
      if (r == separatorIndex) continue;
      rowsWithoutSep.add(parsedRows[r]);
    }

    final columnCount = rowsWithoutSep.first.length;
    final normalized = rowsWithoutSep
        .map((row) => List<String>.generate(
              columnCount,
              (i) => i < row.length ? row[i] : '',
            ))
        .toList();

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 1),
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: List.generate(normalized.length, (r) {
          final isHeaderRow = hasHeader && r == 0;
          return pw.TableRow(
            decoration: isHeaderRow
                ? const pw.BoxDecoration(color: PdfColors.grey300)
                : null,
            children: List.generate(columnCount, (c) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  normalized[r][c],
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: isHeaderRow ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: defaultTextColor,
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  List<String> _splitMarkdownTableRow(String line) {
    var t = line.trim();
    if (t.startsWith('|')) t = t.substring(1);
    if (t.endsWith('|')) t = t.substring(0, t.length - 1);
    return t.split('|').map((e) => e.trim()).toList();
  }
  
  /// Build PDF widgets for a single line (handles colors and images)
  List<pw.Widget> _buildPdfLine(String line, PdfColor defaultTextColor) {
    final widgets = <pw.Widget>[];
    final colorRegex = RegExp(r'<span style="color:\s*([^"]+)">([^<]+)</span>');
    final imageRegex = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');
    
    // Check for colored text
    final colorMatch = colorRegex.firstMatch(line);
    if (colorMatch != null) {
      final colorStr = colorMatch.group(1)!.trim();
      final text = colorMatch.group(2)!;
      PdfColor pdfColor = PdfColors.black;
      
      try {
        if (colorStr.startsWith('#')) {
          final hexColor = colorStr.substring(1);
          final intColor = int.parse(hexColor, radix: 16);
          final r = ((intColor >> 16) & 0xFF) / 255.0;
          final g = ((intColor >> 8) & 0xFF) / 255.0;
          final b = (intColor & 0xFF) / 255.0;
          pdfColor = PdfColor(r, g, b);
        }
      } catch (e) {
        debugPrint('Error parsing PDF color: $e');
      }
      
      widgets.add(
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 12,
            color: pdfColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
      widgets.add(pw.SizedBox(height: 4));
      return widgets;
    }
    
    // Check for images
    final imageMatch = imageRegex.firstMatch(line);
    if (imageMatch != null) {
      final imagePath = imageMatch.group(2)!;
      
      // Try to find the full path in _images list
      String? fullPath;
      if (_images.isNotEmpty) {
        fullPath = _images.firstWhere(
          (img) => img.endsWith(imagePath) || img == imagePath,
          orElse: () => imagePath,
        );
      } else {
        fullPath = imagePath;
      }
      
      try {
        final imageFile = File(fullPath);
        if (imageFile.existsSync()) {
          final imageBytes = imageFile.readAsBytesSync();
          final image = pw.MemoryImage(imageBytes);
          
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
                width: 400,
              ),
            ),
          );
        } else {
          widgets.add(
            pw.Text(
              '[Image: $imagePath]',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error adding image to PDF: $e');
      }
      return widgets;
    }
    
    // Plain text
    if (line.trim().isNotEmpty) {
      widgets.add(
        pw.Text(
          line,
          style: pw.TextStyle(fontSize: 12, color: defaultTextColor),
        ),
      );
      widgets.add(pw.SizedBox(height: 4));
    }
    
    return widgets;
  }
  
  /// Format date for PDF
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  /// Share the note as PDF
  Future<void> _shareAsPdf() async {
    try {
      final pdfBytes = await _generatePdf();
      
      // Save PDF to temporary file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/note_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      // Share the PDF file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sharing note as PDF',
        subject: 'Note from CalcNote',
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share as PDF')),
        );
      }
    }
  }
  
  /// Download the note as PDF and save to library
  Future<void> _downloadPdf() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text('Generating PDF...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      final pdfBytes = await _generatePdf();
      
      // Create file name from note title
      final title = _titleController.text.isNotEmpty 
          ? _titleController.text.replaceAll(RegExp(r'[^\w\s-]'), '') 
          : 'Untitled_Note';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${title}_$timestamp.pdf';
      
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${appDir.path}/pdfs');
      
      // Create pdfs directory if it doesn't exist
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }
      
      // Save PDF file
      final pdfFile = File('${pdfDir.path}/$fileName');
      await pdfFile.writeAsBytes(pdfBytes);
      
      // Save PDF attachment to library using PdfStorageService
      final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
      await PdfStorageService.savePdfAttachment(
        noteId: PdfProvider.libraryNoteId,
        pdfFile: pdfFile,
        fileName: fileName,
        compress: false,
        encrypt: false,
      );
      
      // Reload library PDFs
      await pdfProvider.loadLibraryPdfs();
      await pdfProvider.loadRecentPdfs();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded: $fileName'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Navigate to PDFs screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RecentPdfsScreen(),
                  ),
                );
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Share the current note as text
  Future<void> _shareNote() async {
    try {
      final String title = _titleController.text.isNotEmpty 
          ? _titleController.text 
          : 'Untitled Note';
      
      // Limit the content length to avoid potential issues
      String content = _contentController.text.isNotEmpty 
          ? _contentController.text 
          : 'No content';
      
      // Truncate content if it's too long to avoid potential issues
      const maxLength = 1000;
      if (content.length > maxLength) {
        content = '${content.substring(0, maxLength)}...';
      }
      
      // Create a share intent directly
      final box = context.findRenderObject() as RenderBox?;
      
      // Try the share_plus package first
      try {
        await Share.share(
          content,
          subject: title,
          sharePositionOrigin: box != null
              ? Rect.fromPoints(
                  box.localToGlobal(Offset.zero, ancestor: box),
                  box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: box),
                )
              : null,
        );
        return; // Exit if successful
      } catch (e) {
        print('Share_plus failed with: $e');
        // Continue to fallback method
      }
      
      // Fallback to platform channels if share_plus fails
      try {
        const channel = MethodChannel('dev.fluttercommunity.plus/share');
        await channel.invokeMethod('share', {
          'text': content,
          'subject': title,
        });
      } catch (e) {
        print('Platform channel share failed with: $e');
        // Show a dialog with the content that can be copied
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Share Note'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(content),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '$title\n\n$content'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Copy to Clipboard'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Share failed with error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share. You can copy the text manually.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show reminder dialog
  void _showReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => ReminderDialog(
        noteId: widget.note?.id ?? '',
        noteTitle: _titleController.text.isEmpty 
            ? 'Untitled Note' 
            : _titleController.text,
      ),
    );
  }

  /// Show PDF management dialog
  Future<void> _attachPdf() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      'PDF Attachments',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.red),
                      onPressed: () async {
                        await _pickAndAttachPdf();
                        if (mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                      tooltip: 'Attach PDF',
                    ),
                  ],
                ),
              ),
              const Divider(),
              // PDF List
              Expanded(
                child: Consumer<PdfProvider>(
                  builder: (context, pdfProvider, child) {
                    // Load PDFs for this note
                    pdfProvider.loadPdfsForNote(_currentNote.id);
                    final attachments = pdfProvider.attachments;
                    
                    if (attachments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No PDFs attached',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to attach a PDF',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: attachments.length,
                      itemBuilder: (context, index) {
                        final attachment = attachments[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                            title: Text(
                              attachment.fileName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${attachment.pageCount} pages • ${attachment.fileSizeFormatted}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete PDF'),
                                    content: Text('Delete "${attachment.fileName}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true) {
                                  await pdfProvider.deletePdf(attachment.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('PDF deleted')),
                                    );
                                  }
                                }
                              },
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfViewerScreen(
                                    pdfId: attachment.id,
                                    noteId: _currentNote.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick and attach PDF file
  Future<void> _pickAndAttachPdf() async {
    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Attach PDF using provider (it handles file picking)
      final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
      final attachment = await pdfProvider.pickAndAttachPdf(
        noteId: _currentNote.id,
        compress: true,
        encrypt: false,
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (attachment != null) {
        // Update note to indicate it has PDF attachments
        _currentNote = _currentNote.copyWith(hasPdfAttachments: true);
        await context.read<NoteProvider>().updateNote(_currentNote);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF "${attachment.fileName}" attached successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Delete the current note after confirmation
  Future<void> _deleteNote() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: _colorScheme.error,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ) ?? false;

    if (shouldDelete) {
      try {
        final noteProvider = context.read<NoteProvider>();
        await noteProvider.deleteNote(_currentNote.id);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note deleted')),
          );
        }
      } catch (e) {
        debugPrint('Error deleting note: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete note'),
              backgroundColor: _colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Build AI Insights Panel
  Widget _buildAIInsightsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _colorScheme.primaryContainer.withOpacity(0.3),
            _colorScheme.secondaryContainer.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 18,
            color: _colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'AI',
            style: _textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          // Show detected sum
          if (_detectedSum != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calculate, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Total: ${_detectedSum!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  /// Handle image picked from toolbar
  Future<void> _handleImagePicked(String imagePath) async {
    try {
      // Copy image to app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final notesImagesDir = Directory('${appDir.path}/note_images');
      
      if (!await notesImagesDir.exists()) {
        await notesImagesDir.create(recursive: true);
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imagePath.split('/').last}';
      final newPath = '${notesImagesDir.path}/$fileName';
      
      // Copy the file
      final sourceFile = File(imagePath);
      await sourceFile.copy(newPath);
      
      // Add to images list
      setState(() {
        _images.add(newPath);
      });
      
      // Save note with updated images
      await _saveNote();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image added to note'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Add content to history for undo/redo
  void _addToHistory(String content) {
    // Don't add if it's the same as the last entry
    if (_contentHistory.isNotEmpty && 
        _historyIndex >= 0 && 
        _historyIndex < _contentHistory.length &&
        _contentHistory[_historyIndex] == content) {
      return;
    }
    
    // Remove any history after current index
    if (_historyIndex < _contentHistory.length - 1) {
      _contentHistory.removeRange(_historyIndex + 1, _contentHistory.length);
    }
    
    // Add new entry
    _contentHistory.add(content);
    _historyIndex = _contentHistory.length - 1;
    
    // Limit history size to 50 entries
    if (_contentHistory.length > 50) {
      _contentHistory.removeAt(0);
      _historyIndex--;
    }
    
    // Update UI
    if (mounted) {
      setState(() {});
    }
  }
  
  /// Undo last change
  void _undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _isUndoRedoAction = true;
      
      final previousContent = _contentHistory[_historyIndex];
      _contentController.value = TextEditingValue(
        text: previousContent,
        selection: TextSelection.collapsed(offset: previousContent.length),
      );
      
      _isUndoRedoAction = false;
      
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Undo'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 70, left: 16, right: 16),
          ),
        );
      }
    }
  }
  
  /// Redo last undone change
  void _redo() {
    if (_historyIndex < _contentHistory.length - 1) {
      _historyIndex++;
      _isUndoRedoAction = true;
      
      final nextContent = _contentHistory[_historyIndex];
      _contentController.value = TextEditingValue(
        text: nextContent,
        selection: TextSelection.collapsed(offset: nextContent.length),
      );
      
      _isUndoRedoAction = false;
      
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redo'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 70, left: 16, right: 16),
          ),
        );
      }
    }
  }
}
