import 'package:flutter/material.dart';

import 'motion.dart';

/// Unified overlay entry points: every dialog/sheet/menu shares the same
/// motion language and honors the reduced-motion fallback.

Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = false,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    animationStyle: AppMotion.style(
      context,
      duration: Motion.overlay,
      reverseDuration: Motion.press,
    ),
    builder: builder,
  );
}

Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    showDragHandle: true,
    sheetAnimationStyle: AppMotion.style(
      context,
      duration: Motion.panel,
      reverseDuration: Motion.overlay,
    ),
    builder: builder,
  );
}

Future<T?> showAppMenu<T>(
  BuildContext context, {
  required RelativeRect position,
  required List<PopupMenuEntry<T>> items,
}) {
  return showMenu<T>(
    context: context,
    position: position,
    items: items,
    popUpAnimationStyle: AppMotion.style(
      context,
      duration: Motion.overlay,
      reverseDuration: Motion.press,
    ),
  );
}
