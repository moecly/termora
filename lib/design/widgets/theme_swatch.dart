import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import '../motion.dart';
import '../palette.dart';
import '../tokens.dart';

/// A compact 4-band swatch previewing a [TerminalTheme], with an accent
/// selection ring.
class TerminalThemeSwatch extends StatelessWidget {
  const TerminalThemeSwatch({
    super.key,
    required this.theme,
    required this.selected,
    this.size = 28,
  });

  final TerminalTheme theme;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AnimatedContainer(
      duration: Motion.control,
      curve: Motion.easeInOut,
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(
          color: selected ? p.accent : Colors.transparent,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Row(
          children: [
            for (final color in [theme.red, theme.green, theme.yellow, theme.blue])
              Expanded(child: ColoredBox(color: color)),
          ],
        ),
      ),
    );
  }
}
