import 'package:flutter_test/flutter_test.dart';
import 'package:notiq_mobile/features/inbox/inbox_models.dart';

void main() {
  test('Parses paginated inbox envelope', () {
    final page = InboxPageResult.fromJson({
      'items': [{'id': 5, 'contactName': 'Test', 'phoneNumber': '123',
        'lastMessagePreview': 'Hi', 'unreadCount': 2}],
      'totalPages': 3,
    });
    expect(page.items.single.id, 5);
    expect(page.items.single.unreadCount, 2);
    expect(page.totalPages, 3);
  });
}
