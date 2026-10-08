import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notiq_mobile/core/theme/notiq_theme.dart';
import 'package:notiq_mobile/core/widgets/notiq_button.dart';
import 'package:notiq_mobile/core/widgets/notiq_page_state.dart';
import 'package:notiq_mobile/core/widgets/notiq_pagination.dart';
import 'package:notiq_mobile/core/widgets/notiq_status_badge.dart';

void main() {
  testWidgets('branded button disables interaction while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: NotiqTheme.light(),
      home: Scaffold(
        body: NotiqButton(
          label: 'Send',
          loading: true,
          onPressed: () => taps++,
        ),
      ),
    ));

    await tester.tap(find.text('Send'));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('pagination respects bounds and changes page', (tester) async {
    int? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotiqPagination(
          page: 1,
          totalPages: 3,
          onPageChanged: (page) => selected = page,
        ),
      ),
    ));

    final previous = find.byTooltip('Previous page');
    final next = find.byTooltip('Next page');
    expect(tester.widget<IconButton>(previous).onPressed, isNull);
    await tester.tap(next);
    expect(selected, 2);
    expect(find.text('Page 1 of 3'), findsOneWidget);
  });

  testWidgets('error state exposes retry action', (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotiqPageState.error(onRetry: () => retryCount++),
      ),
    ));
    await tester.tap(find.text('Retry'));
    expect(retryCount, 1);
  });

  testWidgets('status badge renders backend supplied label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: NotiqStatusBadge(
          label: 'Delivered',
          tone: NotiqStatusTone.success,
        ),
      ),
    ));
    expect(find.text('Delivered'), findsOneWidget);
  });

  testWidgets('dark theme renders shared components', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: NotiqTheme.darkTheme(),
      home: const Scaffold(body: NotiqStatusBadge(label: 'Pending')),
    ));
    expect(find.text('Pending'), findsOneWidget);
  });
}
