import 'dart:async';
import 'package:flutter/material.dart';
import 'package:calcnote/src/features/ai/services/formula_detection_service.dart';
import 'package:calcnote/src/features/ai/services/text_understanding_service.dart';
import 'package:calcnote/src/features/ai/services/smart_suggestion_service.dart';
import 'package:calcnote/src/features/ai/services/offline_translation_service.dart';
import 'package:calcnote/src/features/ai/services/local_ai_chat_service.dart';
import 'package:calcnote/src/features/ai/services/voice_input_service.dart';
import 'package:calcnote/src/features/ai/services/auto_theme_service.dart';
import 'package:calcnote/src/features/notes/models/note_model.dart';
import 'package:calcnote/src/features/notes/services/note_database_service.dart';
import 'package:calcnote/src/features/notes/providers/note_provider.dart';
import 'package:calcnote/src/features/pdf/providers/pdf_provider.dart';
import 'package:calcnote/src/features/pdf/services/pdf_storage_service.dart';

/// Provider for managing all AI features
class AIProvider extends ChangeNotifier {
  // Voice input state
  bool _isListening = false;
  String _voiceInput = '';
  
  // AI chat state
  final List<ChatMessage> _chatHistory = [];
  
  // Theme state
  ThemeMode _themeMode = ThemeMode.system;
  bool _autoTheme = true;
  Timer? _themeTimer;

  final NoteDatabaseService _databaseService;
  
  // Suggestions state
  List<SmartSuggestion> _suggestions = [];
  List<QuickAction> _quickActions = [];

  // Data sources for contextual answers
  NoteProvider? _noteProvider;
  PdfProvider? _pdfProvider;
  
  // Getters
  bool get isListening => _isListening;
  String get voiceInput => _voiceInput;
  List<ChatMessage> get chatHistory => _chatHistory;
  ThemeMode get themeMode => _themeMode;
  bool get autoTheme => _autoTheme;
  List<SmartSuggestion> get suggestions => _suggestions;
  List<QuickAction> get quickActions => _quickActions;
  
  /// Initialize AI services
  Future<void> initialize() async {
    await _loadThemeSettings();
    await VoiceInputService.initialize();
    _updateThemeByTime();
    _startThemeTimer();
    notifyListeners();
  }

  AIProvider({NoteDatabaseService? databaseService})
      : _databaseService = databaseService ?? NoteDatabaseService();

  Future<void> _loadThemeSettings() async {
    final saved = _databaseService.getThemeMode();
    final parsed = _parseThemeMode(saved);

    if (parsed != null) {
      _themeMode = parsed;
    }

    // Backwards compatible: if saved mode is system, treat it as auto theme enabled.
    // If saved mode is light/dark, treat it as manual (auto disabled).
    _autoTheme = (_themeMode == ThemeMode.system);
  }

  ThemeMode? _parseThemeMode(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }

  Future<void> _persistThemeSettings() async {
    await _databaseService.setThemeMode(_themeMode.name);
  }

  /// Inject data sources for contextual chat responses
  void updateDataSources({NoteProvider? noteProvider, PdfProvider? pdfProvider}) {
    _noteProvider = noteProvider ?? _noteProvider;
    _pdfProvider = pdfProvider ?? _pdfProvider;
  }
  
  /// Analyze note content and add AI features
  NoteModel analyzeNote(NoteModel note) {
    // Detect category
    final category = TextUnderstandingService.analyzeText(note.content);
    
    // Generate summary
    final summary = TextUnderstandingService.summarizeText(note.content);
    
    // Auto-tag based on category
    final tags = List<String>.from(note.tags);
    if (!tags.contains(category.displayName)) {
      tags.add(category.displayName);
    }
    
    return note.copyWith(
      category: category.displayName,
      summary: summary.isNotEmpty ? summary : null,
      tags: tags,
    );
  }
  
  /// Detect formulas in text
  List<DetectedFormula> detectFormulas(String text) {
    return FormulaDetectionService.detectFormulas(text);
  }
  
  /// Get smart suggestions for text
  void updateSuggestions(String text) {
    _suggestions = SmartSuggestionService.getSuggestions(text);
    _quickActions = SmartSuggestionService.getQuickActions(text);
    notifyListeners();
  }
  
