import 'package:hive_flutter/hive_flutter.dart';
import 'package:calcnote/src/features/notes/models/note_model.dart';
import 'package:calcnote/src/core/constants/app_constants.dart';

class NoteDatabaseService {
  static final NoteDatabaseService _instance = NoteDatabaseService._internal();
  factory NoteDatabaseService() => _instance;
  NoteDatabaseService._internal();

  late Box<NoteModel> _notesBox;
  late Box _settingsBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NoteModelAdapter());
    }
    
    // Open boxes
    _notesBox = await Hive.openBox<NoteModel>(AppConstants.notesBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    
    // Initialize default settings if first run
    await _initializeDefaultSettings();
  }

  /// Initialize default settings
  Future<void> _initializeDefaultSettings() async {
    if (!_settingsBox.containsKey(AppConstants.themeMode)) {
      await _settingsBox.put(AppConstants.themeMode, 'system');
    }
    if (!_settingsBox.containsKey(AppConstants.isBiometricEnabled)) {
      await _settingsBox.put(AppConstants.isBiometricEnabled, false);
    }
  }

  // Note operations
  
  /// Get all notes
  List<NoteModel> getNotes() {
    return _notesBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
  
  /// Get a single note by ID
  NoteModel? getNote(String id) {
    return _notesBox.get(id);
  }
  
  /// Save or update a note
  Future<void> saveNote(NoteModel note) async {
    await _notesBox.put(note.id, note);
  }
  
  /// Delete a note by ID
  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }
  
  /// Delete multiple notes by IDs
  Future<void> deleteNotes(List<String> ids) async {
    await _notesBox.deleteAll(ids);
  }
  
  /// Toggle pin status of a note
  Future<void> togglePinStatus(String id) async {
    final note = _notesBox.get(id);
    if (note != null) {
      note.isPinned = !note.isPinned;
      await saveNote(note);
    }
  }
  
  /// Toggle archive status of a note
  Future<void> toggleArchiveStatus(String id) async {
    final note = _notesBox.get(id);
    if (note != null) {
      note.isArchived = !note.isArchived;
      await saveNote(note);
    }
  }
  
  /// Toggle lock status of a note
  Future<void> toggleLockStatus(String id) async {
    final note = _notesBox.get(id);
    if (note != null) {
      note.isLocked = !note.isLocked;
      await saveNote(note);
    }
  }
  
  // Search operations
  
  /// Search notes by query
  List<NoteModel> searchNotes(String query) {
    if (query.isEmpty) return getNotes();
    
    final lowerQuery = query.toLowerCase();
    return _notesBox.values.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.content.toLowerCase().contains(lowerQuery) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
  
  /// Get all tags
  Set<String> getAllTags() {
    final tags = <String>{};
    for (final note in _notesBox.values) {
      tags.addAll(note.tags);
    }
    return tags;
  }
  
  /// Get notes by tag
  List<NoteModel> getNotesByTag(String tag) {
    return _notesBox.values
        .where((note) => note.tags.any((t) => t == tag))
        .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
  
  // Settings operations
  
  /// Get theme mode
  String getThemeMode() {
    return _settingsBox.get(AppConstants.themeMode, defaultValue: 'system');
  }
  
  /// Set theme mode
  Future<void> setThemeMode(String mode) async {
    await _settingsBox.put(AppConstants.themeMode, mode);
  }
  
  /// Check if biometric auth is enabled
  bool isBiometricEnabled() {
    return _settingsBox.get(AppConstants.isBiometricEnabled, defaultValue: false);
  }
  
  /// Set biometric auth status
  Future<void> setBiometricEnabled(bool enabled) async {
    await _settingsBox.put(AppConstants.isBiometricEnabled, enabled);
  }
  
  // Cleanup
  
  /// Close all boxes
  Future<void> close() async {
    await _notesBox.close();
    await _settingsBox.close();
  }
  
  /// Clear all data (for testing)
  Future<void> clearAll() async {
    await _notesBox.clear();
    await _settingsBox.clear();
  }
}
