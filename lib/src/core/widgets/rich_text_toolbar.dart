import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class RichTextToolbar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onPreviewToggle;
  final bool isPreviewMode;
  final Function(String)? onImagePicked;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onCalculator;

  const RichTextToolbar({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onPreviewToggle,
    this.isPreviewMode = false,
    this.onImagePicked,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
    this.onCalculator,
  }) : super(key: key);

  @override
  State<RichTextToolbar> createState() => _RichTextToolbarState();
}

class _RichTextToolbarState extends State<RichTextToolbar> {

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildButton(
              Icons.format_bold, 
              () => _formatText('**', '**'),
              tooltip: 'Bold (Ctrl+B)',
              isActive: _isFormattingActive('**', '**'),
            ),
            _buildButton(
              Icons.format_italic, 
              () => _formatText('*', '*'),
              tooltip: 'Italic (Ctrl+I)',
              isActive: _isFormattingActive('*', '*'),
            ),
            _buildButton(
              Icons.format_underline, 
              () => _formatText('__', '__'),
              tooltip: 'Underline (Ctrl+U)',
              isActive: _isFormattingActive('__', '__'),
            ),
            _buildButton(
              Icons.format_strikethrough, 
              () => _formatText('~~', '~~'),
              tooltip: 'Strikethrough (Ctrl+S)',
              isActive: _isFormattingActive('~~', '~~'),
            ),
            const VerticalDivider(width: 16, thickness: 1, indent: 8, endIndent: 8),
            _buildButton(
              Icons.format_list_bulleted, 
              _insertBulletList,
              tooltip: 'Bullet List',
            ),
            _buildButton(
              Icons.format_list_numbered, 
              _insertNumberedList,
              tooltip: 'Numbered List',
            ),
            _buildButton(
              Icons.check_box_outlined, 
              _insertChecklist,
              tooltip: 'Checklist',
              iconColor: Colors.orange,
            ),
            _buildButton(
              Icons.code, 
              () => _formatText('`', '`'),
              tooltip: 'Code (Ctrl+`)',
              isActive: _isFormattingActive('`', '`'),
            ),
            _buildButton(
              Icons.link, 
              _insertLink,
              tooltip: 'Insert Link (Ctrl+K)',
            ),
            const VerticalDivider(width: 16, thickness: 1, indent: 8, endIndent: 8),
            _buildButton(
              Icons.image, 
              _pickImage,
              tooltip: 'Insert Image',
              iconColor: Colors.green,
            ),
            _buildButton(
              Icons.color_lens, 
              _pickTextColor,
              tooltip: 'Text Color',
              iconColor: Colors.purple,
            ),
            const VerticalDivider(width: 16, thickness: 1, indent: 8, endIndent: 8),
            _buildButton(
              Icons.undo, 
              widget.canUndo ? (widget.onUndo ?? () {}) : () {},
              tooltip: 'Undo (Ctrl+Z)',
              iconColor: widget.canUndo ? Colors.blue : Colors.grey,
            ),
            _buildButton(
              Icons.redo, 
              widget.canRedo ? (widget.onRedo ?? () {}) : () {},
              tooltip: 'Redo (Ctrl+Y)',
              iconColor: widget.canRedo ? Colors.blue : Colors.grey,
            ),
            _buildButton(
              Icons.delete_outline, 
              _deleteSelectedText,
              tooltip: 'Delete Selected Text',
              iconColor: Colors.red,
            ),
            const VerticalDivider(width: 16, thickness: 1, indent: 8, endIndent: 8),
            _buildButton(
              Icons.calculate, 
              widget.onCalculator ?? () {},
              tooltip: 'Calculator',
              iconColor: Colors.orange,
            ),
            _buildButton(
              widget.isPreviewMode ? Icons.edit : Icons.visibility, 
              widget.onPreviewToggle,
              tooltip: widget.isPreviewMode ? 'Edit Mode' : 'Preview Mode',
              iconSize: 20,
              isActive: widget.isPreviewMode,
            ),
          ],
        ),
      ),
    );
  }

  // Check if the current selection is already wrapped with the given delimiters
  bool _isFormattingActive(String prefix, String suffix) {
    if (!widget.focusNode.hasFocus) return false;
    
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    if (!selection.isValid) return false;
    
    final start = selection.start;
    final end = selection.end;
    
    // Check if the text is already wrapped with the delimiters
    if (start >= prefix.length && 
        end <= text.length - suffix.length) {
      final beforeText = text.substring(start - prefix.length, start);
      final afterText = text.substring(end, end + suffix.length);
      return beforeText == prefix && afterText == suffix;
    }
    
    return false;
  }

  Widget _buildButton(
    IconData icon, 
    VoidCallback onPressed, {
    String? tooltip,
    double iconSize = 22,
    bool isActive = false,
    Color? iconColor,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ?? (isActive 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),
      ),
    );

    return tooltip != null 
        ? Tooltip(
            message: tooltip,
            child: button,
          )
        : button;
  }

  void _formatText(String prefix, String suffix) {
    if (!mounted) return;
    
    try {
      final text = widget.controller.text;
      final selection = widget.controller.selection;
      
      // Validate selection
      if (!selection.isValid || selection.start < 0 || selection.end > text.length) {
        return;
      }
      
      final selectedText = selection.textInside(text);
      
      // Check if text is already formatted
      final isFormatted = _isFormattingActive(prefix, suffix);
      
      if (isFormatted && prefix.isNotEmpty && suffix.isNotEmpty) {
        // Remove formatting
        final beforeSelection = text.substring(0, selection.start);
        final afterSelection = text.substring(selection.end);
        
        // Check if prefix and suffix exist around selection
        if (beforeSelection.endsWith(prefix) && afterSelection.startsWith(suffix)) {
          final newText = beforeSelection.substring(0, beforeSelection.length - prefix.length) +
                         selectedText +
                         afterSelection.substring(suffix.length);
          
          widget.controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection(
              baseOffset: selection.start - prefix.length,
              extentOffset: selection.end - prefix.length,
            ),
          );
        }
      } else {
        // Add formatting
        String formattedText;
        int newCursorPosition;
        
        if (selectedText.isEmpty) {
          // No selection - insert formatting markers and place cursor between them
          formattedText = text.substring(0, selection.start) +
                         prefix + suffix +
                         text.substring(selection.end);
          newCursorPosition = selection.start + prefix.length;
        } else {
          // Has selection - wrap selected text
          formattedText = text.substring(0, selection.start) +
                         prefix + selectedText + suffix +
                         text.substring(selection.end);
          newCursorPosition = selection.start + prefix.length + selectedText.length + suffix.length;
        }
        
        widget.controller.value = TextEditingValue(
          text: formattedText,
          selection: TextSelection.collapsed(offset: newCursorPosition),
        );
      }
      
      // Request focus
      widget.focusNode.requestFocus();
      
    } catch (e) {
      debugPrint('Error formatting text: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to apply formatting'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _insertLink() {
    // Check if the widget is still mounted and has focus
    if (!widget.focusNode.hasFocus) {
      return;
    }
    
    // Get selected text for the link
    final selection = widget.controller.selection;
    String selectedText = '';
    
    try {
      if (selection.isValid && 
          selection.start >= 0 && 
          selection.end <= widget.controller.text.length) {
        selectedText = selection.textInside(widget.controller.text);
      }
    } catch (e) {
      debugPrint('Error getting selected text: $e');
    }
    
    // Show dialog to get the URL
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final urlController = TextEditingController();
        final textController = TextEditingController(text: selectedText);
        
        return AlertDialog(
          title: const Text('Insert Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Text to display',
                  hintText: 'Link text',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://example.com',
                  prefixIcon: Icon(Icons.link, size: 20),
                ),
                keyboardType: TextInputType.url,
                onSubmitted: (url) => _handleLinkInsertion(
                  context, 
                  urlController, 
                  textController.text,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => _handleLinkInsertion(
                context, 
                urlController, 
                textController.text,
              ),
              child: const Text('INSERT'),
            ),
          ],
        );
      },
    );
  }
  
  void _handleLinkInsertion(BuildContext context, TextEditingController urlController, String displayText) {
    final url = urlController.text.trim();
    if (url.isNotEmpty) {
      final linkText = displayText.isNotEmpty ? displayText : 'link';
      final markdownLink = '[$linkText]($url)';
      
      // Insert the markdown link at the current selection
      final selection = widget.controller.selection;
      final text = widget.controller.text;
      
      widget.controller.value = TextEditingValue(
        text: text.replaceRange(
          selection.start,
          selection.end,
          markdownLink,
        ),
        selection: TextSelection.collapsed(
          offset: selection.start + markdownLink.length,
        ),
      );
      
      widget.focusNode.requestFocus();
    }
    
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Pick an image from gallery or camera
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Show options dialog
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && widget.onImagePicked != null) {
        widget.onImagePicked!(image.path);
        
        // Insert image markdown at cursor position
        final selection = widget.controller.selection;
        final text = widget.controller.text;
        final imageName = image.path.split('/').last;
        final imageMarkdown = '\n![Image]($imageName)\n';
        
        widget.controller.value = TextEditingValue(
          text: text.replaceRange(
            selection.start,
            selection.end,
            imageMarkdown,
          ),
          selection: TextSelection.collapsed(
            offset: selection.start + imageMarkdown.length,
          ),
        );
        
        widget.focusNode.requestFocus();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  /// Pick a color for selected text
  Future<void> _pickTextColor() async {
    final Color? selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Text Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick color palette
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.pink,
                  Colors.teal,
                  Colors.brown,
                  Colors.indigo,
                ].map((color) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context, color);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Custom color picker
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _showCustomColorPicker();
                },
                icon: const Icon(Icons.palette),
                label: const Text('Custom Color'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    // Apply color to selected text if a color was selected
    if (mounted && selectedColor != null) {
      _applyTextColor(selectedColor);
    }
  }

  /// Show custom color picker
  Future<void> _showCustomColorPicker() async {
    Color pickerColor = Colors.black;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a Custom Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyTextColor(pickerColor);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  /// Apply color to selected text using HTML color syntax
  void _applyTextColor(Color color) {
    try {
      final text = widget.controller.text;
      final selection = widget.controller.selection;
      
      if (!selection.isValid || selection.start < 0 || selection.end > text.length) {
        return;
      }

      final selectedText = selection.textInside(text);
      if (selectedText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select text to color')),
        );
        return;
      }

      // Convert color to hex
      final colorHex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      
      // Use HTML span tag for colored text (works in markdown preview)
      final coloredText = '<span style="color: $colorHex">$selectedText</span>';
      
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        coloredText,
      );
      
      if (mounted) {
        widget.controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.start + coloredText.length,
          ),
        );
        widget.focusNode.requestFocus();
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Color applied! Switch to Preview mode to see it.'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 70, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error applying text color: $e');
    }
  }

  /// Delete selected text
  void _deleteSelectedText() {
    try {
      final text = widget.controller.text;
      final selection = widget.controller.selection;
      
      if (!selection.isValid || selection.start < 0 || selection.end > text.length) {
        return;
      }

      final selectedText = selection.textInside(text);
      if (selectedText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select text to delete'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Delete the selected text
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '',
      );
      
      if (mounted) {
        widget.controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.start,
          ),
        );
        widget.focusNode.requestFocus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted: "${selectedText.length > 20 ? selectedText.substring(0, 20) + '...' : selectedText}"'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 70, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting text: $e');
    }
  }
  
  /// Insert bullet list
  void _insertBulletList() {
    try {
      final text = widget.controller.text;
      final selection = widget.controller.selection;
      
      if (!selection.isValid || selection.start < 0 || selection.end > text.length) {
        return;
      }
      
      final selectedText = selection.textInside(text);
      String formattedText;
      int newCursorPosition;
      
      if (selectedText.isEmpty) {
        // No selection - insert bullet point
        final beforeText = text.substring(0, selection.start);
        final afterText = text.substring(selection.end);
        
        // Check if we're at the start of a line or need a newline
        final needsNewline = beforeText.isNotEmpty && !beforeText.endsWith('\n');
        final bulletPoint = needsNewline ? '\n- ' : '- ';
        
        formattedText = beforeText + bulletPoint + afterText;
        newCursorPosition = selection.start + bulletPoint.length;
      } else {
        // Has selection - convert each line to bullet point
        final lines = selectedText.split('\n');
        final bulletLines = lines.map((line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) return '';
          if (trimmed.startsWith('- ')) return line; // Already a bullet
          if (trimmed.startsWith(RegExp(r'\d+\. '))) {
            // Convert numbered list to bullet
            return line.replaceFirst(RegExp(r'\d+\. '), '- ');
          }
          return '- $trimmed';
        }).join('\n');
        
        formattedText = text.substring(0, selection.start) +
                       bulletLines +
                       text.substring(selection.end);
        newCursorPosition = selection.start + bulletLines.length;
      }
      
      widget.controller.value = TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
      widget.focusNode.requestFocus();
      
    } catch (e) {
      debugPrint('Error inserting bullet list: $e');
    }
  }
  
  /// Insert numbered list
  void _insertNumberedList() {
    try {
      final text = widget.controller.text;
      final selection = widget.controller.selection;
      
      if (!selection.isValid || selection.start < 0 || selection.end > text.length) {
        return;
      }
      
      final selectedText = selection.textInside(text);
      String formattedText;
      int newCursorPosition;
      
      if (selectedText.isEmpty) {
        // No selection - insert numbered point
        final beforeText = text.substring(0, selection.start);
        final afterText = text.substring(selection.end);
        
        // Check if we're at the start of a line or need a newline
        final needsNewline = beforeText.isNotEmpty && !beforeText.endsWith('\n');
        final numberedPoint = needsNewline ? '\n1. ' : '1. ';
        
        formattedText = beforeText + numberedPoint + afterText;
        newCursorPosition = selection.start + numberedPoint.length;
      } else {
        // Has selection - convert each line to numbered point
        final lines = selectedText.split('\n');
        int number = 1;
        final numberedLines = lines.map((line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) return '';
          if (trimmed.startsWith(RegExp(r'\d+\. '))) return line; // Already numbered
          if (trimmed.startsWith('- ')) {
            // Convert bullet to numbered list
            return line.replaceFirst('- ', '${number++}. ');
          }
          return '${number++}. $trimmed';
        }).join('\n');
        
        formattedText = text.substring(0, selection.start) +
                       numberedLines +
                       text.substring(selection.end);
        newCursorPosition = selection.start + numberedLines.length;
      }
      
      widget.controller.value = TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
      widget.focusNode.requestFocus();
      
    } catch (e) {
      debugPrint('Error inserting numbered list: $e');
    }
  }
  
  /// Insert checklist
  void _insertChecklist() {
    try {
      final text = widget.controller.text;
      final selection = widget.controller.selection;
      
      if (!selection.isValid || selection.start < 0 || selection.end > text.length) {
        return;
      }
      
      final selectedText = selection.textInside(text);
      String formattedText;
      int newCursorPosition;
      
      if (selectedText.isEmpty) {
        // No selection - insert checkbox
        final beforeText = text.substring(0, selection.start);
        final afterText = text.substring(selection.end);
        
        // Check if we're at the start of a line or need a newline
        final needsNewline = beforeText.isNotEmpty && !beforeText.endsWith('\n');
        final checkbox = needsNewline ? '\n- [ ] ' : '- [ ] ';
        
        formattedText = beforeText + checkbox + afterText;
        newCursorPosition = selection.start + checkbox.length;
      } else {
        // Has selection - convert each line to checkbox
        final lines = selectedText.split('\n');
        final checkboxLines = lines.map((line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) return '';
          
          // Already a checkbox (checked or unchecked)
          if (trimmed.startsWith('- [ ] ') || trimmed.startsWith('- [x] ') || trimmed.startsWith('- [X] ')) {
            return line;
          }
          
          // Convert bullet list to checkbox
          if (trimmed.startsWith('- ')) {
            return line.replaceFirst('- ', '- [ ] ');
          }
          
          // Convert numbered list to checkbox
          if (trimmed.startsWith(RegExp(r'\d+\. '))) {
            return line.replaceFirst(RegExp(r'\d+\. '), '- [ ] ');
          }
          
          // Plain text to checkbox
          return '- [ ] $trimmed';
        }).join('\n');
        
        formattedText = text.substring(0, selection.start) +
                       checkboxLines +
                       text.substring(selection.end);
        newCursorPosition = selection.start + checkboxLines.length;
      }
      
      widget.controller.value = TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
      widget.focusNode.requestFocus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checklist added! Switch to Preview mode to see and toggle checkboxes.'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 70, left: 16, right: 16),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('Error inserting checklist: $e');
    }
  }
}
