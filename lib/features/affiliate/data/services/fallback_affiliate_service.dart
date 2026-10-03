import 'package:dio/dio.dart';

import '../../../../core/api_client.dart';
import '../../../../core/api_config.dart';
import '../models/affiliate_earnings.dart';
import '../models/affiliate_marketing.dart';
import '../models/affiliate_profile.dart';
import 'affiliate_service.dart';
import 'api_affiliate_service.dart';
import 'mock_affiliate_service.dart';

/// Data source that prefers the real backend and transparently falls back to
/// bundled demo data when the API cannot be reached.
///
/// This is the default service for the affiliate module, so the same build
/// works the day the affiliate endpoints ship and today, when there is no
/// backend running — no environment flags, no manual wiring.
///
/// Degradation is sticky for the session: the first unreachable-endpoint
/// failure switches to the mock store and stays there, so a single flaky
/// request cannot split the UI between two sources.
///
/// When [kDemoMode] is on (or [forceDemo] is passed), the API is never
/// touched and demo data is used immediately, so the module works fully
/// offline without waiting on connection timeouts.
class FallbackAffiliateService implements AffiliateService {
  FallbackAffiliateService(ApiClient api, {AffiliateService? fallback, bool? forceDemo})
      : _api = ApiAffiliateService(api),
        _fallback = fallback ?? MockAffiliateService(),
        _forceDemo = forceDemo ?? kDemoMode {
    if (_forceDemo) {
      _degraded = true;
      lastFallbackReason = 'Demo mode — using bundled data.';
    }
  }

  final ApiAffiliateService _api;
  final AffiliateService _fallback;
  final bool _forceDemo;
  bool _degraded = false;

  /// Human-readable reason for the last fallback, shown in a small banner.
  String? lastFallbackReason;

  @override
  bool get isDemo => _degraded && _fallback.isDemo;

  /// The most recent unreachable-endpoint problem, if any.
  String? get fallbackReason => lastFallbackReason;

  /// Runs [call] against the live API; on a connectivity / not-implemented
  /// error, switches to the demo store and reports [sourceLabel] to the caller.
  Future<T> _resolve<T>(Future<T> Function(AffiliateService s) call, {required String sourceLabel}) async {
    if (_degraded) return call(_fallback);
    try {
      return await call(_api);
    } catch (e) {
      if (_isUnreachable(e)) {
        _degraded = true;
        lastFallbackReason = _reason(e);
        return call(_fallback);
      }
      rethrow;
    }
  }

  /// Connection failures (`statusCode == null`) and "module not shipped"
  /// responses (404 / 501) trigger demo mode. Genuine client/server errors on
  /// a live endpoint keep throwing so the UI can surface them.
  ///
  /// Note: [ApiClient] rejects with a `DioException` whose `.error` carries
  /// the `ApiException`, so both shapes are unwrapped here.
  bool _isUnreachable(Object e) {
    if (e is ApiException) {
      return e.statusCode == null || e.statusCode == 404 || e.statusCode == 501;
    }
    if (e is DioException) {
      final nested = e.error;
      if (nested is ApiException) return _isUnreachable(nested);
      final code = e.response?.statusCode;
      return code == null || code == 404 || code == 501;
    }
    return false;
  }

  String _reason(Object e) {
    int? code;
    if (e is ApiException) {
      code = e.statusCode;
    } else if (e is DioException) {
      final nested = e.error;
      code = nested is ApiException ? nested.statusCode : e.response?.statusCode;
    }
    if (code == 404 || code == 501) return 'Affiliate API not available yet — showing demo data.';
    return 'Cannot reach the API — showing demo data.';
  }

  @override
  Future<AffiliateProfile> fetchProfile() => _resolve((s) => s.fetchProfile(), sourceLabel: 'profile');

  @override
  Future<AffiliateProfile> updateProfile(AffiliateProfile draft) => _resolve((s) => s.updateProfile(draft), sourceLabel: 'profile');

  @override
  Future<AffiliateVerification> fetchVerification() => _resolve((s) => s.fetchVerification(), sourceLabel: 'verification');

  @override
  Future<AffiliateOverview> fetchOverview() => _resolve((s) => s.fetchOverview(), sourceLabel: 'overview');

  @override
  Future<List<AffiliateLink>> fetchLinks() => _resolve((s) => s.fetchLinks(), sourceLabel: 'links');

  @override
  Future<AffiliateLink> generateLink({String? productId, String? campaignId, String? label}) =>
      _resolve((s) => s.generateLink(productId: productId, campaignId: campaignId, label: label), sourceLabel: 'links');

  @override
  Future<AffiliateLink> setLinkActive(String id, bool active) => _resolve((s) => s.setLinkActive(id, active), sourceLabel: 'links');

  @override
  Future<void> deleteLink(String id) => _resolve((s) => s.deleteLink(id), sourceLabel: 'links');

  @override
  Future<List<PromotableProduct>> fetchPromotableProducts({String? search, String? campaignId}) =>
      _resolve((s) => s.fetchPromotableProducts(search: search, campaignId: campaignId), sourceLabel: 'products');

  @override
  Future<List<AffiliateCampaign>> fetchCampaigns() => _resolve((s) => s.fetchCampaigns(), sourceLabel: 'campaigns');

  @override
  Future<AffiliateCampaign> joinCampaign(String id) => _resolve((s) => s.joinCampaign(id), sourceLabel: 'campaigns');

  @override
  Future<AffiliateStats> fetchStats({String range = '30d'}) => _resolve((s) => s.fetchStats(range: range), sourceLabel: 'stats');

  @override
  Future<AffiliateWallet> fetchWallet() => _resolve((s) => s.fetchWallet(), sourceLabel: 'wallet');

  @override
  Future<List<AffiliateCommission>> fetchCommissions({String? status}) => _resolve((s) => s.fetchCommissions(status: status), sourceLabel: 'commissions');

  @override
  Future<List<AffiliatePayout>> fetchPayouts() => _resolve((s) => s.fetchPayouts(), sourceLabel: 'payouts');

  @override
  Future<AffiliatePayout> requestPayout({required num amount, required String paymentMethod, required String accountName, required String phoneNumber, String? bankName}) =>
      _resolve(
        (s) => s.requestPayout(amount: amount, paymentMethod: paymentMethod, accountName: accountName, phoneNumber: phoneNumber, bankName: bankName),
        sourceLabel: 'payouts',
      );

  @override
  Future<List<AffiliateNotification>> fetchNotifications() => _resolve((s) => s.fetchNotifications(), sourceLabel: 'notifications');

  @override
  Future<void> markNotificationsRead([String? id]) => _resolve((s) => s.markNotificationsRead(id), sourceLabel: 'notifications');

  @override
  Future<AffiliateSettings> fetchSettings() => _resolve((s) => s.fetchSettings(), sourceLabel: 'settings');

  @override
  Future<AffiliateSettings> updateSettings(AffiliateSettings settings) => _resolve((s) => s.updateSettings(settings), sourceLabel: 'settings');
}