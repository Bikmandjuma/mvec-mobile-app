import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/catalog.dart';
import '../models/party.dart';
import '../models/user.dart';
import '../services/admin_service.dart';
import '../services/platform_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService(ref.watch(apiProvider)));
final financeServiceProvider = Provider<FinanceService>((ref) => FinanceService(ref.watch(apiProvider)));
final platformServiceProvider = Provider<PlatformService>((ref) => PlatformService(ref.watch(apiProvider)));

/// Simple parameter-less autoDispose list providers (backend-backed).
final usersProvider = FutureProvider.autoDispose<List<UserRecord>>((ref) async {
  final p = await ref.watch(adminServiceProvider).users(limit: 100);
  return p.items;
});

/// Buyer management: all records whose role maps to a buyer.
final buyersProvider = FutureProvider.autoDispose<List<UserRecord>>((ref) async {
  final p = await ref.watch(adminServiceProvider).users(role: 'buyer', limit: 100);
  final items = p.items;
  if (items.isNotEmpty) return items;
  final all = await ref.watch(adminServiceProvider).users(limit: 100);
  return all.items.where((u) {
    final r = (u.role ?? '').toLowerCase();
    return r.contains('buyer') || (!r.contains('vendor') && !r.contains('supplier') && !r.contains('affiliate') && !r.contains('admin'));
  }).toList();
});

class PartyQuery {
  const PartyQuery({this.page = 1, this.status, this.verification, this.search});
  final int page;
  final String? status;
  final String? verification;
  final String? search;
}

final vendorsProvider = FutureProvider.autoDispose.family<Paged<PartyRecord>, PartyQuery>(
  (ref, q) => ref.watch(adminServiceProvider).vendors(page: q.page, status: q.status, verificationStatus: q.verification),
);

final suppliersProvider = FutureProvider.autoDispose.family<Paged<PartyRecord>, PartyQuery>(
  (ref, q) => ref.watch(adminServiceProvider).suppliers(page: q.page, status: q.status, verificationStatus: q.verification),
);

final affiliatesProvider = FutureProvider.autoDispose<List<PartyRecord>>(
  (ref) => ref.watch(adminServiceProvider).affiliates(),
);

final categoriesProvider = FutureProvider.autoDispose<List<CategoryRecord>>(
  (ref) => ref.watch(adminServiceProvider).categories(),
);

final productsProvider = FutureProvider.autoDispose<List<ProductRecord>>(
  (ref) => ref.watch(adminServiceProvider).products(limit: 100),
);

final ordersProvider = FutureProvider.autoDispose<List<OrderRecord>>(
  (ref) => ref.watch(adminServiceProvider).orders(),
);

final ledgerProvider = FutureProvider.autoDispose.family<Paged<LedgerEntry>, PartyQuery>(
  (ref, q) => ref.watch(financeServiceProvider).ledger(page: q.page, entryType: q.status),
);

final commissionsProvider = FutureProvider.autoDispose<List<CommissionRule>>(
  (ref) => ref.watch(financeServiceProvider).commissions(),
);

final affiliatePayoutsProvider = FutureProvider.autoDispose<List<PayoutRecord>>(
  (ref) => ref.watch(adminServiceProvider).affiliatePayouts(),
);

final adminPayoutsProvider = FutureProvider.autoDispose<List<PayoutRecord>>(
  (ref) => ref.watch(financeServiceProvider).adminPayoutHistory(limit: 100),
);

final subscriptionsProvider = FutureProvider.autoDispose<List<SubscriptionRecord>>(
  (ref) => ref.watch(financeServiceProvider).subscriptions(),
);

final buyerSubscriptionsProvider = FutureProvider.autoDispose<List<SubscriptionRecord>>(
  (ref) => ref.watch(financeServiceProvider).buyerSubscriptions(),
);

final advertisementsProvider = FutureProvider.autoDispose<List<AdvertisementRecord>>(
  (ref) => ref.watch(financeServiceProvider).advertisements(),
);

final reportSummaryProvider = FutureProvider.autoDispose.family<ReportSummary, String>(
  (ref, range) => ref.watch(financeServiceProvider).reportSummary(range),
);

final reportRevenueProvider = FutureProvider.autoDispose.family<RevenueSeries, String>(
  (ref, range) => ref.watch(financeServiceProvider).reportRevenue(range),
);

final disputesProvider = FutureProvider.autoDispose<List<DisputeRecord>>(
  (ref) => ref.watch(platformServiceProvider).disputes(limit: 100),
);

final supportCasesProvider = FutureProvider.autoDispose<List<SupportCase>>(
  (ref) => ref.watch(platformServiceProvider).supportCases(),
);

final notificationsProvider = FutureProvider.autoDispose<List<NotificationRecord>>(
  (ref) => ref.watch(platformServiceProvider).notifications(),
);

final conversationsProvider = FutureProvider.autoDispose<List<ConversationRecord>>(
  (ref) => ref.watch(platformServiceProvider).conversations(),
);

final translationsProvider = FutureProvider.autoDispose<List<TranslationRecord>>(
  (ref) => ref.watch(platformServiceProvider).translations(),
);

final reviewsProvider = FutureProvider.autoDispose<List<ReviewRecord>>(
  (ref) => ref.watch(financeServiceProvider).reviews(),
);

final abuseReportsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(platformServiceProvider).abuseReports(),
);

final promotionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(platformServiceProvider).promotions(),
);

final zonesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(platformServiceProvider).shippingZones(),
);

/// Mock-only modules (no dedicated backend endpoints). Data lives in the app,
/// mirroring the frontend's local `mvecStore` behaviour.
class MockStore {
  MockStore._();
  static final MockStore instance = MockStore._();

  final ledgerEntries = <Map<String, dynamic>>[];
  final commissions = <Map<String, dynamic>>[];
}