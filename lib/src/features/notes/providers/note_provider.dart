import 'package:flutter/material.dart';
import 'package:calcnote/src/features/notes/models/note_model.dart';
import 'package:calcnote/src/features/notes/services/note_database_service.dart';

class NoteProvider with ChangeNotifier {
  final NoteDatabaseService databaseService;
  
  // State
  List<NoteModel> _notes = [];
  bool _isLoading = false;
  String? _error;
  String? _searchQuery;
  
  // Getters
  List<NoteModel> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchQuery => _searchQuery;
  
  // Get filtered and sorted notes
  List<NoteModel> get filteredNotes {
    if (_searchQuery?.isNotEmpty ?? false) {
      return _notes
          .where((note) =>
              note.title.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
              note.content.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
              note.tags.any((tag) =>
                  tag.toLowerCase().contains(_searchQuery!.toLowerCase())))
          .toList();
    }
    return _notes;
  }
  
  // Get pinned notes
  List<NoteModel> get pinnedNotes =>
      _notes.where((note) => note.isPinned).toList();
      
  // Get archived notes
  List<NoteModel> get archivedNotes =>
      _notes.where((note) => note.isArchived).toList();
  
  // Constructor
  NoteProvider({required this.databaseService});
  
  // Load notes from database
  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _notes = databaseService.getNotes();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load notes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create a new note
  Future<void> createNote(NoteModel note) async {
    try {
      await databaseService.saveNote(note);
      await loadNotes(); // Refresh the notes list
    } catch (e) {
      _error = 'Failed to create note: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  // Update an existing note
  Future<void> updateNote(NoteModel note) async {
    try {
      await databaseService.saveNote(note);
      await loadNotes(); // Refresh the notes list
    } catch (e) {
      _error = 'Failed to update note: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  // Delete a note
  Future<void> deleteNote(String id) async {
    try {
      await databaseService.deleteNote(id);
      await loadNotes(); // Refresh the notes list
    } catch (e) {
      _error = 'Failed to delete note: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  // Toggle pin status of a note
  Future<void> togglePinStatus(String id) async {
    try {
      await databaseService.togglePinStatus(id);
      await loadNotes(); // Refresh the notes list
    } catch (e) {
      _error = 'Failed to toggle pin status: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  // Toggle archive status of a note
  Future<void> toggleArchiveStatus(String id) async {
    try {
      await databaseService.toggleArchiveStatus(id);
      await loadNotes(); // Refresh the notes list
    } catch (e) {
      _error = 'Failed to toggle archive status: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  // Toggle lock status of a note
  Future<void> toggleLockStatus(String id) async {
    try {
      await databaseService.toggleLockStatus(id);
      await loadNotes(); // Refresh the notes list
    } catch (e) {
      _error = 'Failed to toggle lock status: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  // Search notes
  void searchNotes(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  // Clear search
  void clearSearch() {
    _searchQuery = null;
    notifyListeners();
  }
  
  // Get a note by ID
  NoteModel? getNoteById(String id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get all tags
  Set<String> getAllTags() {
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags;
  }
  
  // Get notes by tag
  List<NoteModel> getNotesByTag(String tag) {
    return _notes
        .where((note) => note.tags.any((t) => t == tag))
        .toList();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
