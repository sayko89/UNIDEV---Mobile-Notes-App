import 'package:flutter/foundation.dart';

import 'data/note_store.dart';
import 'models/note.dart';
import 'reminders/reminders.dart';
import 'util/ids.dart';
import 'util/text.dart';

/// Passed as `dueAt` to [NotesController.update] to keep a note's reminder unchanged.
const keepDue = _KeepDue();

class _KeepDue {
  const _KeepDue();
}

/// App state: the notes, the categories, and the current filter and search.
///
/// Widgets listen to it (it is a [ChangeNotifier]); every change is written to the [NoteStore]
/// and the note's phone reminder is kept in step through [Reminders].
class NotesController extends ChangeNotifier {
  NotesController(
    this._store, {
    DateTime Function()? clock,
    String Function()? idGenerator,
    Reminders reminders = const NoReminders(),
  }) : _clock = clock ?? DateTime.now,
       _newId = idGenerator ?? generateId,
       _reminders = reminders {
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
  final Reminders _reminders;

  late List<Note> _notes;
  late List<String> _categories;
  String? _filter;
  String _query = '';

  List<String> get categories => List.unmodifiable(_categories);

  /// Whether this device can show reminder notifications.
  bool get remindersSupported => _reminders.isSupported;

  /// The selected category, or null for all notes.
  String? get filter => _filter;
  String get query => _query;
  bool get isFiltering => _filter != null || _query.trim().isNotEmpty;

  /// All notes, most recently changed first.
  List<Note> get notes => _sorted(_notes);

  /// Notes matching the category filter and the search text.
  List<Note> get visibleNotes {
    final words = foldForSearch(_query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return _sorted(
      _notes.where((note) {
        if (_filter != null && note.category != _filter) return false;
        if (words.isEmpty) return true;
        final haystack = foldForSearch('${note.title}\n${note.content}\n${note.category}');
        return words.every(haystack.contains);
      }),
    );
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

  // --- Reminders and dates ---------------------------------------------------------------

  /// Not-done notes whose reminder has passed, oldest first.
  List<Note> overdue({DateTime? now}) {
    final t = now ?? _clock();
    return _byDue(_notes.where((n) => n.isOverdue(t)));
  }

  /// Not-done notes with a reminder from now on, soonest first.
  List<Note> upcoming({DateTime? now}) {
    final t = now ?? _clock();
    return _byDue(_notes.where((n) => n.dueAt != null && !n.done && !n.dueAt!.isBefore(t)));
  }

  /// Notes with a reminder that are already ticked off, most recent first.
  List<Note> completed() => _byDue(_notes.where((n) => n.dueAt != null && n.done)).reversed.toList();

  /// Notes whose reminder falls on [day], in order of time.
  List<Note> notesOn(DateTime day) => _byDue(_notes.where((n) => n.dueAt != null && isSameDay(n.dueAt!, day)));

  /// Overdue notes plus those due later today — the number shown on the "Yaklaşanlar" tab.
  int attentionCount({DateTime? now}) {
    final t = now ?? _clock();
    return _notes.where((n) => n.dueAt != null && !n.done && (n.dueAt!.isBefore(t) || isSameDay(n.dueAt!, t))).length;
  }

  Future<Note> toggleDone(Note note) async {
    final updated = note.copyWith(done: !note.done);
    _replace(updated);
    notifyListeners();
    await _store.putNote(updated);
    await _reminders.sync(updated, now: _clock());
    return updated;
  }

  Future<bool> requestReminderPermission() => _reminders.requestPermission();

  // --- Filters ------------------------------------------------------------------------------

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

  // --- Changes ------------------------------------------------------------------------------

  Future<Note> create({
    required String title,
    required String content,
    required String category,
    DateTime? dueAt,
  }) async {
    final now = _clock();
    final note = Note(
      id: _newId(),
      title: title.trim(),
      content: content.trim(),
      category: category,
      createdAt: now,
      updatedAt: now,
      dueAt: dueAt,
    );
    _notes.add(note);
    notifyListeners();
    await _store.putNote(note);
    await _reminders.sync(note, now: now);
    return note;
  }

  /// Saves changes. Nothing is written — and the "edited" time doesn't move — if nothing changed.
  /// Pass a date (or null to remove the reminder) as [dueAt]; leave it out to keep the current one.
  /// Moving the reminder to another time un-ticks the note.
  Future<Note> update(
    Note note, {
    required String title,
    required String content,
    required String category,
    Object? dueAt = keepDue,
  }) async {
    final newTitle = title.trim();
    final newContent = content.trim();
    final newDue = identical(dueAt, keepDue) ? note.dueAt : dueAt as DateTime?;
    if (newTitle == note.title && newContent == note.content && category == note.category && newDue == note.dueAt) {
      return note;
    }
    final dueChanged = newDue != note.dueAt;
    final updated = note.copyWith(
      title: newTitle,
      content: newContent,
      category: category,
      updatedAt: _clock(),
      setDue: true,
      dueAt: newDue,
      done: dueChanged ? false : note.done,
    );
    _replace(updated);
    notifyListeners();
    await _store.putNote(updated);
    if (dueChanged) await _reminders.sync(updated, now: _clock());
    return updated;
  }

  Future<void> delete(Note note) async {
    _notes.removeWhere((n) => n.id == note.id);
    notifyListeners();
    await _store.deleteNote(note.id);
    await _reminders.cancel(note.id);
  }

  /// Puts a deleted note back (used by "Geri al" / undo).
  Future<void> restore(Note note) async {
    if (noteById(note.id) != null) return;
    _notes.add(note);
    notifyListeners();
    await _store.putNote(note);
    await _reminders.sync(note, now: _clock());
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

  void _replace(Note updated) {
    final index = _notes.indexWhere((n) => n.id == updated.id);
    if (index == -1) {
      _notes.add(updated);
    } else {
      _notes[index] = updated;
    }
  }

  String? _findCategory(String name) {
    final folded = foldForSearch(name);
    for (final category in _categories) {
      if (foldForSearch(category) == folded) return category;
    }
    return null;
  }

  static List<Note> _sorted(Iterable<Note> notes) {
    return notes.toList()..sort((a, b) {
      final byTime = b.updatedAt.compareTo(a.updatedAt);
      return byTime != 0 ? byTime : b.id.compareTo(a.id);
    });
  }

  static List<Note> _byDue(Iterable<Note> notes) {
    return notes.toList()..sort((a, b) {
      final byDue = a.dueAt!.compareTo(b.dueAt!);
      return byDue != 0 ? byDue : a.id.compareTo(b.id);
    });
  }
}
