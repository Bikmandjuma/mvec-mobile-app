import '../core/api_client.dart';
import '../models/catalog.dart';
import '../models/party.dart';

class FinanceService {
  FinanceService(this._api);
  final ApiClient _api;

  // ---------- Ledger ----------
  Future<Paged<LedgerEntry>> ledger({int page = 1, int limit = 20, String? entryType}) async {
    final res = await _api.get('/admin/ledger', query: {
      'page': page,
      'limit': limit,
      if (entryType != null) 'entryType': entryType,
    });
    return Paged.parse(res, LedgerEntry.fromJson);
  }

  Future<void> holdSettlement(String id, String reason) async {
    await _api.patch('/admin/settlements/$id/hold', body: {'reason': reason});
  }

  Future<void> releaseSettlement(String id) async {
    await _api.post('/admin/settlements/$id/release');
  }

  // ---------- Commissions ----------
  Future<List<CommissionRule>> commissions() async {
    final res = await _api.get('/admin/commissions');
    return listJson(res, ['commissions', 'data']).map(CommissionRule.fromJson).toList();
  }

  Future<void> createCommission(Map<String, dynamic> body) async {
    await _api.post('/admin/commissions', body: body);
  }

  Future<void> toggleCommission(String id) async {
    await _api.patch('/admin/commissions/$id/toggle');
  }

  // ---------- Payouts / wallet ----------
  Future<Map<String, dynamic>> adminBalance() async {
    final res = await _api.get('/admin/payouts/balance');
    return res is Map ? Map<String, dynamic>.from(res) : {};
  }

  Future<List<PayoutRecord>> adminPayoutHistory({int page = 1, int limit = 20}) async {
    final res = await _api.get('/admin/payouts/history', query: {'page': page, 'limit': limit});
    return listJson(res, ['data', 'payouts', 'history']).map(PayoutRecord.fromJson).toList();
  }

  // ---------- Subscriptions / ads ----------
  Future<List<SubscriptionRecord>> subscriptions() async {
    final res = await _api.get('/admin/subscriptions');
    return listJson(res, ['data', 'subscriptions']).map(SubscriptionRecord.fromJson).toList();
  }

  Future<void> patchSubscription(String id, String status) async {
    await _api.patch('/admin/subscriptions/$id/status', body: {'status': status});
  }

  Future<List<SubscriptionRecord>> buyerSubscriptions() async {
    final res = await _api.get('/admin/buyer-subscriptions');
    return listJson(res, ['data', 'subscriptions']).map(SubscriptionRecord.fromJson).toList();
  }

  Future<List<AdvertisementRecord>> advertisements() async {
    final res = await _api.get('/admin/advertisements');
    return listJson(res, ['data', 'advertisements']).map(AdvertisementRecord.fromJson).toList();
  }

  Future<void> patchAdvertisement(String id, String status) async {
    await _api.patch('/admin/advertisements/$id/status', body: {'status': status});
  }

  // ---------- Reports ----------
  Future<ReportSummary> reportSummary(String range) async {
    final res = await _api.get('/reports/summary', query: {'range': range});
    final metrics = res is Map && res['metrics'] is Map ? Map<String, dynamic>.from(res['metrics']) : <String, dynamic>{};
    return ReportSummary.fromMetrics(metrics);
  }

  Future<RevenueSeries> reportRevenue(String range) async {
    final res = await _api.get('/reports/revenue', query: {'range': range});
    return RevenueSeries.fromJson(res is Map ? Map<String, dynamic>.from(res) : {});
  }

  // ---------- Reviews ----------
  Future<List<ReviewRecord>> reviews() async {
    final res = await _api.get('/reviews');
    return listJson(res, ['data', 'reviews']).map(ReviewRecord.fromJson).toList();
  }
}

class PlatformService {
  PlatformService(this._api);
  final ApiClient _api;

  Future<List<DisputeRecord>> disputes({int page = 1, int limit = 50, String? status}) async {
    final res = await _api.get('/disputes', query: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    });
    return listJson(res, ['data', 'disputes']).map(DisputeRecord.fromJson).toList();
  }

  Future<void> arbitrateDispute(
    String id, {
    required String decision,
    num? buyerRefundAmount,
    num? vendorReleaseAmount,
    String? notes,
  }) async {
    await _api.post('/disputes/$id/arbitrate', body: {
      'decision': decision,
      if (buyerRefundAmount != null) 'buyerRefundAmount': buyerRefundAmount,
      if (vendorReleaseAmount != null) 'vendorReleaseAmount': vendorReleaseAmount,
      if (notes != null) 'notes': notes,
    });
  }

  Future<List<SupportCase>> supportCases({String? status}) async {
    final res = await _api.get('/support/cases', query: {if (status != null) 'status': status});
    return listJson(res, ['cases', 'data']).map(SupportCase.fromJson).toList();
  }

  Future<void> patchSupportCase(String id, String status) async {
    await _api.patch('/support/cases/$id/status', body: {'status': status});
  }

  Future<List<NotificationRecord>> notifications() async {
    final res = await _api.get('/notifications', query: {'limit': '200'});
    return listJson(res, ['data', 'notifications']).map(NotificationRecord.fromJson).toList();
  }

  Future<void> markAllRead() async {
    await _api.post('/notifications/read-all');
  }

  Future<List<ConversationRecord>> conversations() async {
    final res = await _api.get('/conversations');
    return listJson(res, ['conversations', 'data']).map(ConversationRecord.fromJson).toList();
  }

  Future<List<MessageRecord>> conversationMessages(String id, {String? myId}) async {
    final res = await _api.get('/conversations/$id/messages');
    return listJson(res, ['messages', 'data']).map((e) => MessageRecord.fromJson(e, myId)).toList();
  }

  Future<void> sendMessage(String id, String body) async {
    await _api.post('/conversations/$id/messages', body: {'body': body});
  }

  // ---------- Translations / languages ----------
  Future<List<TranslationRecord>> translations({String? module}) async {
    final res = await _api.get('/admin/translations', query: {
      'limit': '500',
      if (module != null) 'module': module,
    });
    return listJson(res, ['data', 'translations']).map(TranslationRecord.fromJson).toList();
  }

  Future<void> upsertTranslation(String key, String module, Map<String, String> t) async {
    await _api.post('/admin/translations', body: {
      'key': key,
      'module': module,
      'translations': t,
    });
  }

  Future<List<Map<String, dynamic>>> abuseReports() async {
    final res = await _api.get('/abuse-reports');
    return listJson(res, ['data', 'reports']);
  }

  Future<void> patchAbuseReport(String id, String status, {String? notes}) async {
    await _api.patch('/abuse-reports/$id', body: {
      'status': status,
      if (notes != null) 'adminNotes': notes,
    });
  }

  Future<List<Map<String, dynamic>>> promotions() async {
    final res = await _api.get('/promotions');
    return listJson(res, ['data', 'promotions']);
  }

  Future<List<Map<String, dynamic>>> shippingZones() async {
    final res = await _api.get('/shipping/zones');
    return listJson(res, ['data', 'zones']);
  }
}