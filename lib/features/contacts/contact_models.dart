class ContactItem {
  const ContactItem(
      {required this.id,
      required this.name,
      required this.mobile,
      required this.whatsapp,
      required this.email,
      required this.active});
  final int id;
  final String name;
  final String mobile;
  final String whatsapp;
  final String email;
  final bool active;
  factory ContactItem.fromJson(Object? raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return ContactItem(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        mobile: json['mobileNumber']?.toString() ?? '',
        whatsapp: json['whatsAppNumber']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        active: json['isActive'] == true);
  }
}

class ContactPage {
  const ContactPage(this.items, this.totalPages);
  final List<ContactItem> items;
  final int totalPages;
  factory ContactPage.fromJson(Object? raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return ContactPage(
        (json['items'] as List).map(ContactItem.fromJson).toList(),
        (json['totalPages'] as num?)?.toInt() ?? 1);
  }
}

class ContactDetail {
  const ContactDetail(
      {required this.id,
      required this.name,
      required this.mobile,
      required this.whatsapp,
      required this.email,
      required this.smsAllowed,
      required this.whatsappAllowed,
      required this.emailAllowed,
      required this.active,
      required this.groupIds,
      required this.tagIds});
  final int id;
  final String name, mobile, whatsapp, email;
  final bool smsAllowed, whatsappAllowed, emailAllowed, active;
  final List<int> groupIds, tagIds;
  factory ContactDetail.fromJson(Object? raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    List<int> ids(String key) =>
        (json[key] as List? ?? []).map((x) => (x as num).toInt()).toList();
    return ContactDetail(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        mobile: json['mobileNumber']?.toString() ?? '',
        whatsapp: json['whatsAppNumber']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        smsAllowed: json['isSmsAllowed'] == true,
        whatsappAllowed: json['isWhatsAppAllowed'] == true,
        emailAllowed: json['isEmailAllowed'] == true,
        active: json['isActive'] == true,
        groupIds: ids('groupIds'),
        tagIds: ids('tagIds'));
  }
}
