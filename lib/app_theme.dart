import 'package:flutter/material.dart';

// ── Global dark mode notifier ──────────────────────────────────────────────────
// Read from SharedPreferences in main.dart on startup; toggled from profile.dart.
final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(true);

// ── Theme builders ─────────────────────────────────────────────────────────────

const kOrange = Color(0xFFFF8200);

ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);
ThemeData buildLightTheme() => _buildTheme(Brightness.light);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final bg = isDark ? const Color(0xFF161616) : const Color(0xFFF3F3F3);
  final surface = isDark ? const Color(0xFF2A2A2A) : Colors.white;
  final textPrimary = isDark ? Colors.white : const Color(0xFF111111);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: kOrange,
      onPrimary: Colors.white,
      secondary: kOrange,
      onSecondary: Colors.white,
      error: const Color(0xFFFF5252),
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kOrange, width: 1.5),
      ),
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF888888) : const Color(0xFF999999),
        fontSize: 15,
      ),
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFF888888) : const Color(0xFF777777),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFF5252)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : const Color(0xFF111111),
        side: BorderSide(
          color: isDark ? Colors.white38 : const Color(0xFF333333).withValues(alpha: 0.4),
          width: 1,
        ),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF444444),
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
        fontSize: 14,
      ),
    ),
  );
}

// ── BuildContext extension — colour tokens ─────────────────────────────────────

extension AppTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Main scaffold/page background
  Color get bg => isDark ? const Color(0xFF161616) : const Color(0xFFF3F3F3);

  /// Card / list-item background
  Color get surface => isDark ? const Color(0xFF2A2A2A) : Colors.white;

  /// Elevated modal / bottom-sheet background
  Color get card => isDark ? const Color(0xFF1E1E1E) : Colors.white;

  /// Nested card inside a card, image error placeholder
  Color get surfaceLight => isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEBEBEB);

  /// Primary text
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF111111);

  /// Secondary / muted text
  Color get textMuted => isDark ? const Color(0xFF888888) : const Color(0xFF666666);

  /// Body copy text
  Color get textBody => isDark ? const Color(0xFFCCCCCC) : const Color(0xFF444444);

  /// Subtle border / divider
  Color get border => isDark
      ? Colors.white.withValues(alpha: 0.07)
      : Colors.black.withValues(alpha: 0.09);

  /// Slightly stronger divider line
  Color get divider => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.black.withValues(alpha: 0.10);

  /// Icon / button ghost background
  Color get ghostBg => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.05);
}
