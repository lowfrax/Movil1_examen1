import 'package:flutter/material.dart';

class P3Palette {
  static const Color midnight = Color(0xFF0F1841); // Azul oscuro
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color blue = Color(0xFF1977F5);
  static const Color cyan = Color(0xFF00BEF2);
  static const Color lightCyan = Color(0xFF5CE3EC);
  static const Color cobalt = Color(0xFF0000C6);
  static const Color aqua = Color(0xFF00BBEA);
}

ThemeData buildP3Theme() {
  final ColorScheme scheme = ColorScheme(
    brightness: Brightness.light,
    primary: P3Palette.blue,
    onPrimary: P3Palette.white,
    secondary: P3Palette.cyan,
    onSecondary: P3Palette.black,
    tertiary: P3Palette.lightCyan,
    onTertiary: P3Palette.black,
    error: const Color(0xFFB00020),
    onError: P3Palette.white,
    surface: P3Palette.white,
    onSurface: P3Palette.midnight,
    surfaceContainerHighest: P3Palette.white,
    surfaceContainerHigh: P3Palette.white,
    surfaceContainer: P3Palette.white,
    surfaceContainerLow: const Color(0xFFF6F8FC),
    surfaceContainerLowest: const Color(0xFFF9FBFF),
    surfaceBright: P3Palette.white,
    surfaceDim: const Color(0xFFF1F4FA),
    outline: P3Palette.midnight.withOpacity(0.12),
    outlineVariant: P3Palette.midnight.withOpacity(0.24),
    scrim: P3Palette.black.withOpacity(0.5),
    shadow: P3Palette.black,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF6F8FC),
    appBarTheme: AppBarTheme(
      backgroundColor: P3Palette.midnight,
      foregroundColor: P3Palette.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: P3Palette.midnight.withOpacity(0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: P3Palette.midnight.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: P3Palette.midnight.withOpacity(0.7)),
      hintStyle: TextStyle(color: P3Palette.midnight.withOpacity(0.4)),
      prefixIconColor: scheme.primary,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: P3Palette.black.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}

BoxDecoration p3BackgroundGradient() {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        P3Palette.midnight,
        P3Palette.blue.withOpacity(0.95),
        P3Palette.cyan.withOpacity(0.9),
      ],
      stops: const [0.0, 0.55, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

BoxDecoration p3PanelDecoration(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: Colors.white.withOpacity(0.96),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: P3Palette.midnight.withOpacity(0.15),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
    border: Border.all(color: scheme.primary.withOpacity(0.08)),
  );
}
