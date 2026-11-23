import 'package:flutter/material.dart';

/// Hearth UX Spec v1 Design Tokens adapted for Liquid Glass (WCAG AA/AAA contrast)
class HearthTokens {
  // Light mode core tokens (from spec)
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F6F8);
  static const Color lightText = Color(0xFF1A1D21); // 16.6:1 on #FFFFFF
  static const Color lightTextMuted = Color(0xFF5B6470); // 6.0:1 on #FFFFFF
  static const Color lightAccent = Color(0xFF1F5FBF); // 6.1:1 on #FFFFFF
  static const Color lightCritical = Color(0xFFB42318); // 6.6:1 on #FFFFFF
  static const Color lightOk = Color(0xFF1E7A3E); // ~5.3:1 on #FFFFFF
  static const Color lightWarning = Color(0xFF9A5B00); // >5.2:1 on #FFFFFF
  static const Color lightBorder = Color(0xFFD5D9DF);

  // Dark mode liquid glass tokens (high legibility on deep obsidian glass)
  static const Color darkBg = Color(0xFF0A1017);
  static const Color darkSurface = Color(0xFF131C26);
  static const Color darkText = Color(0xFFF3F6FA);
  static const Color darkTextMuted = Color(0xFFA6B4C4);
  static const Color darkAccent = Color(0xFF6BA6FF);
  static const Color darkCritical = Color(0xFFFF6B63);
  static const Color darkOk = Color(0xFF4CD980);
  static const Color darkWarning = Color(0xFFFFC15E);
  static const Color darkBorder = Color(0xFF2B3948);

  // Spacing scale: 4 · 8 · 12 · 16 · 24 · 32 · 48
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;

  // Minimum interactive targets & radii
  static const double minTarget = 48;
  static const double alertTarget = 56;
  static const double cardRadius = 18;
  static const double buttonRadius = 12;
  static const double chipRadius = 14;
}

class HearthPalette extends ThemeExtension<HearthPalette> {
  final Color bg;
  final Color surface;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color critical;
  final Color ok;
  final Color warning;
  final Color border;
  final Color glassFill;
  final Color glassHighlight;
  final Color glassShadow;

  const HearthPalette({
    required this.bg,
    required this.surface,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.critical,
    required this.ok,
    required this.warning,
    required this.border,
    required this.glassFill,
    required this.glassHighlight,
    required this.glassShadow,
  });

  static const light = HearthPalette(
    bg: HearthTokens.lightBg,
    surface: HearthTokens.lightSurface,
    text: HearthTokens.lightText,
    textMuted: HearthTokens.lightTextMuted,
    accent: HearthTokens.lightAccent,
    critical: HearthTokens.lightCritical,
    ok: HearthTokens.lightOk,
    warning: HearthTokens.lightWarning,
    border: HearthTokens.lightBorder,
    glassFill: Color(0xD9FFFFFF), // High-clarity frosted glass preserving >= 6:1 contrast
    glassHighlight: Color(0xF5FFFFFF),
    glassShadow: Color(0x141F3A5F),
  );

  static const dark = HearthPalette(
    bg: HearthTokens.darkBg,
    surface: HearthTokens.darkSurface,
    text: HearthTokens.darkText,
    textMuted: HearthTokens.darkTextMuted,
    accent: HearthTokens.darkAccent,
    critical: HearthTokens.darkCritical,
    ok: HearthTokens.darkOk,
    warning: HearthTokens.darkWarning,
    border: HearthTokens.darkBorder,
    glassFill: Color(0xBF15202D),
    glassHighlight: Color(0x38FFFFFF),
    glassShadow: Color(0x55000000),
  );

  static HearthPalette of(BuildContext context) {
    return Theme.of(context).extension<HearthPalette>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  HearthPalette copyWith({
    Color? bg,
    Color? surface,
    Color? text,
    Color? textMuted,
    Color? accent,
    Color? critical,
    Color? ok,
    Color? warning,
    Color? border,
    Color? glassFill,
    Color? glassHighlight,
    Color? glassShadow,
  }) {
    return HearthPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      critical: critical ?? this.critical,
      ok: ok ?? this.ok,
      warning: warning ?? this.warning,
      border: border ?? this.border,
      glassFill: glassFill ?? this.glassFill,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      glassShadow: glassShadow ?? this.glassShadow,
    );
  }

  @override
  HearthPalette lerp(ThemeExtension<HearthPalette>? other, double t) {
    if (other is! HearthPalette) return this;
    return HearthPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      border: Color.lerp(border, other.border, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
    );
  }
}

class HearthTheme {
  static ThemeData build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final p = isDark ? HearthPalette.dark : HearthPalette.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: isDark ? const Color(0xFF071529) : Colors.white,
      secondary: p.accent,
      onSecondary: Colors.white,
      error: p.critical,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.text,
      outline: p.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.bg,
      extensions: [p],
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -0.3,
          color: p.text,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.25,
          letterSpacing: -0.2,
          color: p.text,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: p.text,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: p.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: p.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: p.textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: p.text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xA6192635) : const Color(0xEBFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.text),
        helperStyle: TextStyle(fontSize: 14, color: p.textMuted),
        errorStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.critical),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.accent, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.critical, width: 1.8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.critical, width: 2.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: p.text,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.border.withValues(alpha: isDark ? 0.45 : 0.7),
        thickness: 1,
      ),
      focusColor: p.accent.withValues(alpha: 0.25),
    );
  }
}
