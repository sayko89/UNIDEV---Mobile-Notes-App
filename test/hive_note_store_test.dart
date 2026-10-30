import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:unidev_note_app/data/hive_note_store.dart';
import 'package:unidev_note_app/models/note.dart';
import 'package:unidev_note_app/notes_controller.dart';

/// The note class and binary format of version 1 (June 2025), copied from the original
/// main.dart, to check that notes saved by that version still open.
class LegacyNote {
  LegacyNote(this.title, this.content, this.category);
  final String title;
  final String content;
  final String category;
}

class LegacyNoteAdapter extends TypeAdapter<LegacyNote> {
  @override
  final int typeId = 0;

  @override
  LegacyNote read(BinaryReader reader) => LegacyNote(reader.readString(), reader.readString(), reader.readString());

  @override
  void write(BinaryWriter writer, LegacyNote obj) {
    writer.writeString(obj.title);
    writer.writeString(obj.content);
    writer.writeString(obj.category);
  }
}

/// The version 2 format (October 2026, before reminders), to check it is still read.
class V2NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeString('\u0000note:v2')
      ..writeString(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.content)
      ..writeString(obj.category)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('hive_note_store_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test('notes and categories survive closing and reopening', () async {
    Hive.registerAdapter(NoteAdapter(), override: true);
    var store = await HiveNoteStore.open();
    final note = Note(
      id: 'abc',
      title: 'Başlık',
      content: 'Çok satırlı\niçerik — ğüşöçı',
      category: 'İş',
      createdAt: DateTime(2026, 10, 29, 9, 15),
      updatedAt: DateTime(2026, 10, 29, 10, 45),
      dueAt: DateTime(2026, 11, 2, 14, 30),
      done: true,
    );
    final undated = Note(
      id: 'def',
      title: 'Tarihsiz',
      content: '',
      category: 'Genel',
      createdAt: DateTime(2026, 10, 29),
      updatedAt: DateTime(2026, 10, 29),
    );
    await store.putNote(note);
    await store.putNote(undated);
    await store.putCategories(['Genel', 'İş', 'Okul']);
    await Hive.close();

    store = await HiveNoteStore.open();
    expect(store.loadNotes()..sort((a, b) => a.id.compareTo(b.id)), [note, undated]);
    expect(store.loadCategories(), ['Genel', 'İş', 'Okul']);

    await store.deleteNote('abc');
    expect(store.loadNotes(), [undated]);
  });

  test('notes saved by version 1 are read and given ids', () async {
    // Write two notes exactly as the original app did: box.add with the v1 adapter.
    Hive.registerAdapter(LegacyNoteAdapter(), override: true);
    final legacyBox = await Hive.openBox<LegacyNote>(HiveNoteStore.notesBoxName);
    await legacyBox.add(LegacyNote('Alışveriş', 'Ekmek', 'Kişisel'));
    await legacyBox.add(LegacyNote('Proje', 'Rapor yaz', 'İş'));
    await Hive.close();

    Hive.registerAdapter(NoteAdapter(), override: true);
    var id = 0;
    final store = await HiveNoteStore.open(newId: () => 'migrated-${++id}');

    final notes = store.loadNotes()..sort((a, b) => a.title.compareTo(b.title));
    expect(notes.map((n) => (n.id, n.title, n.content, n.category)), [
      ('migrated-1', 'Alışveriş', 'Ekmek', 'Kişisel'),
      ('migrated-2', 'Proje', 'Rapor yaz', 'İş'),
    ]);

    // The controller sees them like any other note, and edits are saved in the new format.
    final controller = NotesController(store);
    final edited = await controller.update(notes.first, title: 'Alışveriş', content: 'Ekmek, süt', category: 'Kişisel');
    await Hive.close();
    final reopened = await HiveNoteStore.open();
    expect(reopened.loadNotes().firstWhere((n) => n.id == edited.id).content, 'Ekmek, süt');
  });

  test('notes saved by version 2 are read, without a reminder', () async {
    Hive.registerAdapter(V2NoteAdapter(), override: true);
    final box = await Hive.openBox<Note>(HiveNoteStore.notesBoxName);
    final v2 = Note(
      id: 'v2',
      title: 'Ekim notu',
      content: 'içerik',
      category: 'İş',
      createdAt: DateTime(2026, 10, 29, 9),
      updatedAt: DateTime(2026, 10, 29, 10),
    );
    await box.put('v2', v2);
    await Hive.close();

    Hive.registerAdapter(NoteAdapter(), override: true);
    final store = await HiveNoteStore.open();
    expect(store.loadNotes(), [v2]);
    expect(store.loadNotes().single.dueAt, isNull);
    expect(store.loadNotes().single.done, isFalse);
  });
}
