import 'package:flutter/material.dart';

import '../motion.dart';
import '../palette.dart';

/// Wraps [child] with press feedback (a subtle scale) plus a click cursor.
///
/// Under reduced motion the press is not animated, but taps still work.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.pressedScale = 0.98,
    this.borderRadius,
    this.cursor = SystemMouseCursors.click,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final double pressedScale;
  final BorderRadius? borderRadius;
  final MouseCursor cursor;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final interactive =
        widget.onTap != null ||
        widget.onLongPress != null ||
        widget.onSecondaryTap != null;
    return MouseRegion(
      cursor: interactive ? widget.cursor : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onSecondaryTap: widget.onSecondaryTap,
        child: AnimatedScale(
          scale: _pressed && !AppMotion.reduced(context) ? widget.pressedScale : 1.0,
          duration: Motion.press,
          curve: Motion.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A surface whose background and border color animate on hover.
///
/// Hover is tracked internally via [MouseRegion] (always false on mobile);
/// the optional [hovered] argument forces the hovered appearance. Uses a plain
/// [GestureDetector] for taps — do not stack an [InkWell] on top.
class HoverSurface extends StatefulWidget {
  const HoverSurface({
    super.key,
    required this.child,
    this.hovered,
    this.baseColor,
    this.hoverColor,
    this.borderRadius,
    required this.border,
    required this.hoverBorder,
    this.spotlight = false,
    this.spotlightRadius = 120,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
  });

  final Widget child;
  final bool? hovered;
  final Color? baseColor;
  final Color? hoverColor;
  final BorderRadius? borderRadius;
  final BorderSide border;
  final BorderSide hoverBorder;

  /// Draws a soft radial accent glow that follows the pointer.
  final bool spotlight;
  final double spotlightRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;

  @override
  State<HoverSurface> createState() => _HoverSurfaceState();
}

class _HoverSurfaceState extends State<HoverSurface> {
  bool _hover = false;
  Offset _local = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final hovered = _hover || (widget.hovered ?? false);
    final interactive =
        widget.onTap != null ||
        widget.onLongPress != null ||
        widget.onSecondaryTap != null;
    final radius = widget.borderRadius ?? BorderRadius.zero;
    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      onHover: (e) {
        if (widget.spotlight) setState(() => _local = e.localPosition);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onSecondaryTap: widget.onSecondaryTap,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: Motion.hover,
                curve: Motion.easeInOut,
                decoration: BoxDecoration(
                  color: hovered
                      ? (widget.hoverColor ?? widget.baseColor)
                      : widget.baseColor,
                  borderRadius: radius,
                  border: Border.fromBorderSide(
                    hovered ? widget.hoverBorder : widget.border,
                  ),
                ),
                child: widget.child,
              ),
              if (widget.spotlight)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: hovered ? 1 : 0,
                      duration: Motion.hover,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
                          final alignment = (w <= 0 || h <= 0)
                              ? Alignment.center
                              : Alignment(
                                  (_local.dx / w) * 2 - 1,
                                  (_local.dy / h) * 2 - 1,
                                );
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                radius: widget.spotlightRadius / 100,
                                center: alignment,
                                colors: [
                                  p.accent.withValues(alpha: 0.10),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
