import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A scroll behavior that allows mouse-drag scrolling.
///
/// Wrap only horizontal strips (desktop tab bar, mobile session cards) with a
/// [ScrollConfiguration] using this behavior. Do not set it on
/// [MaterialApp.scrollBehavior]: it would capture the terminal viewport's
/// mouse selection gestures.
class HorizontalDragScrollBehavior extends MaterialScrollBehavior {
  const HorizontalDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}
