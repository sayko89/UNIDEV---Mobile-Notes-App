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

const _shortWeekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const _weekdays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

/// Weekday labels for a calendar that starts on Monday, as is usual in Turkey.
List<String> get shortWeekdays => List.unmodifiable(_shortWeekdays);

/// The date without the time of day.
DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Calendar days from [now] until [time]: 0 = today, 1 = tomorrow, -1 = yesterday.
int daysUntil(DateTime time, DateTime now) => _calendarDays(now, time);

/// "Günaydın", "İyi günler", "İyi akşamlar" or "İyi geceler", by the hour.
String greeting(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return 'Günaydın';
  if (h >= 12 && h < 18) return 'İyi günler';
  if (h >= 18 && h < 22) return 'İyi akşamlar';
  return 'İyi geceler';
}

/// "30 Ekim, Perşembe".
String formatDayTitle(DateTime t) => '${t.day} ${_months[t.month - 1]}, ${_weekdays[t.weekday - 1]}';

/// "Ekim 2026".
String formatMonthTitle(DateTime t) => '${_months[t.month - 1]} ${t.year}';

/// Short month name in capitals for date tiles: "EKİ".
String shortMonthUpper(DateTime t) => _shortMonths[t.month - 1].replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// "14:05".
String formatTime(DateTime t) => _time(t);

/// When a reminder is due: "Bugün 14:00", "Yarın 09:30", "Dün 18:00", "2 Kas Pzt, 14:00",
/// "2 Kas 2027, 14:00".
String formatDue(DateTime due, {DateTime? now}) {
  now ??= DateTime.now();
  final days = daysUntil(due, now);
  if (days == 0) return 'Bugün ${_time(due)}';
  if (days == 1) return 'Yarın ${_time(due)}';
  if (days == -1) return 'Dün ${_time(due)}';
  if (due.year == now.year) {
    return '${due.day} ${_shortMonths[due.month - 1]} ${_shortWeekdays[due.weekday - 1]}, ${_time(due)}';
  }
  return '${due.day} ${_shortMonths[due.month - 1]} ${due.year}, ${_time(due)}';
}

/// Countdown to a reminder: "Gecikti", "Bugün", "Yarın", "3 gün kaldı".
String formatCountdown(DateTime due, {DateTime? now}) {
  now ??= DateTime.now();
  if (due.isBefore(now)) return 'Gecikti';
  final days = daysUntil(due, now);
  if (days == 0) return 'Bugün';
  if (days == 1) return 'Yarın';
  return '$days gün kaldı';
}
