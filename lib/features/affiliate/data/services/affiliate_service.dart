import '../models/affiliate_earnings.dart';
import '../models/affiliate_marketing.dart';
import '../models/affiliate_profile.dart';

/// Data source contract for the whole affiliate module.
///
/// Two implementations exist — [ApiAffiliateService] (the real MVEC backend)
/// and [MockAffiliateService] (local demo data) — and the presentation layer
/// only ever sees this interface, so wiring the module to the live API is a
/// one-line provider change with no widget edits.
abstract class AffiliateService {
  /// True when responses come from bundled demo data rather than the backend.
  bool get isDemo;

  // ---------- Profile & verification ----------
  Future<AffiliateProfile> fetchProfile();

  /// Sends only the editable fields; returns the saved profile.
  Future<AffiliateProfile> updateProfile(AffiliateProfile draft);

  /// Full verification record (submitted documents, reviewer notes).
  Future<AffiliateVerification> fetchVerification();

  // ---------- Dashboard ----------
  /// One aggregated call for the overview screen.
  Future<AffiliateOverview> fetchOverview();

  // ---------- Referral links ----------
  Future<List<AffiliateLink>> fetchLinks();

  /// Creates a link for a product, a campaign, or a bare general link.
  Future<AffiliateLink> generateLink({String? productId, String? campaignId, String? label});

  /// Enables or disables an existing link without losing its statistics.
  Future<AffiliateLink> setLinkActive(String id, bool active);

  Future<void> deleteLink(String id);

  // ---------- Sharing ----------
  Future<List<PromotableProduct>> fetchPromotableProducts({String? search, String? campaignId});

  Future<List<AffiliateCampaign>> fetchCampaigns();

  /// Joins a campaign so its commission rate applies to generated links.
  Future<AffiliateCampaign> joinCampaign(String id);

  // ---------- Statistics ----------
  /// Clicks, registrations and conversions. [range] is `7d` | `30d` | `90d`.
  Future<AffiliateStats> fetchStats({String range = '30d'});

  // ---------- Earnings ----------
  Future<AffiliateWallet> fetchWallet();

  Future<List<AffiliateCommission>> fetchCommissions({String? status});

  // ---------- Payouts ----------
  Future<List<AffiliatePayout>> fetchPayouts();

  /// Requests a withdrawal. The backend enforces the 10,000 RWF minimum.
  Future<AffiliatePayout> requestPayout({required num amount, required String paymentMethod, required String accountName, required String phoneNumber, String? bankName});

  // ---------- Notifications ----------
  Future<List<AffiliateNotification>> fetchNotifications();

  Future<void> markNotificationsRead([String? id]);

  // ---------- Settings ----------
  Future<AffiliateSettings> fetchSettings();

  Future<AffiliateSettings> updateSettings(AffiliateSettings settings);
}
