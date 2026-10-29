import 'package:flutter_test/flutter_test.dart';
import 'package:unidev_note_app/models/note.dart';
import 'package:unidev_note_app/util/text.dart';

Note _note({String title = '', String content = '', DateTime? created, DateTime? updated}) {
  final c = created ?? DateTime(2026, 10, 29, 9);
  return Note(id: 'n', title: title, content: content, category: 'Genel', createdAt: c, updatedAt: updated ?? c);
}

void main() {
  group('Note', () {
    test('uses the title, or the first line of the content when there is no title', () {
      expect(_note(title: ' Market ', content: 'Süt').displayTitle, 'Market');
      expect(_note(content: '\n  Süt\nYumurta').displayTitle, 'Süt');
      expect(_note().displayTitle, 'Başlıksız not');
    });

    test('preview skips the line already shown as the title', () {
      expect(_note(title: 'Market', content: 'Süt\n\nYumurta').preview, 'Süt · Yumurta');
      expect(_note(content: 'Süt\nYumurta\nEkmek').preview, 'Yumurta · Ekmek');
    });

    test('wasEdited compares the two timestamps', () {
      final t = DateTime(2026, 1, 1, 12);
      expect(_note(created: t).wasEdited, isFalse);
      expect(_note(created: t, updated: t.add(const Duration(minutes: 5))).wasEdited, isTrue);
    });

    test('copyWith keeps createdAt and the fields that are not given', () {
      final note = _note(title: 'A', content: 'B');
      final copy = note.copyWith(title: 'C');
      expect(copy.title, 'C');
      expect(copy.content, 'B');
      expect(copy.createdAt, note.createdAt);
      expect(copy, isNot(equals(note)));
      expect(note.copyWith(), equals(note));
    });
  });

  group('foldForSearch', () {
    test('treats the Turkish i letters as one', () {
      expect(foldForSearch('İŞ'), foldForSearch('iş'));
      expect(foldForSearch('ISPARTA'), foldForSearch('ısparta'));
      expect(foldForSearch('Kişisel'), 'kişisel');
    });
  });

  group('formatRelative', () {
    final now = DateTime(2026, 10, 29, 14, 30);

    test('recent times', () {
      expect(formatRelative(now.subtract(const Duration(seconds: 20)), now: now), 'Az önce');
      expect(formatRelative(now.subtract(const Duration(minutes: 7)), now: now), '7 dk önce');
      expect(formatRelative(DateTime(2026, 10, 29, 9, 5), now: now), 'Bugün 09:05');
      expect(formatRelative(DateTime(2026, 10, 28, 23, 50), now: now), 'Dün 23:50');
    });

    test('older dates', () {
      expect(formatRelative(DateTime(2026, 3, 12, 8), now: now), '12 Mar');
      expect(formatRelative(DateTime(2024, 8, 1, 8), now: now), '1 Ağu 2024');
    });

    test('a time slightly in the future (clock skew) is "Az önce"', () {
      expect(formatRelative(now.add(const Duration(seconds: 30)), now: now), 'Az önce');
    });
  });

  test('formatFull', () {
    expect(formatFull(DateTime(2026, 10, 29, 14, 5)), '29 Ekim 2026, 14:05');
  });
}
