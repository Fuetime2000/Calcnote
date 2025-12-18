import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calcnote/src/features/notes/models/note_model.dart';
import 'package:calcnote/src/features/notes/providers/note_provider.dart';
import 'package:calcnote/src/features/notes/widgets/note_list_item.dart';
import 'package:calcnote/src/features/notes/screens/note_editor_screen.dart';
import 'package:calcnote/src/core/utils/calculation_utils.dart';
import 'package:calcnote/src/features/ai/providers/ai_provider.dart';
import 'package:calcnote/src/features/ai/widgets/ai_chat_dialog.dart';
import 'package:calcnote/src/features/ai/services/formula_detection_service.dart';
import 'package:calcnote/src/features/security/screens/security_settings_screen.dart';
import 'package:calcnote/src/features/security/services/app_lock_service.dart';
import 'package:calcnote/src/features/pdf/screens/recent_pdfs_screen.dart';
import 'package:calcnote/src/features/settings/screens/privacy_policy_screen.dart';
import 'package:calcnote/src/features/settings/screens/terms_and_conditions_screen.dart';
import 'package:calcnote/src/features/reminders/widgets/reminder_dialog.dart';
import 'package:calcnote/src/features/help/screens/how_to_use_screen.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _calculatorController = TextEditingController();
  bool _showSearch = false;
  int _selectedIndex = 0;
  String? _calculatorResult;
  List<DetectedFormula> _detectedFormulas = [];
  
  @override
  void initState() {
    super.initState();
    // Load notes when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteProvider>().loadNotes();
      context.read<AIProvider>().initialize();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _calculatorController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged(String query) {
    context.read<NoteProvider>().searchNotes(query);
  }
  
  void _clearSearch() {
    _searchController.clear();
    context.read<NoteProvider>().clearSearch();
    setState(() {
      _showSearch = false;
    });
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCalculatorInputChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _calculatorResult = null;
        _detectedFormulas = [];
      });
      return;
    }
    
    // Detect formulas using AI
    final formulas = FormulaDetectionService.detectFormulas(value);
    
    // Only evaluate if the last character is a number or closing parenthesis
    final lastChar = value.isNotEmpty ? value[value.length - 1] : '';
    if (RegExp(r'[0-9)]').hasMatch(lastChar)) {
      final result = CalculationUtils.evaluateExpression(value);
      setState(() {
        _calculatorResult = result.isNotEmpty ? result : null;
        _detectedFormulas = formulas;
      });
    } else {
      setState(() {
        _calculatorResult = null;
        _detectedFormulas = formulas;
      });
    }
  }

  // Show calculator dialog
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

    void updateCalculation(String value) {
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
          result = CalculationUtils.evaluateExpression(calculatorController.text);
          if (result?.isNotEmpty ?? false) {
            calculatorController.text = result!;
          }
          return;
        }
      } else {
        calculatorController.text += value;
      }

      if (calculatorController.text.trim().isNotEmpty) {
        final res = CalculationUtils.evaluateExpression(calculatorController.text);
        result = res.isNotEmpty ? res : null;
      } else {
        result = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                          setState(() {});
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
                      onPressed: (calculatorController.text.isNotEmpty && result != null)
                          ? () {
                              _saveCalculation(calculatorController.text, result!);
                              Navigator.pop(context);
                            }
                          : null,
                      child: const Text('Save as Note'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          ),
          )
        ),
      ),
    );
  }

  // Save calculation to notes
  Future<void> _saveCalculation(String expression, String result) async {
    final noteProvider = context.read<NoteProvider>();
    final note = NoteModel(
      title: 'Calculation',
      content: '$expression = $result',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await noteProvider.createNote(note);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calculation saved to notes')),
      );
    }
  }

  void _evaluateAndAddNote() async {
    if (_calculatorController.text.trim().isEmpty || _calculatorResult == null) {
      return;
    }
    await _saveCalculation(_calculatorController.text, _calculatorResult!);
    
    // Clear the calculator
    setState(() {
      _calculatorController.clear();
      _calculatorResult = null;
      _detectedFormulas = [];
    });
  }

  // Toggle voice input
  void _toggleVoiceInput() async {
    final aiProvider = context.read<AIProvider>();
    
    if (aiProvider.isListening) {
      await aiProvider.stopVoiceInput();
    } else {
      try {
        await aiProvider.startVoiceInput((text) {
          setState(() {
            _calculatorController.text = text;
            _onCalculatorInputChanged(text);
          });
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice input error: $e')),
          );
        }
      }
    }
  }

  // Show AI chat dialog
  void _showAIChat() {
    showDialog(
      context: context,
      builder: (context) => const AIChatDialog(),
    );
  }

  // Handle menu actions
  void _handleMenuAction(String action) async {
    switch (action) {
      case 'how_to_use':
        _showHowToUse();
        break;
      case 'backup':
        _showBackupDialog();
        break;
      case 'translate':
        _showTranslateDialog();
        break;
      case 'security':
        _showSecuritySettings();
        break;
      case 'theme_light':
        _setTheme(ThemeMode.light);
        break;
      case 'theme_dark':
        _setTheme(ThemeMode.dark);
        break;
      case 'theme_auto':
        _showAutoThemeDialog();
        break;
      case 'privacy':
        _showPrivacyPolicy();
        break;
      case 'terms':
        _showTermsAndConditions();
        break;
    }
  }

  // Show how to use screen
  void _showHowToUse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HowToUseScreen()),
    );
  }

  // Show backup dialog
  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.blue),
            SizedBox(width: 12),
            Text('Backup Notes'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create a readable backup of all your notes.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Backup includes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• All note titles and content', style: TextStyle(fontSize: 12)),
                  Text('• Tags and categories', style: TextStyle(fontSize: 12)),
                  Text('• Creation and update dates', style: TextStyle(fontSize: 12)),
                  Text('• Saved as readable text file', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.download, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saved to Downloads folder. Use Share to move it.',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _createBackup();
            },
            icon: const Icon(Icons.save_alt),
            label: const Text('Create Backup'),
          ),
        ],
      ),
    );
  }

  // Create backup file
  Future<void> _createBackup() async {
    try {
      // Get all notes
      final noteProvider = context.read<NoteProvider>();
      final notes = noteProvider.notes;

      if (notes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No notes to backup'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show loading
      if (!mounted) return;
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
              Text('Creating backup...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Create readable backup content
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('═══════════════════════════════════════════════════════');
      buffer.writeln('              CALCNOTE BACKUP FILE');
      buffer.writeln('═══════════════════════════════════════════════════════');
      buffer.writeln('Created: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now())}');
      buffer.writeln('Total Notes: ${notes.length}');
      buffer.writeln('═══════════════════════════════════════════════════════');
      buffer.writeln();
      buffer.writeln();

      // Add each note
      for (int i = 0; i < notes.length; i++) {
        final note = notes[i];
        
        buffer.writeln('───────────────────────────────────────────────────────');
        buffer.writeln('NOTE ${i + 1} of ${notes.length}');
        buffer.writeln('───────────────────────────────────────────────────────');
        buffer.writeln();
        
        // Title
        buffer.writeln('TITLE: ${note.title.isEmpty ? "(Untitled)" : note.title}');
        buffer.writeln();
        
        // Metadata
        buffer.writeln('Created: ${DateFormat('MMM dd, yyyy - hh:mm a').format(note.createdAt)}');
        buffer.writeln('Updated: ${DateFormat('MMM dd, yyyy - hh:mm a').format(note.updatedAt)}');
        
        if (note.category != null && note.category!.isNotEmpty) {
          buffer.writeln('Category: ${note.category}');
        }
        
        if (note.tags.isNotEmpty) {
          buffer.writeln('Tags: ${note.tags.join(', ')}');
        }
        
        if (note.isPinned) {
          buffer.writeln('Status: 📌 Pinned');
        }
        
        if (note.isLocked) {
          buffer.writeln('Security: 🔒 Locked');
        }
        
        buffer.writeln();
        buffer.writeln('─── CONTENT ───');
        buffer.writeln();
        
        // Content
        if (note.content.isEmpty) {
          buffer.writeln('(Empty note)');
        } else {
          buffer.writeln(note.content);
        }
        
        buffer.writeln();
        buffer.writeln();
      }

      // Footer
      buffer.writeln('═══════════════════════════════════════════════════════');
      buffer.writeln('              END OF BACKUP');
      buffer.writeln('═══════════════════════════════════════════════════════');
      buffer.writeln('Backup created by CalcNote');
      buffer.writeln('Total notes backed up: ${notes.length}');
      buffer.writeln('═══════════════════════════════════════════════════════');

      // Create filename with timestamp
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final filename = 'CalcNote_Backup_$timestamp.txt';

      // Get directory to save
      Directory? directory;
      if (Platform.isAndroid) {
        // Try Downloads folder first
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage
          directory = await getExternalStorageDirectory();
        }
      } else {
        // iOS - use documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage');
      }

      // Write to file
      final file = File('${directory.path}/$filename');
      await file.writeAsString(buffer.toString());

      // Hide loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show success with share and move options
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Backup created successfully!'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${notes.length} notes backed up',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
              Text(
                'Saved to: ${directory.path}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'File: $filename',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () async {
              try {
                await Share.shareXFiles(
                  [XFile(file.path)],
                  subject: 'CalcNote Backup',
                  text: 'My CalcNote backup - ${notes.length} notes from ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                );
              } catch (e) {
                debugPrint('Error sharing: $e');
              }
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error creating backup: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create backup: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Show translate dialog
  void _showTranslateDialog() {
    showDialog(
      context: context,
      builder: (context) => const _TranslateDialog(),
    );
  }

  // Set theme directly
  void _setTheme(ThemeMode mode) {
    final aiProvider = context.read<AIProvider>();
    
    // Disable auto theme
    if (aiProvider.autoTheme) {
      aiProvider.toggleAutoTheme(false);
    }
    
    // Set the theme mode
    aiProvider.setThemeMode(mode);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == ThemeMode.light 
              ? '☀️ Light theme enabled' 
              : '🌙 Dark theme enabled'
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show auto theme dialog
  void _showAutoThemeDialog() {
    final aiProvider = context.read<AIProvider>();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isAutoEnabled = aiProvider.autoTheme;
          final themeDescription = aiProvider.getThemeDescription();
          
          return AlertDialog(
            title: const Text('🌓 Auto Theme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automatically switch between light and dark mode based on time of day.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable Auto Theme'),
                  subtitle: Text(isAutoEnabled ? themeDescription : 'Manual theme control'),
                  value: isAutoEnabled,
                  onChanged: (value) {
                    aiProvider.toggleAutoTheme(value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.wb_sunny, size: 20),
                          SizedBox(width: 8),
                          Text('Light Mode: 6 AM - 6 PM'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.nightlight_round, size: 20),
                          SizedBox(width: 8),
                          Text('Dark Mode: 6 PM - 6 AM'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Show security settings
  void _showSecuritySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SecuritySettingsScreen(),
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _showTermsAndConditions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsAndConditionsScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final noteProvider = context.watch<NoteProvider>();
    final theme = Theme.of(context);
    
    return WillPopScope(
      onWillPop: () async {
        // If not on the first tab (Notes), navigate to Notes tab
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false; // Don't exit the app
        }
        // If already on Notes tab, allow exit
        return true;
      },
      child: Scaffold(
      appBar: _buildAppBar(theme, context),
      body: Column(
        children: [
          // AI-powered Calculator input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calculate, size: 24),
                      onPressed: _showCalculatorDialog,
                      tooltip: 'Open Calculator',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _calculatorController,
                        decoration: InputDecoration(
                          hintText: '🧠 Type calculation or formula (AI-powered)',
                          border: InputBorder.none,
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        style: theme.textTheme.bodyLarge,
                        onChanged: _onCalculatorInputChanged,
                        onSubmitted: (_) => _evaluateAndAddNote(),
                      ),
                    ),
                    // Voice input button (temporarily disabled)
                    // IconButton(
                    //   icon: Icon(
                    //     context.watch<AIProvider>().isListening
                    //         ? Icons.mic
                    //         : Icons.mic_none,
                    //     color: context.watch<AIProvider>().isListening
                    //         ? Colors.red
                    //         : null,
                    //   ),
                    //   onPressed: _toggleVoiceInput,
                    //   tooltip: 'Voice Input',
                    // ),
                    if (_calculatorResult != null) ...[
                      Text(
                        '= $_calculatorResult',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.note_add),
                        onPressed: _evaluateAndAddNote,
                        tooltip: 'Add as note',
                      ),
                    ],
                  ],
                ),
                // Show detected formulas
                if (_detectedFormulas.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _detectedFormulas.take(2).map((formula) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '💡 ${formula.expression}: ${formula.result}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          // Main content
          Expanded(child: _buildBody(noteProvider, theme)),
        ],
      ),
      floatingActionButton: _selectedIndex == 3
          ? null
          : FloatingActionButton(
              onPressed: () {
                // Navigate to the note editor screen to create a new note
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NoteEditorScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notes),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            label: 'Starred',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.archive_outlined),
            label: 'Archive',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'PDFs',
          ),
        ],
      ),
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(ThemeData theme, BuildContext context) {
    return AppBar(
      title: _showSearch 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                border: InputBorder.none,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              style: theme.textTheme.bodyLarge,
              onChanged: _onSearchChanged,
            )
          : const Text('CalcNote'),
      actions: [
        if (_showSearch)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _clearSearch,
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = true;
              });
            },
          ),
          // AI Chat button
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: _showAIChat,
            tooltip: 'AI Assistant',
          ),
        ],
        // Settings menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'how_to_use',
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('How to Use'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'backup',
              child: Row(
                children: [
                  Icon(Icons.backup),
                  SizedBox(width: 8),
                  Text('Backup Notes'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'translate',
              child: Row(
                children: [
                  Icon(Icons.translate),
                  SizedBox(width: 8),
                  Text('Translate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'security',
              child: Row(
                children: [
                  Icon(Icons.lock),
                  SizedBox(width: 8),
                  Text('Security'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'theme_light',
              child: Row(
                children: [
                  Icon(Icons.light_mode, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Light Theme'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'theme_dark',
              child: Row(
                children: [
                  Icon(Icons.dark_mode, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Dark Theme'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'theme_auto',
              child: Row(
                children: [
                  Icon(Icons.brightness_auto, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Auto Theme'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'privacy',
              child: Row(
                children: [
                  Icon(Icons.privacy_tip),
                  SizedBox(width: 8),
                  Text('Privacy Policy'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'terms',
              child: Row(
                children: [
                  Icon(Icons.article_outlined),
                  SizedBox(width: 8),
                  Text('Terms & Conditions'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildBody(NoteProvider noteProvider, ThemeData theme) {
    // Show PDF screen when PDFs tab is selected
    if (_selectedIndex == 3) {
      return const RecentPdfsScreen();
    }
    
    if (noteProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (noteProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading notes',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              noteProvider.error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => noteProvider.loadNotes(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final notes = _getNotesForCurrentTab(noteProvider);
    
    if (notes.isEmpty) {
      return _buildEmptyState(theme);
    }
    
    return RefreshIndicator(
      onRefresh: () => noteProvider.loadNotes(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteListItem(
            note: note,
            searchQuery: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
            onTap: () => _handleNoteTap(note),
            onLongPress: () => _showNoteOptionsSheet(context, noteProvider, note),
            onPinPressed: () => noteProvider.togglePinStatus(note.id),
            onArchivePressed: () => noteProvider.toggleArchiveStatus(note.id),
            onDeletePressed: () => _showDeleteConfirmation(context, noteProvider, note.id),
          );
        },
      ),
    );
  }
  
  List<NoteModel> _getNotesForCurrentTab(NoteProvider noteProvider) {
    switch (_selectedIndex) {
      case 0: // All notes
        return noteProvider.filteredNotes.where((note) => !note.isArchived).toList();
      case 1: // Pinned/Starred
        return noteProvider.pinnedNotes.where((note) => !note.isArchived).toList();
      case 2: // Archived
        return noteProvider.archivedNotes;
      default:
        return [];
    }
  }
  
  Widget _buildEmptyState(ThemeData theme) {
    String message;
    IconData icon;
    
    if (_searchController.text.isNotEmpty) {
      message = 'No notes found for "${_searchController.text}"';
      icon = Icons.search_off;
    } else {
      switch (_selectedIndex) {
        case 0:
          message = 'No notes yet';
          break;
        case 1:
          message = 'No pinned notes';
          break;
        case 2:
          message = 'No archived notes';
          break;
        default:
          message = 'No items';
      }
      icon = _selectedIndex == 0 ? Icons.note_add_outlined : Icons.star_border;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.hintColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
          if (_selectedIndex == 0 && _searchController.text.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first note',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Handle note tap - check if locked
  Future<void> _handleNoteTap(NoteModel note) async {
    if (note.isLocked) {
      // Note is locked, require authentication
      bool authenticated = false;
      
      // Try biometric first if available
      final isBiometricAvailable = await AppLockService.isBiometricAvailable();
      if (isBiometricAvailable) {
        authenticated = await AppLockService.authenticateWithBiometrics();
      }
      
      // If biometric failed or not available, show PIN dialog
      if (!authenticated) {
        final isPinSet = await AppLockService.isPinSet();
        if (isPinSet) {
          authenticated = await _showPinDialog(context);
        }
      }
      
      if (!authenticated) {
        // Authentication failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔒 Authentication required to view this note'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    
    // Note is unlocked or authentication successful, open it
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note),
      ),
    );
  }

  // Show note options bottom sheet (long press)
  void _showNoteOptionsSheet(
    BuildContext context,
    NoteProvider noteProvider,
    NoteModel note,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Note title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                note.title.isEmpty ? 'Untitled Note' : note.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            
            // Set Reminder option
            ListTile(
              leading: const Icon(Icons.alarm_add, color: Colors.orange),
              title: const Text('Set Reminder'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => ReminderDialog(
                    noteId: note.id,
                    noteTitle: note.title.isEmpty ? 'Untitled Note' : note.title,
                  ),
                );
              },
            ),
            
            // Lock/Unlock option
            ListTile(
              leading: Icon(
                note.isLocked ? Icons.lock_open : Icons.lock,
                color: note.isLocked ? Colors.green : Colors.blue,
              ),
              title: Text(note.isLocked ? 'Unlock Note' : 'Lock Note'),
              onTap: () {
                Navigator.pop(context);
                _showNoteLockDialog(context, noteProvider, note);
              },
            ),
            
            // Pin/Unpin option
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: note.isPinned ? Colors.purple : Colors.grey,
              ),
              title: Text(note.isPinned ? 'Unpin Note' : 'Pin Note'),
              onTap: () {
                Navigator.pop(context);
                noteProvider.togglePinStatus(note.id);
              },
            ),
            
            // Archive/Unarchive option
            ListTile(
              leading: Icon(
                note.isArchived ? Icons.unarchive : Icons.archive,
                color: Colors.brown,
              ),
              title: Text(note.isArchived ? 'Unarchive' : 'Archive'),
              onTap: () {
                Navigator.pop(context);
                noteProvider.toggleArchiveStatus(note.id);
              },
            ),
            
            // Delete option
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, noteProvider, note.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show note lock dialog
  void _showNoteLockDialog(
    BuildContext context,
    NoteProvider noteProvider,
    NoteModel note,
  ) async {
    final theme = Theme.of(context);
    final isLocked = note.isLocked;
    
    // Check if app lock is set up
    final isPinSet = await AppLockService.isPinSet();
    final isBiometricAvailable = await AppLockService.isBiometricAvailable();
    
    if (!isPinSet && !isLocked) {
      // No security set up yet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set up app security first in Settings → Security'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isLocked ? Icons.lock_open : Icons.lock,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(isLocked ? 'Unlock Note' : 'Lock Note'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLocked
                  ? 'This note is currently locked. Unlock it to make it accessible without authentication.'
                  : 'Lock this note to protect it with PIN or biometric authentication.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Security Info:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Locked notes require authentication to view\n'
                    '• Uses your app PIN or biometric\n'
                    '• Lock icon shown on note card',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: Icon(isLocked ? Icons.lock_open : Icons.lock),
            label: Text(isLocked ? 'Unlock' : 'Lock'),
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              // Both lock and unlock require authentication
              bool authenticated = false;
              
              // Try biometric first if available
              if (isBiometricAvailable) {
                authenticated = await AppLockService.authenticateWithBiometrics();
              }
              
              // If biometric failed or not available, show PIN dialog
              if (!authenticated && isPinSet) {
                authenticated = await _showPinDialog(context);
              }
              
              if (authenticated) {
                // Authentication successful, toggle lock status
                await noteProvider.toggleLockStatus(note.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isLocked ? '🔓 Note unlocked' : '🔒 Note locked successfully'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                // Authentication failed
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Authentication failed'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
  
  // Show PIN dialog for authentication
  Future<bool> _showPinDialog(BuildContext context) async {
    final controller = TextEditingController();
    bool? result;
    
    try {
      result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _PinDialog(controller: controller),
      );
    } finally {
      // Ensure controller is disposed after dialog closes
      await Future.delayed(const Duration(milliseconds: 100));
      controller.dispose();
    }
    
    return result ?? false;
  }

  void _showDeleteConfirmation(
    BuildContext context, 
    NoteProvider noteProvider, 
    String noteId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              noteProvider.deleteNote(noteId);
              Navigator.pop(context);
              
              // Show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// PIN Dialog Widget
class _PinDialog extends StatelessWidget {
  final TextEditingController controller;

  const _PinDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter PIN'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'PIN',
          border: OutlineInputBorder(),
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final isValid = await AppLockService.verifyPin(controller.text);
            if (context.mounted) {
              Navigator.pop(context, isValid);
            }
          },
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

// Translate Dialog Widget
class _TranslateDialog extends StatefulWidget {
  const _TranslateDialog();

  @override
  State<_TranslateDialog> createState() => _TranslateDialogState();
}

class _TranslateDialogState extends State<_TranslateDialog> {
  final TextEditingController _controller = TextEditingController();
  String _translated = '';
  bool _toHindi = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _translate(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _translated = '';
      });
      return;
    }

    final aiProvider = context.read<AIProvider>();
    setState(() {
      if (_toHindi) {
        _translated = aiProvider.translateText(text, toHindi: true);
      } else {
        _translated = aiProvider.autoTranslate(text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(
            child: Text(
              '🌐 Translate',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Auto Detect',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: _toHindi,
                  onChanged: (value) {
                    setState(() {
                      _toHindi = value;
                      _translate(_controller.text);
                    });
                  },
                ),
                const Flexible(
                  child: Text(
                    'EN → HI',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Input field
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: _toHindi ? 'Enter English text' : 'Enter text (Hindi or English)',
                border: const OutlineInputBorder(),
                hintText: _toHindi ? 'e.g., note, expense, total' : 'e.g., नोट, खर्च, कुल',
              ),
              onChanged: _translate,
            ),
            
            const SizedBox(height: 16),
            
            // Translation result
            if (_translated.isNotEmpty) ...[
              Text(
                'Translation:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _translated,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Example words
            Text(
              'Try these words:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_toHindi) ...[
                  _buildExampleChip('hello', theme),
                  _buildExampleChip('thank you', theme),
                  _buildExampleChip('money', theme),
                  _buildExampleChip('expense', theme),
                  _buildExampleChip('profit', theme),
                  _buildExampleChip('family', theme),
                  _buildExampleChip('book', theme),
                  _buildExampleChip('food', theme),
                ] else ...[
                  _buildExampleChip('नमस्ते', theme),
                  _buildExampleChip('धन्यवाद', theme),
                  _buildExampleChip('पैसा', theme),
                  _buildExampleChip('खर्च', theme),
                  _buildExampleChip('लाभ', theme),
                  _buildExampleChip('परिवार', theme),
                  _buildExampleChip('किताब', theme),
                  _buildExampleChip('खाना', theme),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (_translated.isNotEmpty)
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
            onPressed: () {
              // Copy to clipboard functionality would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Translation copied!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildExampleChip(String word, ThemeData theme) {
    return ActionChip(
      label: Text(word),
      onPressed: () {
        _controller.text = word;
        _translate(word);
      },
    );
  }
}
