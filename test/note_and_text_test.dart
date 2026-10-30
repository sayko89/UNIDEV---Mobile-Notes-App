import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:unidev_note_app/models/category_style.dart';
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

  group('reminders on a note', () {
    test('copyWith changes dueAt only when asked, so it can also be cleared', () {
      final due = DateTime(2026, 11, 2, 14);
      final note = _note(title: 'A').copyWith(setDue: true, dueAt: due);
      expect(note.dueAt, due);
      expect(note.copyWith(title: 'B').dueAt, due);
      expect(note.copyWith(setDue: true, dueAt: null).dueAt, isNull);
    });

    test('isOverdue: past, not done', () {
      final now = DateTime(2026, 10, 30, 12);
      final past = _note().copyWith(setDue: true, dueAt: DateTime(2026, 10, 30, 9));
      expect(past.isOverdue(now), isTrue);
      expect(past.copyWith(done: true).isOverdue(now), isFalse);
      expect(_note().isOverdue(now), isFalse);
    });
  });

  group('reminder texts', () {
    final now = DateTime(2026, 10, 30, 12); // a Friday

    test('formatDue', () {
      expect(formatDue(DateTime(2026, 10, 30, 14), now: now), 'Bugün 14:00');
      expect(formatDue(DateTime(2026, 10, 31, 9, 30), now: now), 'Yarın 09:30');
      expect(formatDue(DateTime(2026, 10, 29, 18), now: now), 'Dün 18:00');
      expect(formatDue(DateTime(2026, 11, 2, 14), now: now), '2 Kas Pzt, 14:00');
      expect(formatDue(DateTime(2027, 1, 5, 8), now: now), '5 Oca 2027, 08:00');
    });

    test('formatCountdown', () {
      expect(formatCountdown(DateTime(2026, 10, 30, 11), now: now), 'Gecikti');
      expect(formatCountdown(DateTime(2026, 10, 30, 18), now: now), 'Bugün');
      expect(formatCountdown(DateTime(2026, 10, 31, 8), now: now), 'Yarın');
      expect(formatCountdown(DateTime(2026, 11, 6, 8), now: now), '7 gün kaldı');
    });

    test('greeting by hour', () {
      expect(greeting(DateTime(2026, 1, 1, 8)), 'Günaydın');
      expect(greeting(DateTime(2026, 1, 1, 13)), 'İyi günler');
      expect(greeting(DateTime(2026, 1, 1, 20)), 'İyi akşamlar');
      expect(greeting(DateTime(2026, 1, 1, 2)), 'İyi geceler');
    });

    test('day and month titles', () {
      expect(formatDayTitle(now), '30 Ekim, Cuma');
      expect(formatMonthTitle(now), 'Ekim 2026');
      expect(shortMonthUpper(now), 'EKİ');
      expect(shortMonthUpper(DateTime(2026, 8, 1)), 'AĞU');
      expect(shortWeekdays.first, 'Pzt');
    });
  });

  group('category style', () {
    test('known categories have their own colour and icon, whatever the case', () {
      expect(categoryStyle('İş').icon, Icons.work_outline);
      expect(categoryStyle('iş').color, categoryStyle('İŞ').color);
      expect(categoryStyle('Okul').icon, Icons.school_outlined);
    });

    test('new categories always get the same colour', () {
      expect(categoryStyle('Hobiler').color, categoryStyle('Hobiler').color);
      expect(categoryStyle('Hobiler').icon, Icons.label_outline);
    });
  });
}
