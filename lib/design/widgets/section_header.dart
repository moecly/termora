import 'package:flutter/material.dart';

import '../tokens.dart';

/// A small uppercase section label with an optional trailing widget.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
    this.dense = false,
  });

  final String title;
  final Widget? trailing;

  /// Overrides the default outer padding (for reuse inside cards/forms).
  final EdgeInsetsGeometry? padding;

  /// Tightens the default padding for dense card usage.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final resolvedPadding =
        padding ??
        (dense
            ? const EdgeInsets.fromLTRB(Space.x3, Space.x3, Space.x3, Space.x1)
            : const EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x4, Space.x2));
    return Padding(
      padding: resolvedPadding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
                color: color,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
