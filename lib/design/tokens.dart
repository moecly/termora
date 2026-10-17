import 'package:flutter/material.dart';

/// Design tokens: colors, spacing, radii and shadows.
abstract final class AppColors {
  // Dark: bg → surface → high → highest (four elevation levels).
  static const darkBg = Color(0xFF08090A);
  static const darkSurface = Color(0xFF101113);
  static const darkSurfaceHigh = Color(0xFF17181B);
  static const darkSurfaceHighest = Color(0xFF1E2024);
  static const darkBorder = Color(0xFF232529);
  static const darkBorderStrong = Color(0xFF33363D);
  static const darkTextPrimary = Color(0xFFF5F6F8);
  static const darkTextSecondary = Color(0xFF8F959F);
  static const darkTextTertiary = Color(0xFF5F646C);
  static const darkHairline = Color(0x0DFFFFFF); // top highlight on high surface.

  // Light: grey background + pure white surfaces.
  static const lightBg = Color(0xFFF5F6F8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFFFFFFF);
  static const lightSurfaceHighest = Color(0xFFFFFFFF);
  static const lightSurfaceSunken = Color(0xFFEDEFF3); // input well.
  static const lightBorder = Color(0xFFE4E7EB);
  static const lightBorderStrong = Color(0xFFD3D7DD);
  static const lightTextPrimary = Color(0xFF14161A);
  static const lightTextSecondary = Color(0xFF5F6672);
  static const lightTextTertiary = Color(0xFF8B929C);

  // Accent and status colors.
  static const accent = Color(0xFF5E6AD2);
  static const accentHover = Color(0xFF6C77DC);
  static const accentPressed = Color(0xFF4C57BE);
  static const accentSoft = Color(0x1A5E6AD2);
  static const success = Color(0xFF4CB782);
  static const warning = Color(0xFFE2A83B);
  static const danger = Color(0xFFE5484D);
  static const dangerSoft = Color(0x1FE5484D);

  // Interaction overlays and scrims.
  static const darkScrim = Color(0x8C000000);
  static const lightScrim = Color(0x52000000);
  static const darkHoverOverlay = Color(0x14FFFFFF);
  static const lightHoverOverlay = Color(0x0A000000);
  static const darkPressedOverlay = Color(0x24FFFFFF);
  static const lightPressedOverlay = Color(0x14000000);
}

abstract final class Space {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;
}

abstract final class Radii {
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
}

abstract final class AppShadows {
  /// Elevation shadows. [level]: 1 card/input focus, 2 raised control,
  /// 3 overlay/menu.
  static List<BoxShadow> of(Brightness brightness, int level) {
    final dark = brightness == Brightness.dark;
    return switch (level) {
      1 => [
        BoxShadow(
          color: Color(dark ? 0x40000000 : 0x12000000),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      2 => [
        BoxShadow(
          color: Color(dark ? 0x52000000 : 0x1A000000),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      3 => [
        BoxShadow(
          color: Color(dark ? 0x66000000 : 0x24000000),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ],
      _ => const <BoxShadow>[],
    };
  }
}
