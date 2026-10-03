import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mvec_mobile/core/api_config.dart';
import 'package:mvec_mobile/core/theme.dart';
import 'package:mvec_mobile/features/vendor/models/vendor_finance.dart';
import 'package:mvec_mobile/features/vendor/models/vendor_order.dart';
import 'package:mvec_mobile/features/vendor/models/vendor_settings.dart';
import 'package:mvec_mobile/features/vendor/services/mock_vendor_finance_service.dart';
import 'package:mvec_mobile/features/vendor/services/mock_vendor_notification_service.dart';
import 'package:mvec_mobile/features/vendor/services/mock_vendor_order_service.dart';
import 'package:mvec_mobile/features/vendor/services/mock_vendor_settings_service.dart';
import 'package:mvec_mobile/features/vendor/screens/vendor_settings_screen.dart';
import 'package:mvec_mobile/features/vendor/vendor_dependencies.dart';

void main() {
  test('demo dependency switch selects local vendor services', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(vendorOrderModuleProvider).isDemo, kDemoMode);
    expect(container.read(vendorFinanceModuleProvider).isDemo, kDemoMode);
    expect(container.read(vendorNotificationModuleProvider).isDemo, kDemoMode);
    expect(container.read(vendorSettingsModuleProvider).isDemo, kDemoMode);
  });

  test('orders progress through tracking and buyer OTP confirmation', () async {
    final service = MockVendorOrderService(delay: Duration.zero);
    final page = await service.orders();
    final pending = page.orders.firstWhere(
      (order) => order.status == VendorOrderStatus.pending,
    );

    final processing = await service.updateStatus(
      pending.id,
      VendorOrderStatus.processing,
    );
    expect(processing.status, VendorOrderStatus.processing);

    await expectLater(
      service.updateStatus(pending.id, VendorOrderStatus.shipped),
      throwsA(isA<Exception>()),
    );

    final shipped = await service.updateStatus(
      pending.id,
      VendorOrderStatus.shipped,
      trackingCode: 'DEMO-TRACK-001',
    );
    expect(shipped.trackingCode, 'DEMO-TRACK-001');

    await expectLater(
      service.updateStatus(
        pending.id,
        VendorOrderStatus.delivered,
        deliveryOtp: '0000',
      ),
      throwsA(isA<Exception>()),
    );

    final delivered = await service.updateStatus(
      pending.id,
      VendorOrderStatus.delivered,
      deliveryOtp: pending.deliveryOtp,
    );
    expect(delivered.escrowReleased, isTrue);
  });

  test(
    'payout validation uses the balance shown in the finance summary',
    () async {
      final service = MockVendorFinanceService(delay: Duration.zero);
      final before = await service.summary();
      expect(before.isConsistent, isTrue);

      final payout = await service.requestPayout(
        amount: 1200000,
        method: PayoutMethod.mtnMomo,
        destination: '+250788000001',
      );
      expect(payout.isPending, isTrue);
      expect(
        (await service.summary()).availablePayout,
        before.availablePayout - payout.amount,
      );
    },
  );

  test(
    'notifications and settings retain mutations in the mock session',
    () async {
      final notifications = MockVendorNotificationService(delay: Duration.zero);
      final firstUnread = (await notifications.notifications()).firstWhere(
        (item) => !item.read,
      );
      expect((await notifications.setRead(firstUnread.id, true)).read, isTrue);

      final settings = MockVendorSettingsService(delay: Duration.zero);
      final profile = await settings.settings();
      final updated = await settings.save(
        profile.copyWith(storeName: 'Demo Store Updated'),
      );
      expect((await settings.settings()).storeName, updated.storeName);

      final staff = profile.staff.firstWhere((member) => !member.isOwner);
      final changed = await settings.setStaffActive(staff.id, false);
      expect(
        changed.staff.firstWhere((member) => member.id == staff.id).active,
        isFalse,
      );
    },
  );

  test('shipping summaries format whole RWF amounts safely', () {
    const flat = ShippingRule(
      id: 'flat',
      name: 'Standard',
      type: ShippingRuleType.flat,
      amount: 2000,
      etaDays: 2,
    );
    const free = ShippingRule(
      id: 'free',
      name: 'Free delivery',
      type: ShippingRuleType.free,
      minimumOrder: 50000,
      etaDays: 1,
    );

    expect(flat.summary, '2,000 · 2 days');
    expect(free.summary, 'Free above 50,000');
  });

  test(
    'staff invitation accepts a password without storing it in settings',
    () async {
      final service = MockVendorSettingsService(delay: Duration.zero);
      final member = VendorStaffMember(
        id: 'staff-test',
        name: 'Test Member',
        email: 'test.member@example.rw',
        role: StaffRole.staff,
        permissions: StaffRole.staff.defaults,
      );

      final updated = await service.inviteStaff(
        member: member,
        password: 'Temporary-123',
      );

      expect(updated.staff.any((staff) => staff.id == member.id), isTrue);
      expect(updated.toJson().toString(), isNot(contains('Temporary-123')));
    },
  );

  testWidgets('business and delivery section renders shipping options', (
    tester,
  ) async {
    final service = MockVendorSettingsService(delay: Duration.zero);
    const settings = VendorStoreSettings(
      storeName: 'Test Store',
      hours: OperatingHours([OperatingDay(label: 'Monday', open: true)]),
      shippingRules: [
        ShippingRule(
          id: 'ship-standard',
          name: 'Kigali standard',
          type: ShippingRuleType.flat,
          amount: 2000,
          etaDays: 2,
        ),
        ShippingRule(
          id: 'ship-free',
          name: 'Free delivery',
          type: ShippingRuleType.free,
          minimumOrder: 50000,
          etaDays: 1,
        ),
      ],
      defaultShippingRuleId: 'ship-standard',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorStoreSettingsProvider.overrideWith((ref) async => settings),
          vendorSettingsModuleProvider.overrideWith((ref) => service),
        ],
        child: MaterialApp(
          theme: lightAppTheme,
          home: const Scaffold(
            body: SingleChildScrollView(child: VendorSettingsScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Business & delivery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Kigali standard · 2,000 · 2 days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
