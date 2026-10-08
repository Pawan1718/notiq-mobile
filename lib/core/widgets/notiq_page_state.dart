import 'package:flutter/material.dart';

/// Standard empty, loading and recoverable failure presentations.
class NotiqPageState extends StatelessWidget {
  const NotiqPageState.loading({super.key})
      : title = null,
        message = null,
        icon = null,
        onRetry = null,
        isLoading = true;

  const NotiqPageState.empty({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
  })  : onRetry = null,
        isLoading = false;

  const NotiqPageState.error({
    super.key,
    this.title = 'Unable to load data',
    this.message = 'Please try again.',
    this.onRetry,
    this.icon = Icons.error_outline,
  }) : isLoading = false;

  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.secondary),
            const SizedBox(height: 12),
            Text(title ?? '', style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!, textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
