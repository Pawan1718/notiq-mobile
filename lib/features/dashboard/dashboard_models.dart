class DashboardMetrics {
  const DashboardMetrics({
    required this.total,
    required this.pending,
    required this.scheduled,
    required this.sent,
    required this.failed,
    required this.retriableFailed,
    required this.channelStats,
    required this.recentLogs,
  });

  final int total;
  final int pending;
  final int scheduled;
  final int sent;
  final int failed;
  final int retriableFailed;
  final List<DashboardChannelStat> channelStats;
  final List<DashboardRecentLog> recentLogs;

  factory DashboardMetrics.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid dashboard payload.');
    }
    int number(String key) {
      final v = value[key];
      if (v is! num) throw FormatException('Missing dashboard metric: $key');
      return v.toInt();
    }

    List<T> entries<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = value[key];
      if (raw == null) return <T>[];
      if (raw is! List) throw FormatException('Invalid $key.');
      return raw.map((item) {
        if (item is! Map<String, dynamic>) {
          throw FormatException('Invalid $key entry.');
        }
        return parse(item);
      }).toList(growable: false);
    }

    return DashboardMetrics(
      total: number('total'),
      pending: number('pending'),
      scheduled: number('scheduled'),
      sent: number('sent'),
      failed: number('failed'),
      retriableFailed: number('retriableFailed'),
      channelStats: entries('channelStats', DashboardChannelStat.fromJson),
      recentLogs: entries('recentLogs', DashboardRecentLog.fromJson),
    );
  }
}

class DashboardChannelStat {
  const DashboardChannelStat({
    required this.channel,
    required this.total,
    required this.sent,
    required this.failed,
  });

  final String channel;
  final int total;
  final int sent;
  final int failed;

  factory DashboardChannelStat.fromJson(Map<String, dynamic> json) =>
      DashboardChannelStat(
        channel: _channelLabel(json['channel']),
        total: (json['total'] as num?)?.toInt() ?? 0,
        sent: (json['sent'] as num?)?.toInt() ?? 0,
        failed: (json['failed'] as num?)?.toInt() ?? 0,
      );
}

class DashboardRecentLog {
  const DashboardRecentLog({
    required this.id,
    required this.channel,
    required this.status,
    required this.recipientName,
    required this.recipientAddress,
    required this.createdAt,
  });

  final int id;
  final String channel;
  final String status;
  final String recipientName;
  final String recipientAddress;
  final DateTime? createdAt;

  factory DashboardRecentLog.fromJson(Map<String, dynamic> json) =>
      DashboardRecentLog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        channel: _channelLabel(json['channel']),
        status: _statusLabel(json['status']),
        recipientName: json['recipientName']?.toString() ?? '',
        recipientAddress: json['recipientAddress']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

String _channelLabel(Object? value) {
  final key = value.toString().toLowerCase();
  switch (key) {
    case '1':
    case 'inapp':
      return 'In-app';
    case '2':
    case 'email':
      return 'Email';
    case '3':
    case 'sms':
      return 'SMS';
    case '4':
    case 'whatsapp':
      return 'WhatsApp';
    default:
      return value?.toString() ?? 'Other';
  }
}

String _statusLabel(Object? value) {
  const statuses = {
    '1': 'Draft',
    '2': 'Queued',
    '3': 'Scheduled',
    '4': 'Sent',
    '5': 'Delivered',
    '6': 'Failed',
    '7': 'Cancelled',
    '8': 'Read',
    '9': 'Processing',
  };
  final key = value.toString().toLowerCase();
  return statuses[key] ??
      (key.isEmpty ? 'Unknown' : '${key[0].toUpperCase()}${key.substring(1)}');
}
