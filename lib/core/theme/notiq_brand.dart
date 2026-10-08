import 'package:flutter/material.dart';
import 'notiq_theme.dart';

/// Shared wordmark used across authentication and application surfaces.
class NotiqBrand extends StatelessWidget {
  const NotiqBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconSize = compact ? 34.0 : 56.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [NotiqTheme.violet, Color(0xFF837BFF)],
            ),
            borderRadius: BorderRadius.circular(compact ? 11 : 17),
          ),
          child: Icon(
            Icons.forum_rounded,
            color: Colors.white,
            size: compact ? 19 : 30,
            semanticLabel: 'Notiq',
          ),
        ),
        SizedBox(width: compact ? 9 : 13),
        Text(
          'notiq.',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
            fontSize: compact ? 25 : 36,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
