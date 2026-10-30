import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/note.dart';
import 'reminders.dart';

/// Phone notifications on Android and iOS, using flutter_local_notifications.
///
/// Times are scheduled as an absolute instant (in UTC), so the device's time zone database
/// isn't needed: the notification fires at the moment the user picked.
class LocalNotificationReminders implements Reminders {
  LocalNotificationReminders._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Hatırlatmalar',
      channelDescription: 'Notlara eklenen tarih ve saatte gelen hatırlatmalar',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<LocalNotificationReminders> create() async {
    tz_data.initializeTimeZones();
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Ask for permission when the user first adds a reminder, not at app start.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    return LocalNotificationReminders._(plugin);
  }

  @override
  bool get isSupported => true;

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    return false;
  }

  @override
  Future<void> sync(Note note, {required DateTime now}) async {
    final id = notificationIdFor(note.id);
    await _plugin.cancel(id: id);
    if (!shouldNotify(note, now)) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: note.displayTitle,
        body: note.preview.isEmpty ? 'Hatırlatma' : note.preview,
        scheduledDate: tz.TZDateTime.from(note.dueAt!.toUtc(), tz.UTC),
        notificationDetails: _details,
        // Inexact scheduling needs no special "exact alarm" permission; the notification may
        // arrive a few minutes late, which is fine for a note reminder.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (error) {
      debugPrint('Could not schedule a reminder for ${note.id}: $error');
    }
  }

  @override
  Future<void> cancel(String noteId) => _plugin.cancel(id: notificationIdFor(noteId));
}
