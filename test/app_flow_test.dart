import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unidev_note_app/app.dart';
import 'package:unidev_note_app/data/note_store.dart';
import 'package:unidev_note_app/models/note.dart';
import 'package:unidev_note_app/notes_controller.dart';

Note _note(String id, String title, String content, String category, int minutesAgo) {
  final time = DateTime.now().subtract(Duration(minutes: minutesAgo));
  return Note(id: id, title: title, content: content, category: category, createdAt: time, updatedAt: time);
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
}
