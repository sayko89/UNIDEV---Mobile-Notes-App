import 'package:flutter/material.dart';

/// Colours taken from the UI prototype (docs/prototype.png): a soft grey page, white cards
/// and a muted blue-green accent. The accent from the prototype (#7AAFC4) is too light for
/// white button text, so buttons use a darker shade of the same hue for readable contrast.
const prototypeAccent = Color(0xFF7AAFC4);
const _accentLight = Color(0xFF3B7A93);

ThemeData buildTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  var scheme = ColorScheme.fromSeed(seedColor: prototypeAccent, brightness: brightness);
  if (isLight) scheme = scheme.copyWith(primary: _accentLight, onPrimary: Colors.white);

  final page = isLight ? const Color(0xFFF0F0EE) : const Color(0xFF101416);
  final card = isLight ? Colors.white : const Color(0xFF1A2023);
  final radius = BorderRadius.circular(18);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: page,
    appBarTheme: AppBarTheme(
      backgroundColor: page,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
      backgroundColor: card,
      showCheckmark: false,
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: card, showDragHandle: true),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      elevation: 0,
      height: 68,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
