import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/storage_service.dart';

class NotesProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final Uuid _uuid = const Uuid();

  List<Note> _notes = [];
  String _searchQuery = '';
  bool _isLoading = false;

  List<Note> get notes => _filteredNotes;
  List<Note> get allNotes => _notes;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) return List.from(_notes);

    final query = _searchQuery.toLowerCase();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          _formatDate(note.createdAt).toLowerCase().contains(query);
    }).toList();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  /// Load notes from storage
  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    _notes = await _storageService.loadNotes();

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new note
  Future<Note> addNote({
    required String content,
    Duration? recordingDuration,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: Note.generateTitle(content),
      content: content,
      createdAt: now,
      updatedAt: now,
      recordingDuration: recordingDuration,
    );

    _notes.insert(0, note);
    await _storageService.saveNotes(_notes);
    notifyListeners();
    return note;
  }

  /// Update an existing note
  Future<void> updateNote(String id, {String? title, String? content}) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final note = _notes[index];
    final updatedNote = note.copyWith(
      title: title ?? (content != null ? Note.generateTitle(content) : null),
      content: content,
      updatedAt: DateTime.now(),
    );

    // If title was explicitly provided, use it
    if (title != null) {
      _notes[index] = note.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      );
    } else {
      _notes[index] = updatedNote;
    }

    // Re-sort
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  /// Update search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
}
