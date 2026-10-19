import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Unified motion durations and curves.
abstract final class Motion {
  static const press = Duration(milliseconds: 90);
  static const hover = Duration(milliseconds: 130);
  static const control = Duration(milliseconds: 150);
  static const overlay = Duration(milliseconds: 200);
  static const tab = Duration(milliseconds: 220);
  static const panel = Duration(milliseconds: 300);
  static const page = Duration(milliseconds: 340);
  static const spatial = Duration(milliseconds: 420);
  static const reveal = Duration(milliseconds: 480);
  static const pulse = Duration(milliseconds: 1400);
  static const breathe = Duration(milliseconds: 2600);
  static const stagger = Duration(milliseconds: 28);
  static const maxStaggerIndex = 10;

  static const easeOut = Curves.easeOutCubic;
  static const easeIn = Curves.easeInCubic;
  static const easeInOut = Curves.easeInOutCubic;
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const emphasizedAccel = Cubic(0.3, 0.0, 0.8, 0.15);
  static const overshoot = Cubic(0.34, 1.2, 0.64, 1.0);

  static const snap = SpringDescription(mass: 1, stiffness: 520, damping: 34);

  /// Convenience for [AnimationController.animateWith]; velocity is px/s or 1/s.
  static SpringSimulation to(
    SpringDescription spring, {
    required double from,
    required double to,
    double velocity = 0,
  }) =>
      SpringSimulation(spring, from, to, velocity);
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
