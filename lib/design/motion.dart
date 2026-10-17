import 'package:flutter/material.dart';

/// Unified motion durations and curves.
abstract final class Motion {
  static const press = Duration(milliseconds: 100);
  static const hover = Duration(milliseconds: 140);
  static const control = Duration(milliseconds: 160);
  static const overlay = Duration(milliseconds: 180);
  static const tab = Duration(milliseconds: 200);
  static const panel = Duration(milliseconds: 260);
  static const page = Duration(milliseconds: 300);
  static const spatial = Duration(milliseconds: 380);
  static const pulse = Duration(milliseconds: 1200); // StatusDot breathing.
  static const stagger = Duration(milliseconds: 24); // stagger step.
  static const maxStaggerIndex = 8; // stagger cap, avoids long tails.

  static const easeOut = Curves.easeOutCubic;
  static const easeIn = Curves.easeInCubic;
  static const easeInOut = Curves.easeInOutCubic;
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const emphasizedAccel = Cubic(0.3, 0.0, 0.8, 0.15);
  static const spring = SpringDescription(mass: 1, stiffness: 380, damping: 30);
}

abstract final class AppMotion {
  /// System "reduce motion" preference. Spec §7 fallback; no in-app setting.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration scale(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  /// For showDialog / showModalBottomSheet / PopupMenuButton.
  static AnimationStyle style(
    BuildContext context, {
    required Duration duration,
    required Duration reverseDuration,
  }) =>
      reduced(context)
          ? AnimationStyle.noAnimation
          : AnimationStyle(
              duration: duration,
              reverseDuration: reverseDuration,
              curve: Motion.emphasized,
              reverseCurve: Motion.emphasizedAccel,
            );
}
