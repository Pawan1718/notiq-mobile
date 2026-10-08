import 'package:flutter_test/flutter_test.dart';
import 'package:notiq_mobile/features/campaigns/campaign_repository.dart';

void main() {
  test('campaign list matches backend payload', () {
    final page = CampaignPage.fromJson({
      'items': [{'id': 7, 'name': 'Fall', 'status': 'Scheduled',
        'totalRecipients': 10, 'sentCount': 0, 'failedCount': 0}],
      'totalPages': 2,
    });
    expect(page.items.single.name, 'Fall');
    expect(page.items.single.status, 'Scheduled');
    expect(page.items.single.total, 10);
    expect(page.totalPages, 2);
  });
  test('server permissions drive campaign actions', () {
    final detail = CampaignDetail.fromJson({
      'id': 7, 'name': 'Fall', 'status': 'Draft', 'isDraft': true,
      'canPublishDraft': true, 'canCancel': false, 'canEditDraft': true,
    });
    expect(detail.canPublish, true);
    expect(detail.canCancel, false);
    expect(detail.canEditDraft, true);
  });
  test('recipient reports respect nested page envelope', () {
    final report = RecipientReport.fromJson({
      'summary': {'total': 3, 'failed': 1},
      'recipients': {
        'items': [{'recipientName': 'Test', 'recipientAddress': '100', 'status': 1}],
        'totalPages': 2,
      },
    });
    expect(report.recipients.length, 1);
    expect(report.totalPages, 2);
    expect(number(report.summary['failed']), 1);
  });
}
