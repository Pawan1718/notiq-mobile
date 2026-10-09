import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_response.dart';

const campaignBase = '/api/communication/bulk';

Map<String, dynamic> objectMap(Object? value) =>
    Map<String, dynamic>.from(value as Map);

int number(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
bool flag(Map<String, dynamic> json, String key) => json[key] == true;

class CampaignItem {
  const CampaignItem(this.raw);
  final Map<String, dynamic> raw;
  int get id => number(raw['id']);
  String get name => (raw['name'] ?? 'Campaign').toString();
  String get status => (raw['status'] ?? 'Unknown').toString();
  int get total => number(raw['totalRecipients']);
  int get sent => number(raw['sentCount']);
  int get failed => number(raw['failedCount']);
  factory CampaignItem.fromJson(Object? value) =>
      CampaignItem(objectMap(value));
}

class CampaignPage {
  const CampaignPage(this.items, this.totalPages);
  final List<CampaignItem> items;
  final int totalPages;
  factory CampaignPage.fromJson(Object? value) {
    final raw = objectMap(value);
    return CampaignPage(
      (raw['items'] as List? ?? const []).map(CampaignItem.fromJson).toList(),
      number(raw['totalPages']),
    );
  }
}

class CampaignDetail {
  const CampaignDetail(this.raw);
  final Map<String, dynamic> raw;
  int get id => number(raw['id']);
  String get name => (raw['name'] ?? '').toString();
  String get status => (raw['status'] ?? '').toString();
  bool get isDraft => flag(raw, 'isDraft');
  bool get canPublish => flag(raw, 'canPublishDraft');
  bool get canEditDraft => flag(raw, 'canEditDraft');
  bool get canDeleteDraft => flag(raw, 'canDeleteDraft');
  bool get canDuplicate => flag(raw, 'canDuplicate');
  bool get canCancel => flag(raw, 'canCancel');
  bool get canRetry => flag(raw, 'canRetryFailed');
  bool get canReschedule => flag(raw, 'canReschedule');
  factory CampaignDetail.fromJson(Object? value) =>
      CampaignDetail(objectMap(value));
}

class RecipientReport {
  const RecipientReport(this.raw);
  final Map<String, dynamic> raw;
  Map<String, dynamic> get summary => objectMap(raw['summary']);
  List<Map<String, dynamic>> get recipients =>
      (objectMap(raw['recipients'])['items'] as List? ?? const [])
          .map(objectMap)
          .toList();
  int get totalPages => number(objectMap(raw['recipients'])['totalPages']);
  factory RecipientReport.fromJson(Object? value) =>
      RecipientReport(objectMap(value));
}

class CampaignRepository {
  CampaignRepository(this._api);
  final ApiClient _api;
  Future<List<Map<String, dynamic>>> lookup(String path) async {
    final result = await _api.get<List<Map<String, dynamic>>>(
      path,
      (value) => (value as List<dynamic>)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList(),
    );
    return result.data ?? const [];
  }

  Future<CampaignPage> list({int page = 1, String search = ''}) async {
    final query = Uri(queryParameters: {
      'pageNumber': '$page',
      'pageSize': '20',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    }).query;
    final result = await _api.get<CampaignPage>(
        '$campaignBase/campaigns?$query', CampaignPage.fromJson);
    if (result.data == null) {
      throw const FormatException('Campaign list missing');
    }
    return result.data!;
  }

  Future<CampaignDetail> detail(int id) async {
    final result = await _api.get<CampaignDetail>(
        '$campaignBase/campaigns/$id', CampaignDetail.fromJson);
    if (result.data == null) {
      throw const FormatException('Campaign detail missing');
    }
    return result.data!;
  }

  Future<RecipientReport> recipients(int id, {int page = 1}) async {
    final result = await _api.get<RecipientReport>(
        '$campaignBase/campaigns/$id/recipients?pageNumber=$page&pageSize=20',
        RecipientReport.fromJson);
    if (result.data == null) throw const FormatException('Recipients missing');
    return result.data!;
  }

  Future<void> action(int id, String suffix,
      {Map<String, dynamic>? body, String method = 'POST'}) async {
    await _api.mutate<Object?>(
        '$campaignBase/campaigns/$id/$suffix', method, (v) => v,
        payload: body);
  }

  Future<Map<String, dynamic>> uploadAttachment({
    required int channel,
    required String name,
    required List<int> bytes,
  }) async {
    final file = MultipartFile.fromBytes(bytes, filename: name);
    final response = await _api.dio.post<Object?>(
      '/api/communication/uploads/attachment',
      data: FormData.fromMap({'channel': channel, 'file': file}),
    );
    if (response.data is! Map<String, dynamic>) {
      throw const ApiFailure('Unexpected upload response');
    }
    final result = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data! as Map<String, dynamic>,
      (value) => Map<String, dynamic>.from(value as Map),
    );
    if ((response.statusCode ?? 500) >= 400 || !result.success ||
        result.data == null) {
      throw ApiFailure(result.message.isNotEmpty
          ? result.message : 'Attachment upload failed');
    }
    return result.data!;
  }

  Future<void> saveDraft(Map<String, dynamic> payload, {int? id}) async {
    await _api.mutate<Object?>(
        id == null
            ? '$campaignBase/drafts'
            : '$campaignBase/campaigns/$id/draft',
        id == null ? 'POST' : 'PUT',
        (v) => v,
        payload: payload);
  }
}

final campaignRepositoryProvider = Provider<CampaignRepository>(
  (ref) => CampaignRepository(ref.read(apiClientProvider)),
);
final campaignsProvider = FutureProvider.autoDispose
    .family<CampaignPage, ({int page, String search})>(
  (ref, filter) => ref
      .read(campaignRepositoryProvider)
      .list(page: filter.page, search: filter.search),
);
final campaignDetailProvider =
    FutureProvider.autoDispose.family<CampaignDetail, int>(
  (ref, id) => ref.read(campaignRepositoryProvider).detail(id),
);
final campaignRecipientsProvider =
    FutureProvider.autoDispose.family<RecipientReport, ({int id, int page})>(
  (ref, args) =>
      ref.read(campaignRepositoryProvider).recipients(args.id, page: args.page),
);

final campaignGroupsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.read(campaignRepositoryProvider).lookup('/api/communication/contacts/groups'),
);
final campaignProvidersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.read(campaignRepositoryProvider).lookup('/api/communication/provider-settings'),
);
final campaignTemplatesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.read(campaignRepositoryProvider).lookup('/api/communication/templates'),
);
