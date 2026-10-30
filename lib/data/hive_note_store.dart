import 'package:hive_ce/hive_ce.dart';

import '../models/note.dart';
import '../util/ids.dart';
import 'note_store.dart';

/// Stores notes on the device with Hive (IndexedDB on the web).
///
/// Uses the same box name and type id as version 1 of the app, so notes saved by the
/// original version are still found — see [NoteAdapter] and [_migrateLegacyKeys].
class HiveNoteStore implements NoteStore {
  HiveNoteStore._(this._notes, this._settings);

  static const notesBoxName = 'notes';
  static const settingsBoxName = 'settings';
  static const _categoriesKey = 'categories';

  final Box<Note> _notes;
  final Box<dynamic> _settings;

  /// Opens the boxes. Call `Hive.initFlutter()` (or `Hive.init(path)` in tests) first.
  static Future<HiveNoteStore> open({String Function() newId = generateId}) async {
    if (!Hive.isAdapterRegistered(NoteAdapter.id)) {
      Hive.registerAdapter(NoteAdapter());
    }
    final notes = await Hive.openBox<Note>(notesBoxName);
    final settings = await Hive.openBox<dynamic>(settingsBoxName);
    await _migrateLegacyKeys(notes, newId);
    return HiveNoteStore._(notes, settings);
  }

  /// Version 1 saved notes with `box.add`, which uses auto-increment integer keys and
  /// stored no id. Give each such note an id and re-save it under that id.
  static Future<void> _migrateLegacyKeys(Box<Note> box, String Function() newId) async {
    final legacyKeys = box.keys.whereType<int>().toList();
    for (final key in legacyKeys) {
      final note = box.get(key);
      if (note == null) continue;
      final id = newId();
      await box.put(id, note.copyWith(id: id));
      await box.delete(key);
    }
  }

  @override
  List<Note> loadNotes() => _notes.values.toList();

  @override
  List<String> loadCategories() {
    final saved = _settings.get(_categoriesKey);
    return saved is List ? saved.cast<String>() : const [];
  }

  @override
  Future<void> putNote(Note note) => _notes.put(note.id, note);

  @override
  Future<void> deleteNote(String id) => _notes.delete(id);

  @override
  Future<void> putCategories(List<String> categories) => _settings.put(_categoriesKey, categories);
}

/// Binary format of a note in Hive.
///
/// - Version 1 (June 2025) wrote three strings: title, content, category.
/// - Version 2 starts with a marker string that a v1 title can't realistically be, followed by
///   id, title, content, category and the two timestamps.
/// - Version 3 (current) has its own marker and adds the reminder date and the "done" flag.
///
/// Reading the first string tells the formats apart, so older notes keep working without a
/// separate migration step.
class NoteAdapter extends TypeAdapter<Note> {
  static const id = 0; // same type id as version 1
  static const _v2Marker = '\u0000note:v2';
  static const _v3Marker = '\u0000note:v3';
  static const _noDue = -1;

  @override
  int get typeId => id;

  @override
  Note read(BinaryReader reader) {
    final first = reader.readString();
    if (first != _v2Marker && first != _v3Marker) {
      // Version 1 note: no id (added by HiveNoteStore) and no dates.
      final content = reader.readString();
      final category = reader.readString();
      final now = DateTime.now();
      return Note(id: '', title: first, content: content, category: category, createdAt: now, updatedAt: now);
    }
    final id = reader.readString();
    final title = reader.readString();
    final content = reader.readString();
    final category = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    DateTime? dueAt;
    var done = false;
    if (first == _v3Marker) {
      final due = reader.readInt();
      dueAt = due == _noDue ? null : DateTime.fromMillisecondsSinceEpoch(due);
      done = reader.readBool();
    }
    return Note(
      id: id,
      title: title,
      content: content,
      category: category,
      createdAt: createdAt,
      updatedAt: updatedAt,
      dueAt: dueAt,
      done: done,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeString(_v3Marker)
      ..writeString(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.content)
      ..writeString(obj.category)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch)
      ..writeInt(obj.dueAt?.millisecondsSinceEpoch ?? _noDue)
      ..writeBool(obj.done);
  }
}
