import 'package:flutter/material.dart';

enum NotiqButtonVariant { primary, secondary, danger }

/// Consistent asynchronous-action presentation; callers own network state.
class NotiqButton extends StatelessWidget {
  const NotiqButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.variant = NotiqButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final NotiqButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = loading ? null : onPressed;
    final scheme = Theme.of(context).colorScheme;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == NotiqButtonVariant.secondary
                  ? scheme.primary
                  : Colors.white,
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );
    switch (variant) {
      case NotiqButtonVariant.primary:
        return FilledButton(onPressed: enabled, child: content);
      case NotiqButtonVariant.secondary:
        return OutlinedButton(onPressed: enabled, child: content);
      case NotiqButtonVariant.danger:
        return FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: enabled,
          child: content,
        );
    }
  }
}
