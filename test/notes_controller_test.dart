import 'package:flutter_test/flutter_test.dart';
import 'package:unidev_note_app/data/note_store.dart';
import 'package:unidev_note_app/models/note.dart';
import 'package:unidev_note_app/notes_controller.dart';

/// A controller with a fake clock that moves one minute per call, and predictable ids.
({NotesController controller, MemoryNoteStore store}) _setUp({List<Note> notes = const []}) {
  final store = MemoryNoteStore(notes: notes);
  var time = DateTime(2026, 10, 29, 9);
  var id = 0;
  final controller = NotesController(
    store,
    clock: () => time = time.add(const Duration(minutes: 1)),
    idGenerator: () => 'id${++id}',
  );
  return (controller: controller, store: store);
}

void main() {
  test('starts with the default categories', () {
    final (:controller, store: _) = _setUp();
    expect(controller.categories, ['Genel', 'İş', 'Kişisel']);
    expect(controller.notes, isEmpty);
  });

  test('create trims the text, stores the note and lists newest first', () async {
    final (:controller, :store) = _setUp();
    await controller.create(title: '  İlk  ', content: '\nmerhaba\n', category: 'Genel');
    await controller.create(title: 'İkinci', content: '', category: 'İş');

    expect(controller.notes.map((n) => n.title), ['İkinci', 'İlk']);
    expect(controller.notes.last.content, 'merhaba');
    expect(store.loadNotes(), hasLength(2));
  });

  test('update changes updatedAt only when something changed', () async {
    final (:controller, :store) = _setUp();
    final note = await controller.create(title: 'A', content: 'B', category: 'Genel');

    final same = await controller.update(note, title: 'A ', content: 'B', category: 'Genel');
    expect(identical(same, note), isTrue);

    final changed = await controller.update(note, title: 'A2', content: 'B', category: 'İş');
    expect(changed.updatedAt.isAfter(note.updatedAt), isTrue);
    expect(changed.createdAt, note.createdAt);
    expect(controller.noteById(note.id)!.title, 'A2');
    expect(store.loadNotes().single.category, 'İş');
  });

  test('an edited note moves to the top', () async {
    final (:controller, store: _) = _setUp();
    final first = await controller.create(title: 'Eski', content: '', category: 'Genel');
    await controller.create(title: 'Yeni', content: '', category: 'Genel');
    await controller.update(first, title: 'Eski (düzenlendi)', content: '', category: 'Genel');
    expect(controller.notes.first.title, 'Eski (düzenlendi)');
  });

  test('delete and restore (undo)', () async {
    final (:controller, :store) = _setUp();
    final note = await controller.create(title: 'Sil beni', content: '', category: 'Genel');

    await controller.delete(note);
    expect(controller.notes, isEmpty);
    expect(store.loadNotes(), isEmpty);

    await controller.restore(note);
    await controller.restore(note); // restoring twice does not duplicate
    expect(controller.notes, [note]);
    expect(store.loadNotes(), [note]);
  });

  group('filter and search', () {
    late NotesController controller;

    setUp(() async {
      controller = _setUp().controller;
      await controller.create(title: 'Market listesi', content: 'süt, yumurta', category: 'Kişisel');
      await controller.create(title: 'Toplantı', content: 'İŞ PLANI ve bütçe', category: 'İş');
      await controller.create(title: 'Fikir', content: 'yeni uygulama', category: 'Genel');
    });

    test('by category', () {
      controller.setFilter('İş');
      expect(controller.visibleNotes.map((n) => n.title), ['Toplantı']);
      expect(controller.count('Kişisel'), 1);
      expect(controller.count(), 3);
    });

    test('search is case-insensitive, Turkish-aware and needs every word', () {
      controller.setQuery('iş planı');
      expect(controller.visibleNotes.map((n) => n.title), ['Toplantı']);
      controller.setQuery('SÜT yumurta');
      expect(controller.visibleNotes.map((n) => n.title), ['Market listesi']);
      controller.setQuery('süt bütçe');
      expect(controller.visibleNotes, isEmpty);
    });

    test('search also matches the category name', () {
      controller.setQuery('kişisel');
      expect(controller.visibleNotes.map((n) => n.title), ['Market listesi']);
    });

    test('filter and search combine, and can be cleared', () {
      controller
        ..setFilter('Genel')
        ..setQuery('market');
      expect(controller.visibleNotes, isEmpty);
      expect(controller.isFiltering, isTrue);
      controller.clearFilters();
      expect(controller.visibleNotes, hasLength(3));
      expect(controller.isFiltering, isFalse);
    });
  });

  group('categories', () {
    test('adding a category saves it; duplicates are matched case-insensitively', () async {
      final (:controller, :store) = _setUp();
      expect(await controller.addCategory('  Okul '), 'Okul');
      expect(await controller.addCategory('OKUL'), 'Okul');
      expect(await controller.addCategory('iş'), 'İş');
      expect(controller.categories, ['Genel', 'İş', 'Kişisel', 'Okul']);
      expect(store.loadCategories(), controller.categories);
    });

    test('an empty name is rejected', () {
      final (:controller, store: _) = _setUp();
      expect(() => controller.addCategory('   '), throwsArgumentError);
    });

    test('categories used by stored notes are added to the list', () {
      final old = Note(
        id: 'x',
        title: 'Eski not',
        content: '',
        category: 'Arşiv',
        createdAt: DateTime(2025, 6, 24),
        updatedAt: DateTime(2025, 6, 24),
      );
      final (:controller, store: _) = _setUp(notes: [old]);
      expect(controller.categories, contains('Arşiv'));
    });
  });

  test('listeners are notified of changes', () async {
    final (:controller, store: _) = _setUp();
    var calls = 0;
    controller.addListener(() => calls++);
    final note = await controller.create(title: 'a', content: '', category: 'Genel');
    controller.setFilter('İş');
    controller.setFilter('İş'); // no change, no notification
    await controller.delete(note);
    expect(calls, 3);
  });
}
