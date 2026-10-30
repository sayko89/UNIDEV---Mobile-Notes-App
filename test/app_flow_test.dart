import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unidev_note_app/app.dart';
import 'package:unidev_note_app/data/note_store.dart';
import 'package:unidev_note_app/models/note.dart';
import 'package:unidev_note_app/notes_controller.dart';

Note _note(String id, String title, String content, String category, int minutesAgo, {DateTime? dueAt}) {
  final time = DateTime.now().subtract(Duration(minutes: minutesAgo));
  return Note(
    id: id,
    title: title,
    content: content,
    category: category,
    createdAt: time,
    updatedAt: time,
    dueAt: dueAt,
  );
}

/// A tab in the bottom navigation bar.
Finder _tab(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

DateTime _dayFromToday(int days, int hour) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days, hour);
}

Future<NotesController> _pumpApp(WidgetTester tester, {List<Note> notes = const []}) async {
  final controller = NotesController(MemoryNoteStore(notes: notes));
  await tester.pumpWidget(NotesApp(controller: controller, themeMode: ThemeMode.light));
  await tester.pumpAndSettle();
  return controller;
}

/// Lets any snackbar time out, so no timers are left running when the test ends.
Future<void> _finishSnackBars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty list, then add a note in a chosen category', (tester) async {
    final controller = await _pumpApp(tester);
    expect(find.text('Henüz not yok'), findsOneWidget);

    await tester.tap(find.byTooltip('Yeni not'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni not'), findsOneWidget); // editor title

    await tester.enterText(find.byKey(const Key('title-field')), 'Market listesi');
    await tester.enterText(find.byKey(const Key('content-field')), 'Süt\nYumurta');
    await tester.tap(find.byKey(const Key('category-Kişisel')));
    await tester.tap(find.byKey(const Key('save-note')));
    await tester.pumpAndSettle();

    expect(find.text('Market listesi'), findsOneWidget);
    expect(find.text('Süt · Yumurta'), findsOneWidget);
    expect(controller.notes.single.category, 'Kişisel');
  });

  testWidgets('an empty note is not saved', (tester) async {
    final controller = await _pumpApp(tester);
    await tester.tap(find.byTooltip('Yeni not'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title-field')), '   ');
    await tester.tap(find.byKey(const Key('save-note')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Boş not kaydedilemez'), findsOneWidget);
    expect(controller.notes, isEmpty);
  });

  testWidgets('open a note, edit it, and see the change on the detail page', (tester) async {
    await _pumpApp(tester, notes: [_note('a', 'Toplantı', 'Gündem: bütçe', 'İş', 30)]);

    await tester.tap(find.text('Toplantı'));
    await tester.pumpAndSettle();
    expect(find.text('Gündem: bütçe'), findsOneWidget);
    expect(find.textContaining('Oluşturuldu'), findsOneWidget);

    await tester.tap(find.byTooltip('Düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('content-field')), 'Gündem: bütçe ve takvim');
    await tester.tap(find.byKey(const Key('save-note')));
    await tester.pumpAndSettle();

    expect(find.text('Gündem: bütçe ve takvim'), findsOneWidget); // back on the detail page
    expect(find.textContaining('Düzenlendi'), findsOneWidget);
  });

  testWidgets('long press → Sil removes the note, and Geri al brings it back', (tester) async {
    final controller = await _pumpApp(tester, notes: [_note('a', 'Silinecek not', '', 'Genel', 5)]);

    await tester.longPress(find.text('Silinecek not'));
    await tester.pumpAndSettle();
    expect(find.text('Düzenle'), findsOneWidget);
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();

    expect(controller.notes, isEmpty);
    expect(find.text('"Silinecek not" silindi'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    expect(find.text('Silinecek not'), findsOneWidget);
    expect(controller.notes, hasLength(1));
    await _finishSnackBars(tester);
  });

  testWidgets('delete from the detail page returns to the list with undo', (tester) async {
    final controller = await _pumpApp(tester, notes: [_note('a', 'Detaydan sil', 'x', 'Genel', 5)]);
    await tester.tap(find.text('Detaydan sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sil'));
    await tester.pumpAndSettle();

    expect(find.text('Notlarım'), findsOneWidget);
    expect(controller.notes, isEmpty);
    expect(find.text('Geri al'), findsOneWidget);
    await _finishSnackBars(tester);
  });

  testWidgets('category filter and search', (tester) async {
    await _pumpApp(
      tester,
      notes: [
        _note('a', 'Market', 'süt', 'Kişisel', 1),
        _note('b', 'Sprint planı', 'iş takibi', 'İş', 2),
        _note('c', 'Fikir', 'uygulama', 'Genel', 3),
      ],
    );

    await tester.tap(find.byKey(const Key('filter-İş')));
    await tester.pumpAndSettle();
    expect(find.text('Sprint planı'), findsOneWidget);
    expect(find.text('Market'), findsNothing);

    await tester.tap(find.byKey(const Key('filter-all')));
    await tester.enterText(find.byKey(const Key('search-field')), 'SÜT');
    await tester.pumpAndSettle();
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Fikir'), findsNothing);

    await tester.enterText(find.byKey(const Key('search-field')), 'olmayan kelime');
    await tester.pumpAndSettle();
    expect(find.text('Eşleşen not yok'), findsOneWidget);
    await tester.tap(find.text('Filtreleri temizle'));
    await tester.pumpAndSettle();
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Fikir'), findsOneWidget);
  });

  testWidgets('leaving the editor with unsaved changes asks first', (tester) async {
    final controller = await _pumpApp(tester);
    await tester.tap(find.byTooltip('Yeni not'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title-field')), 'Yarım kalan');
    await tester.pump();

    await tester.binding.handlePopRoute(); // Android back button / gesture
    await tester.pumpAndSettle();
    expect(find.text('Değişiklikler kaydedilmedi'), findsOneWidget);

    await tester.tap(find.text('Düzenlemeye dön'));
    await tester.pumpAndSettle();
    expect(find.text('Yarım kalan'), findsOneWidget); // still editing

    await tester.binding.handlePopRoute(); // Android back button / gesture
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydetmeden çık'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz not yok'), findsOneWidget);
    expect(controller.notes, isEmpty);
  });

  testWidgets('leaving the editor without changes does not ask', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Yeni not'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute(); // Android back button / gesture
    await tester.pumpAndSettle();
    expect(find.text('Değişiklikler kaydedilmedi'), findsNothing);
    expect(find.text('Notlarım'), findsOneWidget);
  });

  testWidgets('add a new category from the editor', (tester) async {
    final controller = await _pumpApp(tester);
    await tester.tap(find.byTooltip('Yeni not'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title-field')), 'Vize');

    await tester.tap(find.byKey(const Key('new-category')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category-name-field')), 'Okul');
    await tester.tap(find.byKey(const Key('category-add')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-note')));
    await tester.pumpAndSettle();

    expect(controller.categories, contains('Okul'));
    expect(controller.notes.single.category, 'Okul');
    expect(find.byKey(const Key('filter-Okul')), findsOneWidget);
  });

  testWidgets('a new note starts in the category being filtered', (tester) async {
    final controller = await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('filter-İş')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Yeni not'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('title-field')), 'Rapor');
    await tester.tap(find.byKey(const Key('save-note')));
    await tester.pumpAndSettle();
    expect(controller.notes.single.category, 'İş');
  });

  testWidgets('dark theme renders', (tester) async {
    final controller = NotesController(MemoryNoteStore(notes: [_note('a', 'Gece notu', 'x', 'Genel', 1)]));
    await tester.pumpWidget(NotesApp(controller: controller, themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Gece notu'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  group('reminders', () {
    testWidgets('a card shows the countdown, and the round check ticks the note off', (tester) async {
      final controller = await _pumpApp(
        tester,
        notes: [
          _note('late', 'Kitabı iade et', '', 'Okul', 60, dueAt: _dayFromToday(-1, 17)),
          _note('soon', 'Sınav', '', 'Okul', 60, dueAt: _dayFromToday(3, 10)),
        ],
      );

      expect(find.byKey(const Key('upcoming-strip')), findsOneWidget);
      expect(find.textContaining('Gecikti'), findsWidgets);
      expect(find.textContaining('3 gün kaldı'), findsWidgets);

      final card = find.byKey(const ValueKey('note-late'));
      await tester.tap(find.descendant(of: card, matching: find.byTooltip('Tamamlandı olarak işaretle')));
      await tester.pumpAndSettle();
      expect(controller.noteById('late')!.done, isTrue);
      expect(controller.overdue(), isEmpty);
    });

    testWidgets('calendar: the selected day lists its notes on the timeline', (tester) async {
      final tomorrow = _dayFromToday(1, 10);
      await _pumpApp(tester, notes: [_note('t', 'Diş hekimi', '', 'Kişisel', 60, dueAt: tomorrow)]);

      await tester.tap(_tab('Takvim'));
      await tester.pumpAndSettle();
      expect(find.text('Bu gün için hatırlatma yok'), findsOneWidget);

      if (tomorrow.month != DateTime.now().month) {
        await tester.tap(find.byTooltip('Sonraki ay'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(Key('day-${tomorrow.year}-${tomorrow.month}-${tomorrow.day}')));
      await tester.pumpAndSettle();
      expect(find.text('Diş hekimi'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('calendar: "Bu güne not ekle" starts a note with a reminder on that day', (tester) async {
      final controller = await _pumpApp(tester);
      await tester.tap(_tab('Takvim'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-note-on-day')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reminder-tile')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('title-field')), 'Spor salonu');
      await tester.ensureVisible(find.byKey(const Key('save-note')));
      await tester.tap(find.byKey(const Key('save-note')));
      await tester.pumpAndSettle();

      final note = controller.notes.single;
      expect(note.dueAt, _dayFromToday(0, 9));
      expect(find.text('Spor salonu'), findsOneWidget); // on today's timeline
    });

    testWidgets('upcoming tab groups reminders', (tester) async {
      await _pumpApp(
        tester,
        notes: [
          _note('a', 'Gecikmiş iş', '', 'İş', 60, dueAt: _dayFromToday(-2, 9)),
          _note('b', 'Yarınki toplantı', '', 'İş', 60, dueAt: _dayFromToday(1, 11)),
          _note('c', 'Tatil', '', 'Kişisel', 60, dueAt: _dayFromToday(20, 8)),
          _note('d', 'Tarihsiz not', '', 'Genel', 60),
        ],
      );
      await tester.tap(_tab('Yaklaşanlar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group-Gecikenler')), findsOneWidget);
      expect(find.byKey(const Key('group-Yarın')), findsOneWidget);
      expect(find.byKey(const Key('group-Daha sonra')), findsOneWidget);
      expect(find.text('Yarınki toplantı'), findsOneWidget);
      expect(find.text('Tarihsiz not'), findsNothing);
      expect(find.text('20 gün kaldı'), findsOneWidget);
    });

    testWidgets('a reminder can be removed in the editor', (tester) async {
      final controller = await _pumpApp(
        tester,
        notes: [_note('r', 'Hatırlatmalı', 'x', 'Genel', 60, dueAt: _dayFromToday(5, 12))],
      );
      await tester.tap(find.byKey(const ValueKey('note-r')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-toggle-done')), findsOneWidget);

      await tester.tap(find.byTooltip('Düzenle'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Hatırlatmayı kaldır'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hatırlatmayı kaldır'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add-reminder')), findsOneWidget);
      await tester.tap(find.byKey(const Key('save-note')));
      await tester.pumpAndSettle();

      expect(controller.noteById('r')!.dueAt, isNull);
    });
  });
}
