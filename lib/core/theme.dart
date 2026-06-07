import 'package:flutter/material.dart';

class EM {
  static const bg           = Color(0xFFF4F6F5);
  static const surface      = Color(0xFFFFFFFF);
  static const surface2     = Color(0xFFF0F4F1);
  static const primary      = Color(0xFF16A34A);
  static const primaryDark  = Color(0xFF15803D);
  static const primaryLight = Color(0xFF22C55E);
  static const accent       = Color(0xFF0F766E);
  static const accentLight  = Color(0xFF14B8A6);
  static const text         = Color(0xFF1C2B20);
  static const textMuted    = Color(0xFF6B7280);
  static const border       = Color(0xFFE5E7EB);
  static const danger       = Color(0xFFDC2626);
  static const dangerLight  = Color(0xFFEF4444);
  static const success      = Color(0xFF16A34A);
  static const successLight = Color(0xFF22C55E);
  static const warning      = Color(0xFFF59E0B);
  static const shadow       = Color(0x0A000000);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: EM.bg,
    colorScheme: const ColorScheme.light(
      primary: EM.primary,
      secondary: EM.accent,
      surface: EM.surface,
      error: EM.dangerLight,
    ),
    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: EM.text, letterSpacing: -1),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: EM.text),
      titleLarge:    TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EM.text),
      titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: EM.text),
      bodyLarge:     TextStyle(fontSize: 15, color: EM.text),
      bodyMedium:    TextStyle(fontSize: 13, color: EM.textMuted),
      labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EM.textMuted, letterSpacing: 0.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: EM.surface,
      hintStyle: const TextStyle(color: EM.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EM.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EM.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EM.primary, width: 1.8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: EM.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: EM.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: EM.border)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: EM.surface,
      foregroundColor: EM.text,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: EM.text),
    ),
  );
}
