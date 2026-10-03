import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_config.dart';
import 'models/vendor_finance.dart';
import 'models/vendor_notification.dart';
import 'models/vendor_order.dart';
import 'models/vendor_settings.dart';
import 'services/mock_vendor_finance_service.dart';
import 'services/mock_vendor_notification_service.dart';
import 'services/mock_vendor_order_service.dart';
import 'services/mock_vendor_settings_service.dart';
import 'services/vendor_finance_service.dart';
import 'services/vendor_notification_service.dart';
import 'services/vendor_order_service.dart';
import 'services/vendor_settings_service.dart';

/// One compile-time switch keeps every vendor module on the same data source.
final vendorOrderModuleProvider = Provider<VendorOrderService>(
  (ref) =>
      kDemoMode
          ? MockVendorOrderService()
          : ApiVendorOrderService(ref.watch(apiProvider)),
);

final vendorFinanceModuleProvider = Provider<VendorFinanceService>(
  (ref) =>
      kDemoMode
          ? MockVendorFinanceService()
          : ApiVendorFinanceService(ref.watch(apiProvider)),
);

final vendorNotificationModuleProvider = Provider<VendorNotificationService>(
  (ref) =>
      kDemoMode
          ? MockVendorNotificationService()
          : ApiVendorNotificationService(ref.watch(apiProvider)),
);

final vendorSettingsModuleProvider = Provider<VendorSettingsService>(
  (ref) =>
      kDemoMode
          ? MockVendorSettingsService()
          : ApiVendorSettingsService(ref.watch(apiProvider)),
);

final vendorOrdersPageProvider = FutureProvider.autoDispose.family<
  VendorOrderPage,
  VendorOrderStatus?
>((ref, status) => ref.watch(vendorOrderModuleProvider).orders(status: status));

final vendorFinanceSummaryProvider =
    FutureProvider.autoDispose<VendorFinanceSummary>(
      (ref) => ref.watch(vendorFinanceModuleProvider).summary(),
    );

final vendorLedgerProvider = FutureProvider.autoDispose<List<LedgerEntry>>(
  (ref) => ref.watch(vendorFinanceModuleProvider).ledger(),
);

final vendorPayoutsProvider = FutureProvider.autoDispose<List<PayoutRequest>>(
  (ref) => ref.watch(vendorFinanceModuleProvider).payouts(),
);

final vendorNotificationsProvider = FutureProvider.autoDispose
    .family<List<VendorNotification>, NotificationCategory?>(
      (ref, category) => ref
          .watch(vendorNotificationModuleProvider)
          .notifications(category: category),
    );

final vendorStoreSettingsProvider =
    FutureProvider.autoDispose<VendorStoreSettings>(
      (ref) => ref.watch(vendorSettingsModuleProvider).settings(),
    );
