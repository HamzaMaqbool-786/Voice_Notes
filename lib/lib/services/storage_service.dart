import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class StorageService {
  static const String _notesKey = 'voice_notes';

  /// Load all notes from SharedPreferences
  Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> noteStrings = prefs.getStringList(_notesKey) ?? [];
    return noteStrings.map((s) => Note.fromJsonString(s)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Save all notes to SharedPreferences
  Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> noteStrings = notes.map((n) => n.toJsonString()).toList();
    await prefs.setStringList(_notesKey, noteStrings);
  }

  /// Add a single note
  Future<void> addNote(Note note) async {
    final notes = await loadNotes();
    notes.add(note);
    await saveNotes(notes);
  }

  /// Update a single note
  Future<void> updateNote(Note updatedNote) async {
    final notes = await loadNotes();
    final index = notes.indexWhere((n) => n.id == updatedNote.id);
    if (index != -1) {
      notes[index] = updatedNote;
      await saveNotes(notes);
    }
  }

  /// Delete a note by ID
  Future<void> deleteNote(String id) async {
    final notes = await loadNotes();
    notes.removeWhere((n) => n.id == id);
    await saveNotes(notes);
  }

  /// Clear all notes
  Future<void> clearAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notesKey);
  }
}
