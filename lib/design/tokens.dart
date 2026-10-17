import 'package:flutter/material.dart';

/// Design tokens: colors, spacing, radii and motion durations.
abstract final class AppColors {
  static const darkBg = Color(0xFF08090A);
  static const darkSurface = Color(0xFF101113);
  static const darkSurfaceHigh = Color(0xFF17181B);
  static const darkBorder = Color(0xFF232529);
  static const darkTextPrimary = Color(0xFFF7F8F8);
  static const darkTextSecondary = Color(0xFF8A8F98);
  static const darkTextTertiary = Color(0xFF62666D);

  static const lightBg = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF7F8F9);
  static const lightSurfaceHigh = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE7E8EA);
  static const lightTextPrimary = Color(0xFF16171A);
  static const lightTextSecondary = Color(0xFF6B6F76);
  static const lightTextTertiary = Color(0xFF9AA0A6);

  static const accent = Color(0xFF5E6AD2);
  static const accentPressed = Color(0xFF4F5ABF);
  static const accentSoft = Color(0x1F5E6AD2);
  static const success = Color(0xFF4CB782);
  static const warning = Color(0xFFE2A83B);
  static const danger = Color(0xFFE5484D);
  static const dangerSoft = Color(0x1FE5484D);
}

abstract final class Space {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
}

abstract final class Radii {
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;
}
