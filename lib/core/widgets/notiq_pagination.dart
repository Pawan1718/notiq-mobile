import 'package:flutter/material.dart';

/// Page controls for the backend's one-based pagination contract.
class NotiqPagination extends StatelessWidget {
  const NotiqPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final lastPage = totalPages < 1 ? 1 : totalPages;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Previous page',
          onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Page $page of $lastPage'),
        IconButton(
          tooltip: 'Next page',
          onPressed: page < lastPage ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
