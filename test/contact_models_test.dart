import 'package:flutter_test/flutter_test.dart';
import 'package:notiq_mobile/features/contacts/contact_models.dart';

void main() {
  test('Inactive contact detail preserves status and consent', () {
    final contact = ContactDetail.fromJson({
      'id': 42, 'name': 'Inactive', 'isActive': false,
      'isSmsAllowed': false, 'isWhatsAppAllowed': false,
      'isEmailAllowed': false, 'groupIds': <int>[], 'tagIds': <int>[],
    });
    expect(contact.active, isFalse);
    expect(contact.smsAllowed, isFalse);
    expect(contact.whatsappAllowed, isFalse);
    expect(contact.emailAllowed, isFalse);
  });

  test('Existing active contact and groups parse unchanged', () {
    final contact = ContactDetail.fromJson({
      'id': 7, 'name': 'Active', 'isActive': true,
      'isSmsAllowed': true, 'isWhatsAppAllowed': false,
      'isEmailAllowed': true, 'groupIds': [2], 'tagIds': [5],
    });
    expect(contact.active, isTrue);
    expect(contact.smsAllowed, isTrue);
    expect(contact.whatsappAllowed, isFalse);
    expect(contact.emailAllowed, isTrue);
    expect(contact.groupIds, [2]);
    expect(contact.tagIds, [5]);
  });
}
