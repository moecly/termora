import 'package:flutter/material.dart';

import '../tokens.dart';

/// A small uppercase section label with an optional trailing widget.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x4, Space.x2),
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
