import 'package:flutter/material.dart';

class FocusFlowTheme {
  FocusFlowTheme._();

  // Global Brand Colors
  static const Color primary = Color(0xFF7C5CFF);
  static const Color secondary = Color(0xFF22D3EE);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF090B12);
  static const Color darkSurface = Color(0xFF121625);
  static const Color darkSurfaceSoft = Color(0xFF1A2033);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSoft = Color(0xFFEFF2FA);

  // Text Colors
  static const Color _darkText = Color(
    0xFFEEF0FF,
  ); // slightly cool-tinted white
  static const Color _lightText = Color(0xFF1C1F2E); // warm-tinted near-black
  static const Color _lightTextMid = Color(
    0xFF4A5068,
  ); // mid-tone for light theme
  static const Color _lightTextSoft = Color(
    0xFF717899,
  ); // soft secondary for light theme

  // ==========================================
  // SHARED TEXT THEME FACTORY
  // ==========================================

  static TextTheme _buildTextTheme({required bool dark}) {
    final high = dark ? _darkText : _lightText;
    final mid = dark
        ? const Color(0xBBEEF0FF)
        : _lightTextMid; // ~73% opacity cool white
    final soft = dark
        ? const Color(0x8AEEF0FF)
        : _lightTextSoft; // ~54% opacity cool white

    // DM Sans is the expressive display face; Inter is the legible body face.
    // Both are variable fonts — set fontVariations for precise weight tuning.
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 48,
        fontWeight: FontWeight.w900,
        fontVariations: const [FontVariation('wght', 900)],
        letterSpacing: -2.0,
        height: 1.05,
        color: high,
      ),
      displayMedium: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 40,
        fontWeight: FontWeight.w900,
        fontVariations: const [FontVariation('wght', 900)],
        letterSpacing: -1.6,
        height: 1.08,
        color: high,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 32,
        fontWeight: FontWeight.w800,
        fontVariations: const [FontVariation('wght', 800)],
        letterSpacing: -1.0,
        height: 1.1,
        color: high,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 26,
        fontWeight: FontWeight.w800,
        fontVariations: const [FontVariation('wght', 800)],
        letterSpacing: -0.7,
        height: 1.15,
        color: high,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        fontVariations: const [FontVariation('wght', 700)],
        letterSpacing: -0.4,
        height: 1.2,
        color: high,
      ),
      titleLarge: TextStyle(
        fontFamily: 'DMSans',
        fontSize: 19,
        fontWeight: FontWeight.w700,
        fontVariations: const [FontVariation('wght', 700)],
        letterSpacing: -0.3,
        height: 1.25,
        color: high,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontVariations: const [FontVariation('wght', 600)],
        letterSpacing: -0.15,
        height: 1.3,
        color: high,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontVariations: const [FontVariation('wght', 600)],
        letterSpacing: 0.1,
        height: 1.35,
        color: mid,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontVariations: const [FontVariation('wght', 400)],
        letterSpacing: -0.1,
        height: 1.55,
        color: high,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontVariations: const [FontVariation('wght', 400)],
        letterSpacing: -0.05,
        height: 1.55,
        color: mid,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontVariations: const [FontVariation('wght', 400)],
        letterSpacing: 0.05,
        height: 1.45,
        color: soft,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontVariations: const [FontVariation('wght', 600)],
        letterSpacing: 0.2,
        height: 1.3,
        color: high,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontVariations: const [FontVariation('wght', 500)],
        letterSpacing: 0.3,
        height: 1.3,
        color: mid,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        fontVariations: const [FontVariation('wght', 500)],
        letterSpacing: 0.5,
        height: 1.3,
        color: soft,
      ),
    );
  }

  // ==========================================
  // DARK THEME
  // ==========================================
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: secondary,
      surface: darkSurface,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Inter',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: _buildTextTheme(dark: true),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _darkText,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontVariations: const [FontVariation('wght', 800)],
          color: _darkText,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface.withValues(alpha: 0.90),
        surfaceTintColor: Colors.transparent,
        // Subtle glow from primary — makes cards feel lit, not just flat
        shadowColor: primary.withValues(alpha: 0.22),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: darkSurface.withValues(alpha: 0.96),
        indicatorColor: primary.withValues(alpha: 0.20),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontVariations: [FontVariation('wght', selected ? 700 : 500)],
            letterSpacing: 0.2,
            color: selected ? _darkText : Colors.white.withValues(alpha: 0.50),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 26 : 23,
            color: selected ? primary : Colors.white.withValues(alpha: 0.50),
          );
        }),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.1,
            fontVariations: [FontVariation('wght', 700)],
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkText,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontVariations: [FontVariation('wght', 600)],
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: -0.1,
            fontVariations: [FontVariation('wght', 600)],
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceSoft.withValues(alpha: 0.60),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primary.withValues(alpha: 0.70),
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.55),
        ),
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.35),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.white.withValues(alpha: 0.65);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.32);
          }
          return Colors.white.withValues(alpha: 0.10);
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceSoft,
        selectedColor: primary.withValues(alpha: 0.25),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontVariations: [FontVariation('wght', 500)],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.07),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ==========================================
  // LIGHT THEME
  // ==========================================
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      surface: lightSurface,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: 'Inter',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: _buildTextTheme(dark: false),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _lightText,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontVariations: const [FontVariation('wght', 800)],
          color: _lightText,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: lightSurface.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        shadowColor: primary.withValues(alpha: 0.10),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.055)),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: lightSurface.withValues(alpha: 0.96),
        indicatorColor: primary.withValues(alpha: 0.13),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontVariations: [FontVariation('wght', selected ? 700 : 500)],
            letterSpacing: 0.2,
            color: selected ? _lightText : _lightTextSoft,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 26 : 23,
            color: selected ? primary : _lightTextSoft,
          );
        }),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.1,
            fontVariations: [FontVariation('wght', 700)],
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightText,
          side: BorderSide(color: Colors.black.withValues(alpha: 0.11)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontVariations: [FontVariation('wght', 600)],
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: -0.1,
            fontVariations: [FontVariation('wght', 600)],
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.07)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primary.withValues(alpha: 0.65),
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _lightTextSoft,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: _lightTextSoft.withValues(alpha: 0.70),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return const Color(0xFFB0B8D0);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.28);
          }
          return Colors.black.withValues(alpha: 0.08);
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceSoft,
        selectedColor: primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontVariations: const [FontVariation('wght', 500)],
          color: _lightTextMid,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
