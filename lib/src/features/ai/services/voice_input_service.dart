// Voice input temporarily disabled due to package compatibility
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:flutter_tts/flutter_tts.dart';

/// Service for offline voice input and text-to-speech
/// Note: Voice features temporarily disabled due to Gradle compatibility
class VoiceInputService {
  // static final SpeechToText _speechToText = SpeechToText();
  // static final FlutterTts _flutterTts = FlutterTts();
  static const bool _isInitialized = false;
  
  /// Initialize voice services
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    // Voice features temporarily disabled
    print('Voice input is temporarily disabled due to package compatibility');
    return false;
  }
  
  /// Check if speech recognition is available
  static Future<bool> isAvailable() async {
    return false; // Temporarily disabled
  }
  
  /// Start listening for voice input
  static Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
  }) async {
    throw Exception('Voice input temporarily disabled. Enable it by uncommenting speech_to_text in pubspec.yaml');
  }
  
  /// Stop listening
  static Future<void> stopListening() async {
    // Disabled
  }
  
  /// Check if currently listening
  static bool isListening() {
    return false;
  }
  
  /// Speak text (text-to-speech)
  static Future<void> speak(String text) async {
    // Disabled
  }
  
  /// Stop speaking
  static Future<void> stopSpeaking() async {
    // Disabled
  }
  
  /// Get available languages
  static Future<List<String>> getAvailableLanguages() async {
    return [];
  }
  
  /// Set language
  static Future<void> setLanguage(String languageCode) async {
    // Disabled
  }
  
  /// Process voice command
  static VoiceCommand? processCommand(String text) {
    final lowerText = text.toLowerCase();
    
    // Create note command
    if (lowerText.contains('create') && lowerText.contains('note')) {
      return VoiceCommand(
        type: CommandType.createNote,
        text: text,
      );
    }
    
    // Search command
    if (lowerText.contains('search') || lowerText.contains('find')) {
      final searchQuery = lowerText
          .replaceAll('search', '')
          .replaceAll('find', '')
          .trim();
      return VoiceCommand(
        type: CommandType.search,
        text: searchQuery,
      );
    }
    
    // Calculate command
    if (lowerText.contains('calculate') || lowerText.contains('compute')) {
      return VoiceCommand(
        type: CommandType.calculate,
        text: text,
      );
    }
    
    // Open calculator
    if (lowerText.contains('open calculator')) {
      return VoiceCommand(
        type: CommandType.openCalculator,
        text: text,
      );
    }
    
    // Delete note
    if (lowerText.contains('delete')) {
      return VoiceCommand(
        type: CommandType.deleteNote,
        text: text,
      );
    }
    
    // Default: just text input
    return VoiceCommand(
      type: CommandType.textInput,
      text: text,
    );
  }
}

/// Voice command model
class VoiceCommand {
  final CommandType type;
  final String text;
  
  VoiceCommand({
    required this.type,
    required this.text,
  });
}

/// Command type enum
enum CommandType {
  createNote,
  search,
  calculate,
  openCalculator,
  deleteNote,
  textInput,
}
