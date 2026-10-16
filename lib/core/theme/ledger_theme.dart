import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Vibrant Midnight Ledger — design tokens for Cuan mobile.
/// Dark premium base with rich, expressive color.
/// Deliberately different from the light editorial web dashboard.
abstract final class LedgerTheme {
  static bool _isDark = true;
  static bool get isDark => _isDark;
  static void setDark(bool value) => _isDark = value;

  // Base — dynamic by theme mode
  static Color get bg =>
      _isDark ? const Color(0xFF0B0F0E) : const Color(0xFFF5F7F5);
  static Color get surface =>
      _isDark ? const Color(0xFF141A17) : const Color(0xFFFFFFFF);
  static Color get surface2 =>
      _isDark ? const Color(0xFF1C2420) : const Color(0xFFEBEEEA);
  static Color get border =>
      _isDark ? const Color(0x14FFFFFF) : const Color(0x22000000);
  static Color get text =>
      _isDark ? const Color(0xFFF2F5F3) : const Color(0xFF141817);
  static Color get muted =>
      _isDark ? const Color(0xFFA8B3AD) : const Color(0xFF5C6663);

  /// Text hierarchy — startup-fintech standard. All body text uses neutral
  /// colors; the teal accent is reserved for interactive elements only.
  /// displayLarge: hero numbers (balance) — tabular figures keep digits aligned.
  static TextStyle get displayLarge => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: text,
        letterSpacing: -0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// headlineMedium: section/card titles.
  static TextStyle get headlineMedium => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: text,
        letterSpacing: -0.25,
      );

  /// bodyLarge: primary body copy.
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: text,
      );

  /// bodyMedium: secondary body copy, list values.
  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: text,
      );

  /// caption: labels, hints, timestamps — always muted, never accent.
  static TextStyle get caption => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: muted,
      );

  // Brand (same both modes)
  static const accent = Color(0xFF5EEAD4); // teal — AI + primary actions
  static const accentDim = Color(0xFF2A3D38);

  /// Foreground color for content placed ON TOP of the accent color
  /// (FABs, filled buttons, chips). Always dark — accent is bright.
  static const onAccent = Color(0xFF0B0F0E);

  // Palette — restrained, data-first. No AI-purple.
  static const teal = Color(0xFF5EEAD4);
  static const sky = Color(0xFF7DD3FC);
  static const rose = Color(0xFFFB7185);
  static const amber = Color(0xFFFBBF24);
  static const emerald = Color(0xFF34D399);
  static const income = Color(0xFF4ADE80);
  static const expense = Color(0xFFF87171);

  /// Category colors — teal-family led, assigned per category for charts.
  static const categoryColors = [
    teal,
    sky,
    emerald,
    amber,
    rose,
    Color(0xFF67E8F9),
    Color(0xFF2DD4BF),
    Color(0xFFFCD34D),
  ];

  /// Hero gradient — the ONE brand gradient, reserved for the balance hero.
  /// Everything else uses solid surfaces (anti-slop: no rainbow gradients).
  static const heroGradient = LinearGradient(
    colors: [Color(0xFF0E3B34), Color(0xFF0B0F0E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const accentGradient = LinearGradient(
    colors: [Color(0xFF5EEAD4), Color(0xFF7DD3FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Foreground (icon/text) color that stays readable on a gradient.
  /// Uses average luminance of the gradient stops: bright gradients
  /// (accent, mint, gold, royal, sunset) get dark ink, dark ones get white.
  static Color foregroundFor(Gradient gradient) {
    if (gradient is LinearGradient && gradient.colors.isNotEmpty) {
      var total = 0.0;
      for (final c in gradient.colors) {
        total += c.computeLuminance();
      }
      final avg = total / gradient.colors.length;
      return avg > 0.45 ? onAccent : Colors.white;
    }
    return Colors.white;
  }

  /// Foreground color readable on a solid [color] (category avatars, chips).
  static Color foregroundForColor(Color color) {
    return color.computeLuminance() > 0.45 ? onAccent : Colors.white;
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: teal,
        tertiary: amber,
        surface: surface,
        onSurface: text,
        error: expense,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: text,
        titleTextStyle: displaySerif(26),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: TextStyle(color: muted),
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: teal,
        tertiary: amber,
        surface: surface,
        onSurface: text,
        error: expense,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: text,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: TextStyle(color: muted),
      ),
    );
  }

  /// Current theme by mode.
  static ThemeData get current => _isDark ? dark : light;

  /// Radius system — by component role, not decoration.
  /// hero: 24 (balance hero, large feature cards)
  /// card: 20 (standard cards, dialogs, result panels)
  /// tile: 16 (list tiles, inputs, quick actions)
  /// avatar: 12 (icon avatars)
  /// sheet: 28 top (bottom sheets only)
  static const double radiusHero = 24;
  static const double radiusCard = 20;
  static const double radiusTile = 16;
  static const double radiusAvatar = 12;

  /// Serif display for the balance hero — the editorial signature.
  static TextStyle displaySerif(double size,
      {Color? color, FontWeight? weight}) {
    return GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w600,
      color: color ?? text,
      letterSpacing: -0.5,
    );
  }
}
