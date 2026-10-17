import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'motion.dart';

/// A route for the terminal page: a "new context" rather than sibling
/// navigation, so it uses fade-through (old page fades out, new fades in)
/// instead of a horizontal shared axis.
Route<T> terminalRoute<T>({required WidgetBuilder builder}) => PageRouteBuilder<T>(
  transitionDuration: Motion.page,
  reverseTransitionDuration: Motion.panel,
  pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      AppMotion.reduced(context)
          ? child
          : FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            ),
);
