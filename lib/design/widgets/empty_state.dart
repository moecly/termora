import 'package:flutter/material.dart';

import '../tokens.dart';

/// A centered empty-state placeholder with an icon, title and optional subtitle.
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
    final tertiary = theme.brightness == Brightness.dark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: tertiary),
            const SizedBox(height: Space.x4),
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: Space.x1),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
