/// Helpers for Turkish text: search folding and date formatting.
library;

/// Lower-cases text for searching, treating the Turkish dotted and dotless i (İ, I, ı, i)
/// as the same letter — so "iş", "İŞ" and "IS" all find a note titled "İş planı".
String foldForSearch(String text) {
  return text.replaceAll('İ', 'i').replaceAll('I', 'i').replaceAll('ı', 'i').toLowerCase();
}

const _shortMonths = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String _two(int n) => n.toString().padLeft(2, '0');

String _time(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// Whole calendar days from [from] to [to], ignoring the time of day and daylight saving.
int _calendarDays(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// Short, relative time for lists: "Az önce", "5 dk önce", "Bugün 14:05", "Dün 09:30",
/// "12 Mar", "12 Mar 2024".
String formatRelative(DateTime time, {DateTime? now}) {
  now ??= DateTime.now();
  final elapsed = now.difference(time);
  if (elapsed.inSeconds < 60) return 'Az önce';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} dk önce';
  final days = _calendarDays(time, now);
  if (days == 0) return 'Bugün ${_time(time)}';
  if (days == 1) return 'Dün ${_time(time)}';
  if (time.year == now.year) return '${time.day} ${_shortMonths[time.month - 1]}';
  return '${time.day} ${_shortMonths[time.month - 1]} ${time.year}';
}

/// Full date and time: "29 Ekim 2026, 14:05".
String formatFull(DateTime time) => '${time.day} ${_months[time.month - 1]} ${time.year}, ${_time(time)}';
