import 'package:flutter/material.dart';

class AppTheme {
  // Dark theme colors (web versiyonuyla birebir)
  static const Color bg = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surface2 = Color(0xFF1A1A28);
  static const Color accent = Color(0xFF7C3AED);
  static const Color accent2 = Color(0xFFA855F7);
  static const Color accent3 = Color(0xFFC084FC);
  static const Color textColor = Color(0xFFE2D9F3);
  static const Color muted = Color(0xFF7C6FA0);
  static const Color border = Color(0xFF2A2040);
  static const Color danger = Color(0xFFEF4444);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: accent2,
      surface: surface,
      error: danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: muted),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: accent2,
      unselectedItemColor: muted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
