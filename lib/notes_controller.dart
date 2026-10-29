import 'package:flutter/foundation.dart';

import 'data/note_store.dart';
import 'models/note.dart';
import 'util/ids.dart';
import 'util/text.dart';

/// App state: the notes, the categories, and the current filter and search.
///
/// Widgets listen to it (it is a [ChangeNotifier]); every change is written to the [NoteStore].
class NotesController extends ChangeNotifier {
  NotesController(this._store, {DateTime Function()? clock, String Function()? idGenerator})
      : _clock = clock ?? DateTime.now,
        _newId = idGenerator ?? generateId {
    _notes = _store.loadNotes();
    final saved = _store.loadCategories();
    _categories = saved.isEmpty ? [...defaultCategories] : [...saved];
    // Notes can use a category that isn't in the list (e.g. notes from version 1).
    for (final note in _notes) {
      if (_findCategory(note.category) == null) _categories.add(note.category);
    }
  }

  static const defaultCategories = ['Genel', 'İş', 'Kişisel'];

  final NoteStore _store;
  final DateTime Function() _clock;
  final String Function() _newId;

  late List<Note> _notes;
  late List<String> _categories;
  String? _filter;
  String _query = '';

  List<String> get categories => List.unmodifiable(_categories);

  /// The selected category, or null for all notes.
  String? get filter => _filter;
  String get query => _query;
  bool get isFiltering => _filter != null || _query.trim().isNotEmpty;

  /// All notes, most recently changed first.
  List<Note> get notes => _sorted(_notes);

  /// Notes matching the category filter and the search text.
  List<Note> get visibleNotes {
    final words = foldForSearch(_query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return _sorted(_notes.where((note) {
      if (_filter != null && note.category != _filter) return false;
      if (words.isEmpty) return true;
      final haystack = foldForSearch('${note.title}\n${note.content}\n${note.category}');
      return words.every(haystack.contains);
    }));
  }

  /// Number of notes in [category], or of all notes when it is null.
  int count([String? category]) =>
      category == null ? _notes.length : _notes.where((n) => n.category == category).length;

  Note? noteById(String id) {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  void setFilter(String? category) {
    if (_filter == category) return;
    _filter = category;
    notifyListeners();
  }

  void setQuery(String query) {
    if (_query == query) return;
    _query = query;
    notifyListeners();
  }

  void clearFilters() {
    _filter = null;
    _query = '';
    notifyListeners();
  }

  Future<Note> create({required String title, required String content, required String category}) async {
    final now = _clock();
    final note = Note(
      id: _newId(),
      title: title.trim(),
      content: content.trim(),
      category: category,
      createdAt: now,
      updatedAt: now,
    );
    _notes.add(note);
    notifyListeners();
    await _store.putNote(note);
    return note;
  }

  /// Saves changes. Nothing is written — and the "edited" time doesn't move — if nothing changed.
  Future<Note> update(Note note, {required String title, required String content, required String category}) async {
    final newTitle = title.trim();
    final newContent = content.trim();
    if (newTitle == note.title && newContent == note.content && category == note.category) return note;
    final updated = note.copyWith(title: newTitle, content: newContent, category: category, updatedAt: _clock());
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      _notes.add(updated);
    } else {
      _notes[index] = updated;
    }
    notifyListeners();
    await _store.putNote(updated);
    return updated;
  }

  Future<void> delete(Note note) async {
    _notes.removeWhere((n) => n.id == note.id);
    notifyListeners();
    await _store.deleteNote(note.id);
  }

  /// Puts a deleted note back (used by "Geri al" / undo).
  Future<void> restore(Note note) async {
    if (noteById(note.id) != null) return;
    _notes.add(note);
    notifyListeners();
    await _store.putNote(note);
  }

  /// Adds a category and returns its name. If one already exists with the same name
  /// (ignoring case), that one is returned instead of creating a duplicate.
  Future<String> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', 'Category name cannot be empty');
    final existing = _findCategory(trimmed);
    if (existing != null) return existing;
    _categories.add(trimmed);
    notifyListeners();
    await _store.putCategories(List.of(_categories));
    return trimmed;
  }

  String? _findCategory(String name) {
    final folded = foldForSearch(name);
    for (final category in _categories) {
      if (foldForSearch(category) == folded) return category;
    }
    return null;
  }

  static List<Note> _sorted(Iterable<Note> notes) {
    return notes.toList()
      ..sort((a, b) {
        final byTime = b.updatedAt.compareTo(a.updatedAt);
        return byTime != 0 ? byTime : b.id.compareTo(a.id);
      });
  }
}
