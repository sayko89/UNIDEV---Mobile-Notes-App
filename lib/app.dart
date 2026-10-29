import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'notes_controller.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

class NotesApp extends StatelessWidget {
  const NotesApp({super.key, required this.controller, this.themeMode = ThemeMode.system});

  final NotesController controller;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNIDEV Notlar',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeScreen(controller: controller),
    );
  }
}
