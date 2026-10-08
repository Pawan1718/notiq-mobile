import 'package:flutter/material.dart';

/// A compact, accessible metric surface for server-provided counts and costs.
class NotiqMetricCard extends StatelessWidget {
  const NotiqMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon = Icons.analytics_outlined,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            const SizedBox(width: 8),
            Text(value, style: theme.textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
