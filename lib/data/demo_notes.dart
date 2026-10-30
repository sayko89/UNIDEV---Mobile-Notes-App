import '../models/note.dart';

/// Sample content for the web demo (`?demo=1`). Times are relative to [now], so the demo
/// always has something overdue, something today and something coming up.
List<Note> demoNotes(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(int days, int hour, [int minute = 0]) =>
      DateTime(today.year, today.month, today.day + days, hour, minute);

  Note note(
    String id,
    String title,
    String content,
    String category,
    Duration age, {
    Duration? edited,
    DateTime? dueAt,
    bool done = false,
  }) {
    final created = now.subtract(age);
    return Note(
      id: id,
      title: title,
      content: content,
      category: category,
      createdAt: created,
      updatedAt: edited == null ? created : now.subtract(edited),
      dueAt: dueAt,
      done: done,
    );
  }

  // Today's reminders sit a little before and after the current time (but stay on today).
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 30);
  DateTime todayIn(Duration offset) {
    final t = now.add(offset);
    return t.isAfter(endOfToday) ? endOfToday : DateTime(t.year, t.month, t.day, t.hour, t.minute < 30 ? 0 : 30);
  }

  final laterToday =
      now.add(const Duration(hours: 2)).isBefore(today.add(const Duration(days: 1)))
          ? now.add(const Duration(hours: 2))
          : today.add(const Duration(hours: 23, minutes: 30));

  return [
    note(
      'demo-1',
      'Market listesi',
      'Süt\nYumurta\nTam buğday ekmek\nMuz\nKahve çekirdeği',
      'Kişisel',
      const Duration(days: 2),
      edited: const Duration(minutes: 4),
    ),
    note(
      'demo-2',
      'Haftalık toplantı',
      'Sprint hedefleri gözden geçirilecek.\nAPI dokümantasyonu cuma gününe kadar tamamlanacak.',
      'İş',
      const Duration(hours: 3),
      dueAt: DateTime(laterToday.year, laterToday.month, laterToday.day, laterToday.hour, 0),
    ),
    note(
      'demo-3',
      'Bilgisayar Ağları vizesi',
      'OSI katmanları, TCP el sıkışması, alt ağ hesapları.\nÇıkmış soruları çöz.',
      'Okul',
      const Duration(days: 1, hours: 2),
      dueAt: at(3, 10),
    ),
    note(
      'demo-4',
      'Ayşe’nin doğum günü',
      'Hediye: Rüzgârın Gölgesi (kitap)\nAkşam yemeği rezervasyonu',
      'Kişisel',
      const Duration(days: 4),
      dueAt: at(9, 19, 30),
    ),
    note(
      'demo-5',
      'Kütüphane kitabını iade et',
      'Veri Yapıları — 2. kat',
      'Okul',
      const Duration(days: 9),
      dueAt: at(-1, 17),
    ),
    note('demo-6', 'Elektrik faturası', 'Son ödeme günü', 'Genel', const Duration(days: 12), dueAt: at(6, 12)),
    note(
      'demo-7',
      'Proje sunumu provası',
      'Slaytlar hazır, süre 10 dakika.',
      'İş',
      const Duration(days: 3),
      dueAt: at(-2, 14),
      done: true,
    ),
    note(
      'demo-9',
      'Sabah koşusu',
      '5 km, sahil yolu',
      'Kişisel',
      const Duration(days: 1),
      dueAt: DateTime(now.year, now.month, now.day, 7, 30),
      done: true,
    ),
    note(
      'demo-10',
      'Elif ile kahve',
      'Kampüs kafe — staj başvurularını konuşalım.',
      'Kişisel',
      const Duration(hours: 20),
      dueAt: todayIn(const Duration(hours: 4)),
    ),
    note('demo-8', '', 'Kitap önerisi: Kürk Mantolu Madonna\nZeynep tavsiye etti.', 'Kişisel', const Duration(days: 6)),
  ];
}

const demoCategories = ['Genel', 'İş', 'Kişisel', 'Okul'];
