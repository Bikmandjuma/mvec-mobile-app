import '../../../../core/api_client.dart';
import '../models/affiliate_earnings.dart';
import '../models/affiliate_marketing.dart';
import '../models/affiliate_profile.dart';
import 'affiliate_service.dart';

/// Backend-backed affiliate data source.
///
/// Endpoint paths mirror the web console's `src/API/affiliates.jsx` so both
/// clients hit the same routes. Parsing is deliberately tolerant (see the
/// `fromJson` factories) so renamed or newly added response fields do not
/// break the UI.
class ApiAffiliateService implements AffiliateService {
  ApiAffiliateService(this._api);

  final ApiClient _api;

  @override
  bool get isDemo => false;

  // ---------- Profile & verification ----------

  @override
  Future<AffiliateProfile> fetchProfile() async {
    final res = await _api.get('/affiliates/profile');
    return AffiliateProfile.fromJson(singleJson(res, ['affiliate', 'profile', 'user']));
  }

  @override
  Future<AffiliateProfile> updateProfile(AffiliateProfile draft) async {
    final res = await _api.patch('/affiliates/profile', body: draft.toUpdateJson());
    return AffiliateProfile.fromJson(singleJson(res, ['affiliate', 'profile', 'user']));
  }

  @override
  Future<AffiliateVerification> fetchVerification() async {
    final res = await _api.get('/affiliates/verification');
    return AffiliateVerification.fromJson(singleJson(res, ['verification']));
  }

  // ---------- Dashboard ----------

  @override
  Future<AffiliateOverview> fetchOverview() async {
    final res = await _api.get('/affiliates/overview');
    return AffiliateOverview.fromJson(res is Map ? Map<String, dynamic>.from(res) : const {});
  }

  // ---------- Referral links ----------

  @override
  Future<List<AffiliateLink>> fetchLinks() async {
    final res = await _api.get('/affiliates/links');
    return listJsonOf(res, AffiliateLink.fromJson);
  }

  @override
  Future<AffiliateLink> generateLink({String? productId, String? campaignId, String? label}) async {
    final res = await _api.post('/affiliates/links', body: {
      if (productId != null) 'productId': productId,
      if (campaignId != null) 'campaignId': campaignId,
      if (label != null && label.isNotEmpty) 'label': label,
    });
    return AffiliateLink.fromJson(singleJson(res, ['link', 'affiliateLink']));
  }

  @override
  Future<AffiliateLink> setLinkActive(String id, bool active) async {
    final res = await _api.patch('/affiliates/links/$id', body: {'isActive': active});
    return AffiliateLink.fromJson(singleJson(res, ['link', 'affiliateLink']));
  }

  @override
  Future<void> deleteLink(String id) async {
    await _api.delete('/affiliates/links/$id');
  }

  // ---------- Sharing ----------

  @override
  Future<List<PromotableProduct>> fetchPromotableProducts({String? search, String? campaignId}) async {
    final res = await _api.get('/products', query: {
      'page': '1',
      'limit': '60',
      'status': 'ACTIVE',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (campaignId != null) 'campaignId': campaignId,
    });
    return listJsonOf(res, PromotableProduct.fromJson);
  }

  @override
  Future<List<AffiliateCampaign>> fetchCampaigns() async {
    final res = await _api.get('/affiliates/campaigns', query: {'status': 'ACTIVE'});
    return listJsonOf(res, AffiliateCampaign.fromJson);
  }

  @override
  Future<AffiliateCampaign> joinCampaign(String id) async {
    final res = await _api.post('/affiliates/campaigns/$id/join');
    return AffiliateCampaign.fromJson(singleJson(res, ['campaign']));
  }

  // ---------- Statistics ----------

  @override
  Future<AffiliateStats> fetchStats({String range = '30d'}) async {
    final res = await _api.get('/affiliates/stats', query: {'range': range});
    return AffiliateStats.fromJson(res is Map ? Map<String, dynamic>.from(res) : const {});
  }

  // ---------- Earnings ----------

  @override
  Future<AffiliateWallet> fetchWallet() async {
    final res = await _api.get('/affiliates/wallet');
    return AffiliateWallet.fromJson(singleJson(res, ['wallet']));
  }

  @override
  Future<List<AffiliateCommission>> fetchCommissions({String? status}) async {
    final res = await _api.get('/affiliates/commissions', query: {
      'limit': '200',
      if (status != null) 'status': status,
    });
    return listJsonOf(res, AffiliateCommission.fromJson);
  }

  // ---------- Payouts ----------

  @override
  Future<List<AffiliatePayout>> fetchPayouts() async {
    final res = await _api.get('/affiliates/payouts');
    return listJsonOf(res, AffiliatePayout.fromJson);
  }

  @override
  Future<AffiliatePayout> requestPayout({
    required num amount,
    required String paymentMethod,
    required String accountName,
    required String phoneNumber,
    String? bankName,
  }) async {
    final res = await _api.post('/affiliates/payouts/request', body: {
      'amount': amount,
      'paymentMethod': paymentMethod,
      'accountDetails': {
        'phoneNumber': phoneNumber,
        'accountName': accountName,
        if (bankName != null && bankName.isNotEmpty) 'bankName': bankName,
      },
    });
    return AffiliatePayout.fromJson(singleJson(res, ['payout']));
  }

  // ---------- Notifications ----------

  @override
  Future<List<AffiliateNotification>> fetchNotifications() async {
    final res = await _api.get('/affiliates/notifications', query: {'limit': '100'});
    return listJsonOf(res, AffiliateNotification.fromJson);
  }

  @override
  Future<void> markNotificationsRead([String? id]) async {
    if (id == null) {
      await _api.post('/affiliates/notifications/read-all');
    } else {
      await _api.patch('/affiliates/notifications/$id/read');
    }
  }

  // ---------- Settings ----------

  @override
  Future<AffiliateSettings> fetchSettings() async {
    final res = await _api.get('/affiliates/settings');
    return AffiliateSettings.fromJson(singleJson(res, ['settings']));
  }

  @override
  Future<AffiliateSettings> updateSettings(AffiliateSettings settings) async {
    final res = await _api.patch('/affiliates/settings', body: settings.toJson());
    return AffiliateSettings.fromJson(singleJson(res, ['settings']));
  }
}
