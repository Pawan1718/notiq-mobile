import 'package:flutter/material.dart';

/// Uses the same official brand mark as Notiq.React/NotiqBrand.tsx.
/// Compact mode deliberately displays the mark only, matching React.
class NotiqBrand extends StatelessWidget {
  const NotiqBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mark = Image.asset(
      'assets/branding/notiq-mark.png',
      width: compact ? 36 : 56,
      height: compact ? 36 : 56,
      fit: BoxFit.contain,
      semanticLabel: 'Notiq',
    );

    if (compact) return mark;

    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notiq',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            Text(
              'COMMUNICATION OS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
