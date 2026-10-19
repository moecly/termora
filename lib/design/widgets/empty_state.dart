import 'package:flutter/material.dart';

import '../palette.dart';
import '../tokens.dart';
import 'enter_transition.dart';

/// A centered empty-state placeholder with an icon, title and optional
/// subtitle. Renders a dotted grid plate with an accent corner tick.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = AppPalette.of(context);
    return Center(
      child: EnterTransition(
        index: 0,
        child: Padding(
          padding: const EdgeInsets.all(Space.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.surfaceHigh,
                    borderRadius: BorderRadius.circular(Radii.lg),
                  ),
                  child: CustomPaint(
                    painter: _DotGridPainter(color: p.textTertiary),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 2,
                            decoration: BoxDecoration(
                              color: p.accent,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(Radii.lg),
                              ),
                            ),
                          ),
                        ),
                        Center(child: Icon(icon, size: 28, color: p.textTertiary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.x4),
              Text(title, style: theme.textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: Space.x1),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: p.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const cells = 5;
    final paint = Paint()..color = color.withValues(alpha: 0.20);
    final dx = size.width / (cells + 1);
    final dy = size.height / (cells + 1);
    for (var x = 1; x <= cells; x++) {
      for (var y = 1; y <= cells; y++) {
        canvas.drawCircle(Offset(dx * x, dy * y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}
