import 'package:flutter_test/flutter_test.dart';
import 'package:unidev_note_app/data/note_store.dart';
import 'package:unidev_note_app/models/note.dart';
import 'package:unidev_note_app/notes_controller.dart';
import 'package:unidev_note_app/reminders/reminders.dart';

/// A controller with a fake clock that moves one minute per call, and predictable ids.
({NotesController controller, MemoryNoteStore store}) _setUp({
  List<Note> notes = const [],
  Reminders reminders = const NoReminders(),
}) {
  final store = MemoryNoteStore(notes: notes);
  var time = DateTime(2026, 10, 29, 9);
  var id = 0;
  final controller = NotesController(
    store,
    clock: () => time = time.add(const Duration(minutes: 1)),
    idGenerator: () => 'id${++id}',
    reminders: reminders,
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

  group('reminders', () {
    // The fake clock starts at 2026-10-29 09:00 and moves one minute per call.
    final now = DateTime(2026, 10, 29, 12);

    Future<NotesController> withDates() async {
      final (:controller, store: _) = _setUp();
      await controller.create(title: 'Dün', content: '', category: 'Genel', dueAt: DateTime(2026, 10, 28, 18));
      await controller.create(title: 'Bugün', content: '', category: 'İş', dueAt: DateTime(2026, 10, 29, 15));
      await controller.create(title: 'Yarın', content: '', category: 'Okul', dueAt: DateTime(2026, 10, 30, 9));
      await controller.create(title: 'Gelecek ay', content: '', category: 'Okul', dueAt: DateTime(2026, 11, 20, 9));
      await controller.create(title: 'Tarihsiz', content: '', category: 'Genel');
      return controller;
    }

    test('overdue, upcoming and per-day lists', () async {
      final controller = await withDates();
      expect(controller.overdue(now: now).map((n) => n.title), ['Dün']);
      expect(controller.upcoming(now: now).map((n) => n.title), ['Bugün', 'Yarın', 'Gelecek ay']);
      expect(controller.notesOn(DateTime(2026, 10, 30)).map((n) => n.title), ['Yarın']);
      expect(controller.attentionCount(now: now), 2); // overdue + later today
    });

    test('ticking a note off removes it from the waiting lists', () async {
      final controller = await withDates();
      final overdue = controller.overdue(now: now).single;
      final done = await controller.toggleDone(overdue);
      expect(done.done, isTrue);
      expect(controller.overdue(now: now), isEmpty);
      expect(controller.completed().map((n) => n.title), ['Dün']);
      expect((await controller.toggleDone(done)).done, isFalse);
    });

    test('update keeps the reminder unless a new one is given; moving it un-ticks the note', () async {
      final (:controller, store: _) = _setUp();
      final due = DateTime(2026, 11, 1, 10);
      var note = await controller.create(title: 'Sınav', content: '', category: 'Okul', dueAt: due);
      note = await controller.toggleDone(note);

      note = await controller.update(note, title: 'Sınav!', content: '', category: 'Okul');
      expect(note.dueAt, due);
      expect(note.done, isTrue);

      note = await controller.update(note, title: 'Sınav!', content: '', category: 'Okul', dueAt: DateTime(2026, 11, 2, 10));
      expect(note.done, isFalse);

      note = await controller.update(note, title: 'Sınav!', content: '', category: 'Okul', dueAt: null);
      expect(note.dueAt, isNull);
    });

    test('reminders are scheduled and cancelled as notes change', () async {
      final reminders = _FakeReminders();
      final (:controller, store: _) = _setUp(reminders: reminders);
      final future = DateTime(2030, 1, 1, 9);

      final note = await controller.create(title: 'A', content: '', category: 'Genel', dueAt: future);
      expect(reminders.scheduled, {note.id: future});

      final done = await controller.toggleDone(note);
      expect(reminders.scheduled, isEmpty);

      await controller.toggleDone(done);
      expect(reminders.scheduled, {note.id: future});

      await controller.delete(note);
      expect(reminders.scheduled, isEmpty);

      await controller.restore(note);
      expect(reminders.scheduled.keys, [note.id]);
    });
  });

  test('notification ids are stable and positive', () {
    expect(notificationIdFor('abc'), notificationIdFor('abc'));
    expect(notificationIdFor('abc'), isNot(notificationIdFor('abd')));
    expect(notificationIdFor('m2x9k1q-1h3j9z'), greaterThanOrEqualTo(0));
  });
}

/// Records what would be scheduled, using the same rule as the real implementation.
class _FakeReminders implements Reminders {
  final scheduled = <String, DateTime>{};

  @override
  bool get isSupported => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> sync(Note note, {required DateTime now}) async {
    if (shouldNotify(note, now)) {
      scheduled[note.id] = note.dueAt!;
    } else {
      scheduled.remove(note.id);
    }
  }

  @override
  Future<void> cancel(String noteId) async => scheduled.remove(noteId);
}
