import '../models/note.dart';

/// Sample content for the web demo (`?demo=1`). Times are relative to [now].
List<Note> demoNotes(DateTime now) {
  Note note(String id, String title, String content, String category, Duration age, {Duration? edited}) {
    final created = now.subtract(age);
    return Note(
      id: id,
      title: title,
      content: content,
      category: category,
      createdAt: created,
      updatedAt: edited == null ? created : now.subtract(edited),
    );
  }

  return [
    note('demo-1', 'Market listesi', 'Süt\nYumurta\nTam buğday ekmek\nMuz\nKahve çekirdeği', 'Kişisel',
        const Duration(days: 2), edited: const Duration(minutes: 4)),
    note('demo-2', 'Haftalık toplantı', 'Sprint hedefleri gözden geçirildi.\n'
        'API dokümantasyonu cuma gününe kadar tamamlanacak.\nYeni tasarım cuma demo.', 'İş',
        const Duration(hours: 3)),
    note('demo-3', 'Bilgisayar Ağları vizesi', 'OSI katmanları, TCP el sıkışması, alt ağ hesapları.\n'
        'Çıkmış soruları çöz.', 'Okul', const Duration(days: 1, hours: 2)),
    note('demo-4', '', 'Kitap önerisi: Rüzgârın Gölgesi\nAyşe tavsiye etti.', 'Kişisel',
        const Duration(days: 6)),
    note('demo-5', 'Hatırlatma', 'Fatura son ödeme günü 15’i.', 'Genel', const Duration(days: 40)),
  ];
}

const demoCategories = ['Genel', 'İş', 'Kişisel', 'Okul'];
