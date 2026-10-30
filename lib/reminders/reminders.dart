import '../models/note.dart';

/// Schedules a phone notification for each note's reminder.
///
/// [NotesController] calls [sync] after every change, and the implementation decides:
/// a future, not-done reminder is (re)scheduled; anything else is cancelled.
abstract interface class Reminders {
  Future<void> sync(Note note, {required DateTime now});
  Future<void> cancel(String noteId);

  /// Asks the user for permission to show notifications (Android 13+, iOS).
  /// Returns whether notifications can be shown.
  Future<bool> requestPermission();

  /// False where notifications aren't available (web, tests).
  bool get isSupported;
}

/// Used on the web, in the demo and in tests: reminders are shown in the app only.
class NoReminders implements Reminders {
  const NoReminders();

  @override
  Future<void> sync(Note note, {required DateTime now}) async {}

  @override
  Future<void> cancel(String noteId) async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  bool get isSupported => false;
}

/// Turns a note id into the int id a notification needs. FNV-1a, kept to 31 bits.
int notificationIdFor(String noteId) {
  var hash = 0x811c9dc5;
  for (final unit in noteId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

/// Whether a note should have a scheduled notification.
bool shouldNotify(Note note, DateTime now) => note.dueAt != null && !note.done && note.dueAt!.isAfter(now);
