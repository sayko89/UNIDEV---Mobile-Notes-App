import '../models/note.dart';

/// Where notes and categories are kept.
///
/// The app uses [HiveNoteStore] (on-device storage). Tests and the web demo use
/// [MemoryNoteStore], so the UI can be exercised without touching the disk.
abstract interface class NoteStore {
  List<Note> loadNotes();
  List<String> loadCategories();
  Future<void> putNote(Note note);
  Future<void> deleteNote(String id);
  Future<void> putCategories(List<String> categories);
}

class MemoryNoteStore implements NoteStore {
  MemoryNoteStore({Iterable<Note> notes = const [], Iterable<String> categories = const []})
    : _notes = {for (final note in notes) note.id: note},
      _categories = [...categories];

  final Map<String, Note> _notes;
  List<String> _categories;

  @override
  List<Note> loadNotes() => _notes.values.toList();

  @override
  List<String> loadCategories() => List.of(_categories);

  @override
  Future<void> putNote(Note note) async => _notes[note.id] = note;

  @override
  Future<void> deleteNote(String id) async => _notes.remove(id);

  @override
  Future<void> putCategories(List<String> categories) async => _categories = List.of(categories);
}
