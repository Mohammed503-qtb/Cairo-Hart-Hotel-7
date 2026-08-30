import 'package:flutter/material.dart';

/// Hotel platform theme: warm gold + deep charcoal, no indigo/blue dominance.
/// Used across all roles (Website, Guest, Reception, Admin) for one design system.
class AppTheme {
  AppTheme._();

  // Brand seed colors (warm, hotel-hospitality palette)
  static const Color _seed = Color(0xFFB8860B); // dark goldenrod
  static const Color _ink = Color(0xFF1F1B16); // warm charcoal
  static const Color _sand = Color(0xFFF6F1E7); // warm sand surface
  static const Color _sandDark = Color(0xFF211C16);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      primary: const Color(0xFF9A6A12),
      secondary: const Color(0xFF5C6B5A),
      surface: const Color(0xFFFFFBF4),
      onSurface: const Color(0xFF211C16),
    );
    return _build(scheme, _sand, _ink);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      primary: const Color(0xFFE6B450),
      secondary: const Color(0xFFA8C0A4),
      surface: const Color(0xFF1A1712),
      onSurface: const Color(0xFFEDE3D0),
    );
    return _build(scheme, _sandDark, const Color(0xFFEDE3D0));
  }

  static ThemeData _build(
    ColorScheme scheme,
    Color scaffoldBg,
    Color ink,
  ) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      dividerColor: ink.withOpacity(0.12),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? _sandDark : Colors.white,
        foregroundColor: ink,
        elevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0.6 : 0.8,
        color: isDark ? const Color(0xFF262019) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: ink.withOpacity(isDark ? 0.18 : 0.07)),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ink.withOpacity(0.06),
        labelStyle: TextStyle(
          color: ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(56, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(56, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: scheme.primary.withOpacity(0.5)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ink.withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ink.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ink.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        labelStyle: TextStyle(color: ink.withOpacity(0.7), fontSize: 13),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? _sandDark : Colors.white,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: ink.withOpacity(0.55)),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(color: ink.withOpacity(0.7)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? _sandDark : Colors.white,
        height: 64,
        indicatorColor: scheme.primary.withOpacity(0.14),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      textTheme: _textTheme(ink),
    );
  }

  static TextTheme _textTheme(Color ink) {
    final base = TextStyle(color: ink);
    return TextTheme(
      displayLarge: base.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displayMedium: base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      headlineMedium: base.copyWith(
        fontSize: 23,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      headlineSmall: base.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.copyWith(fontSize: 15.5, height: 1.55),
      bodyMedium: base.copyWith(fontSize: 14.5, height: 1.5),
      bodySmall: base.copyWith(fontSize: 12.5, height: 1.4),
      labelLarge: base.copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: base.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}
