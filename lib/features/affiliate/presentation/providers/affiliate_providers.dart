import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api_client.dart';
import '../../data/models/affiliate_earnings.dart';
import '../../data/models/affiliate_marketing.dart';
import '../../data/models/affiliate_profile.dart';
import '../../data/services/affiliate_service.dart';
import '../../data/services/fallback_affiliate_service.dart';

/// Single injected data source for the affiliate module. Defaults to
/// [FallbackAffiliateService], which talks to the real backend and degrades
/// to bundled demo data on the first connectivity failure. Swap this one
/// line to force live-API or mock-only behaviour.
final affiliateServiceProvider = Provider<AffiliateService>((ref) {
  return FallbackAffiliateService(ref.watch(apiProvider));
});

/// Demo-mode flag for the top bar banner: true once the service has degraded
/// to local data for this session.
final affiliateDemoModeProvider = Provider<bool>((ref) {
  final service = ref.watch(affiliateServiceProvider);
  return service.isDemo;
});

final affiliateDemoReasonProvider = Provider<String?>((ref) {
  final service = ref.watch(affiliateServiceProvider);
  return service is FallbackAffiliateService ? service.fallbackReason : null;
});

// ---------- Profile & verification ----------

final affiliateProfileProvider = FutureProvider.autoDispose<AffiliateProfile>((ref) async {
  return ref.watch(affiliateServiceProvider).fetchProfile();
});

final affiliateVerificationProvider = FutureProvider.autoDispose<AffiliateVerification>((ref) async {
  return ref.watch(affiliateServiceProvider).fetchVerification();
});

// ---------- Dashboard ----------

final affiliateOverviewProvider = FutureProvider.autoDispose<AffiliateOverview>((ref) async {
  return ref.watch(affiliateServiceProvider).fetchOverview();
});

// ---------- Links ----------

final affiliateLinksProvider = FutureProvider.autoDispose<List<AffiliateLink>>((ref) async {
  return ref.watch(affiliateServiceProvider).fetchLinks();
});

// ---------- Sharing ----------

final affiliateProductsProvider = FutureProvider.autoDispose<List<PromotableProduct>>((ref) async {
  return ref.watch(affiliateServiceProvider).fetchPromotableProducts();
});

final affiliateCampaignsProvider = FutureProvider.autoDispose<List<AffiliateCampaign>>((ref) async {
  return ref.watch(affiliateServiceProvider).fetchCampaigns();
});

// ---------- Statistics ----------

final affiliateStatsProvider = FutureProvider.autoDispose.family<AffiliateStats, String>((ref, range) async {
  return ref.watch(affiliateServiceProvider).fetchStats(range: range);
});

// ---------- Earnings ----------

final affiliateWalletProvider = FutureProvider.autoDispose<AffiliateWallet>((ref) async {
  return ref.watch(affiliateServiceProvider).fetchWallet();
});

final affiliateCommissionsProvider = FutureProvider.autoDispose<List<AffiliateCommission>>((ref) async {
  return ref.watch(affiliateServiceProvider).fetchCommissions();
});

// ---------- Payouts ----------

final affiliatePayoutsProvider = FutureProvider.autoDispose<List<AffiliatePayout>>((ref) async {
  return ref.watch(affiliateServiceProvider).fetchPayouts();
});

// ---------- Notifications ----------

final affiliateNotificationsProvider = FutureProvider.autoDispose<List<AffiliateNotification>>((ref) async {
  return ref.watch(affiliateServiceProvider).fetchNotifications();
});

// ---------- Settings ----------

final affiliateSettingsProvider = FutureProvider.autoDispose<AffiliateSettings>((ref) async {
  return ref.watch(affiliateServiceProvider).fetchSettings();
});