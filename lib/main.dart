import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'data/demo_notes.dart';
import 'data/hive_note_store.dart';
import 'data/note_store.dart';
import 'notes_controller.dart';
import 'reminders/local_notification_reminders.dart';
import 'reminders/reminders.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On the web, `?demo=1` opens the app with sample notes kept in memory only, so the
  // live demo never touches a visitor's saved notes. `?theme=dark|light` forces a theme.
  final params = Uri.base.queryParameters;
  final demo = params['demo'] == '1';

  final NoteStore store;
  if (demo) {
    store = MemoryNoteStore(notes: demoNotes(DateTime.now()), categories: demoCategories);
  } else {
    await Hive.initFlutter();
    store = await HiveNoteStore.open();
  }

  // Phone notifications on Android and iOS. Browsers can't schedule notifications for later,
  // so on the web reminders are shown inside the app only.
  Reminders reminders = const NoReminders();
  if (!kIsWeb && !demo) {
    try {
      reminders = await LocalNotificationReminders.create();
    } catch (error) {
      debugPrint('Notifications unavailable: $error');
    }
  }

  final themeMode = switch (params['theme']) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };

  runApp(NotesApp(controller: NotesController(store, reminders: reminders), themeMode: themeMode));
}
