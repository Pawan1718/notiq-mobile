class DashboardMetrics {
  const DashboardMetrics(
      {required this.total,
      required this.pending,
      required this.scheduled,
      required this.sent,
      required this.failed,
      required this.retriableFailed});

  final int total;
  final int pending;
  final int scheduled;
  final int sent;
  final int failed;
  final int retriableFailed;

  factory DashboardMetrics.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid dashboard payload.');
    }
    int number(String key) {
      final v = value[key];
      if (v is! num) throw FormatException('Missing dashboard metric: $key');
      return v.toInt();
    }

    return DashboardMetrics(
      total: number('total'),
      pending: number('pending'),
      scheduled: number('scheduled'),
      sent: number('sent'),
      failed: number('failed'),
      retriableFailed: number('retriableFailed'),
    );
  }
}
