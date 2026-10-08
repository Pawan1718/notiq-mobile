import 'package:flutter/material.dart';

enum NotiqStatusTone { neutral, success, warning, danger, info }

/// Visual status only: never infers authorization or backend state.
class NotiqStatusBadge extends StatelessWidget {
  const NotiqStatusBadge({
    super.key,
    required this.label,
    this.tone = NotiqStatusTone.neutral,
  });

  final String label;
  final NotiqStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color;
    switch (tone) {
      case NotiqStatusTone.success:
        color = theme.brightness == Brightness.dark
            ? const Color(0xFF53DEB7)
            : const Color(0xFF087F61);
      case NotiqStatusTone.warning:
        color = theme.brightness == Brightness.dark
            ? const Color(0xFFFFCA78)
            : const Color(0xFF9A5B00);
      case NotiqStatusTone.danger:
        color = theme.colorScheme.error;
      case NotiqStatusTone.info:
        color = theme.colorScheme.primary;
      case NotiqStatusTone.neutral:
        color = theme.colorScheme.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(
        color: color, fontWeight: FontWeight.w700,
      )),
    );
  }
}
