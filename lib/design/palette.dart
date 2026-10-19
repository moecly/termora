import 'package:flutter/material.dart';

/// The Signal palette: every UI color flows through this [ThemeExtension], so
/// widgets read `AppPalette.of(context)` instead of `dark ? X : Y` ternaries.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.hairline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentHover,
    required this.accentPressed,
    required this.accentSoft,
    required this.onAccent,
    required this.hoverOverlay,
    required this.pressedOverlay,
    required this.scrim,
    required this.live,
    required this.warn,
    required this.danger,
    required this.dangerSoft,
    required this.idle,
    required this.signal,
  });

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;
  final Color hairline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentHover;
  final Color accentPressed;
  final Color accentSoft;
  final Color onAccent;
  final Color hoverOverlay;
  final Color pressedOverlay;
  final Color scrim;
  final Color live;
  final Color warn;
  final Color danger;
  final Color dangerSoft;
  final Color idle;
  final Color signal;

  static const dark = AppPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF07090C),
    surface: Color(0xFF0D1015),
    surfaceHigh: Color(0xFF141821),
    surfaceHighest: Color(0xFF1B2029),
    surfaceSunken: Color(0xFF04060A),
    border: Color(0xFF1E242E),
    borderStrong: Color(0xFF2D3541),
    hairline: Color(0x14FFFFFF),
    textPrimary: Color(0xFFE9EDF5),
    textSecondary: Color(0xFF8B95A7),
    textTertiary: Color(0xFF59626F),
    accent: Color(0xFF4FD1FF),
    accentHover: Color(0xFF74DCFF),
    accentPressed: Color(0xFF2FB8EB),
    accentSoft: Color(0x1F4FD1FF),
    onAccent: Color(0xFF04121B),
    hoverOverlay: Color(0x14FFFFFF),
    pressedOverlay: Color(0x24FFFFFF),
    scrim: Color(0xA6000000),
    live: Color(0xFF3ED598),
    warn: Color(0xFFF0B429),
    danger: Color(0xFFFF5A5F),
    dangerSoft: Color(0x1FFF5A5F),
    idle: Color(0xFF3A424E),
    signal: Color(0xFF7FE3FF),
  );

  static const light = AppPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF2F4F8),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFFFFFFF),
    surfaceHighest: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFE8ECF3),
    border: Color(0xFFDDE3EC),
    borderStrong: Color(0xFFC6CEDA),
    hairline: Color(0x0D0E1218),
    textPrimary: Color(0xFF0E1218),
    textSecondary: Color(0xFF5B6472),
    textTertiary: Color(0xFF8A93A1),
    accent: Color(0xFF0B7FC4),
    accentHover: Color(0xFF0E93DE),
    accentPressed: Color(0xFF096BA8),
    accentSoft: Color(0x1A0B7FC4),
    onAccent: Color(0xFFFFFFFF),
    hoverOverlay: Color(0x0A0E1218),
    pressedOverlay: Color(0x140E1218),
    scrim: Color(0x52000000),
    live: Color(0xFF1F9D63),
    warn: Color(0xFFB7791F),
    danger: Color(0xFFD93B3F),
    dangerSoft: Color(0x1FD93B3F),
    idle: Color(0xFFAAB2BE),
    signal: Color(0xFF0B7FC4),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ??
      (Theme.of(context).brightness == Brightness.light ? light : dark);

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? bg,
    Color? surface,
    Color? surfaceHigh,
    Color? surfaceHighest,
    Color? surfaceSunken,
    Color? border,
    Color? borderStrong,
    Color? hairline,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentHover,
    Color? accentPressed,
    Color? accentSoft,
    Color? onAccent,
    Color? hoverOverlay,
    Color? pressedOverlay,
    Color? scrim,
    Color? live,
    Color? warn,
    Color? danger,
    Color? dangerSoft,
    Color? idle,
    Color? signal,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceHighest: surfaceHighest ?? this.surfaceHighest,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      hairline: hairline ?? this.hairline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      hoverOverlay: hoverOverlay ?? this.hoverOverlay,
      pressedOverlay: pressedOverlay ?? this.pressedOverlay,
      scrim: scrim ?? this.scrim,
      live: live ?? this.live,
      warn: warn ?? this.warn,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      idle: idle ?? this.idle,
      signal: signal ?? this.signal,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surfaceHigh: c(surfaceHigh, other.surfaceHigh),
      surfaceHighest: c(surfaceHighest, other.surfaceHighest),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      hairline: c(hairline, other.hairline),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      accent: c(accent, other.accent),
      accentHover: c(accentHover, other.accentHover),
      accentPressed: c(accentPressed, other.accentPressed),
      accentSoft: c(accentSoft, other.accentSoft),
      onAccent: c(onAccent, other.onAccent),
      hoverOverlay: c(hoverOverlay, other.hoverOverlay),
      pressedOverlay: c(pressedOverlay, other.pressedOverlay),
      scrim: c(scrim, other.scrim),
      live: c(live, other.live),
      warn: c(warn, other.warn),
      danger: c(danger, other.danger),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      idle: c(idle, other.idle),
      signal: c(signal, other.signal),
    );
  }
}