  /// Start voice input
  Future<void> startVoiceInput(Function(String) onResult) async {
    try {
      _isListening = true;
      notifyListeners();
      
      await VoiceInputService.startListening(
        onResult: (text) {
          _voiceInput = text;
          onResult(text);
          _isListening = false;
          notifyListeners();
        },
        onPartialResult: (text) {
          _voiceInput = text;
          notifyListeners();
        },
      );
    } catch (e) {
      _isListening = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Stop voice input
  Future<void> stopVoiceInput() async {
    await VoiceInputService.stopListening();
    _isListening = false;
    notifyListeners();
  }
  
  /// Process voice command
  VoiceCommand? processVoiceCommand(String text) {
    return VoiceInputService.processCommand(text);
  }
  
  /// Speak text
  Future<void> speak(String text) async {
    await VoiceInputService.speak(text);
  }
  
  /// Chat with local AI
  String chatWithAI(String query) {
    final response = LocalAIChatService.getResponse(
      query,
      context: _buildAssistantContext(),
    );
    
    _chatHistory.add(ChatMessage(
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    
    _chatHistory.add(ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    
    notifyListeners();
    return response;
  }
  
  /// Get suggested questions for AI chat
  List<String> getSuggestedQuestions() {
    return LocalAIChatService.getSuggestedQuestions();
  }
  
  /// Clear chat history
  void clearChatHistory() {
    _chatHistory.clear();
    notifyListeners();
  }
  
  /// Translate text
  String translateText(String text, {bool toHindi = false}) {
    if (toHindi) {
      return OfflineTranslationService.translateEnglishToHindi(text);
    } else {
      return OfflineTranslationService.translateHindiToEnglish(text);
    }
  }
  
  /// Auto translate (detect language)
  String autoTranslate(String text) {
    return OfflineTranslationService.autoTranslate(text);
  }
  
  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _autoTheme = false;
    _stopThemeTimer();
    notifyListeners();
    _persistThemeSettings();
  }
  
  /// Toggle auto theme
  void toggleAutoTheme(bool enabled) {
    _autoTheme = enabled;
    if (enabled) {
      // Represent auto theme using ThemeMode.system, while actual light/dark is decided by time.
      _themeMode = ThemeMode.system;
      _updateThemeByTime();
      _startThemeTimer();
    } else {
      _stopThemeTimer();
    }
    notifyListeners();
    _persistThemeSettings();
  }
  
  /// Update theme based on time
  void _updateThemeByTime() {
    if (_autoTheme) {
      final newThemeMode = AutoThemeService.getThemeModeByTime();
      if (_themeMode != newThemeMode) {
        // Keep the persisted preference as system while applying computed theme.
        _themeMode = newThemeMode;
        notifyListeners();
      }
    }
  }
  
  /// Start periodic theme timer
  void _startThemeTimer() {
    _stopThemeTimer();
    if (_autoTheme) {
      // Check theme every minute
      _themeTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _updateThemeByTime();
      });
    }
  }
  
  /// Stop theme timer
  void _stopThemeTimer() {
    _themeTimer?.cancel();
    _themeTimer = null;
  }
  
  /// Get theme description
  String getThemeDescription() {
    return AutoThemeService.getThemeDescription();
  }
  
  /// Calculate sum from text
  double? calculateSum(String text) {
    return FormulaDetectionService.calculateSum(text);
  }
  
  /// Calculate average from text
  double? calculateAverage(String text) {
    return FormulaDetectionService.calculateAverage(text);
  }
  
  /// Extract key information from text
  Map<String, dynamic> extractKeyInfo(String text) {
    return TextUnderstandingService.extractKeyInfo(text);
  }
  
  /// Generate suggestions based on text
  List<String> generateTextSuggestions(String text) {
    return TextUnderstandingService.generateSuggestions(text);
  }

  AssistantContext? _buildAssistantContext() {
    final noteProvider = _noteProvider;
    final pdfProvider = _pdfProvider;

    if (noteProvider == null && pdfProvider == null) {
      return null;
    }

    final notes = List<NoteModel>.from(noteProvider?.notes ?? []);
    final noteCount = notes.length;
    final pinnedCount = notes.where((note) => note.isPinned).length;
    final archivedCount = notes.where((note) => note.isArchived).length;
    final lockedCount = notes.where((note) => note.isLocked).length;
    final recentNoteTitles = notes
        .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recentNoteNames = recentNoteTitles
        .take(3)
        .map((note) => note.title.trim().isEmpty ? 'Untitled Note' : note.title.trim())
        .toList();

    DateTime? lastUpdated;
    if (notes.isNotEmpty) {
      lastUpdated = notes
          .map((note) => note.updatedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    final tags = noteProvider?.getAllTags() ?? <String>{};

    final allPdfs = PdfStorageService.getAllPdfAttachments();
    final pdfCount = allPdfs.length;
    final recentPdfTitles = (pdfProvider?.recentPdfs ?? [])
        .take(3)
        .map((pdf) => pdf.fileName)
        .toList();

    return AssistantContext(
      noteCount: noteCount,
      pinnedCount: pinnedCount,
      archivedCount: archivedCount,
      lockedCount: lockedCount,
      recentNoteTitles: recentNoteNames,
      lastUpdated: lastUpdated,
      tags: tags,
      pdfCount: pdfCount,
      recentPdfTitles: recentPdfTitles,
    );
  }
  
  @override
  void dispose() {
    _stopThemeTimer();
    super.dispose();
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
