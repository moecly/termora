import 'package:flutter/material.dart';

import 'motion.dart';

/// A route for the terminal page: a "new context" rather than sibling
/// navigation, so it fades in while scaling up from slightly smaller.
Route<T> terminalRoute<T>({required WidgetBuilder builder}) => PageRouteBuilder<T>(
  transitionDuration: Motion.spatial,
  reverseTransitionDuration: Motion.panel,
  pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    if (AppMotion.reduced(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.emphasized,
      reverseCurve: Motion.emphasizedAccel,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.965, end: 1).animate(curved),
        child: child,
      ),
    );
  },
);
