import 'package:flutter/material.dart';

/// Raw color constants kept only for non-UI code (terminal style, status
/// colors). UI widgets must read colors from [AppPalette] instead.
abstract final class AppColors {
  /// Status colors shared with the terminal status line and status icons.
  static const success = Color(0xFF3ED598);
  static const warning = Color(0xFFF0B429);
  static const danger = Color(0xFFFF5A5F);
  static const dangerSoft = Color(0x1FFF5A5F);
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
  static const md = 10.0;
  static const lg = 14.0;
  static const xl = 20.0;
  static const pill = 999.0;
}

abstract final class AppShadows {
  /// Elevation shadows. [level]: 1 card/input focus, 2 raised control,
  /// 3 overlay/menu, 4 command palette.
  static List<BoxShadow> of(Brightness brightness, int level) {
    final dark = brightness == Brightness.dark;
    return switch (level) {
      1 => [
        BoxShadow(
          color: Color(dark ? 0x4D000000 : 0x14000000),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
      2 => [
        BoxShadow(
          color: Color(dark ? 0x5C000000 : 0x1F000000),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      3 => [
        BoxShadow(
          color: Color(dark ? 0x73000000 : 0x26000000),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ],
      4 => [
        BoxShadow(
          color: Color(dark ? 0x8C000000 : 0x2E000000),
          blurRadius: 64,
          offset: const Offset(0, 24),
        ),
      ],
      _ => const <BoxShadow>[],
    };
  }
}
