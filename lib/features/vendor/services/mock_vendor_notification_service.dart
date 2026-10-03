import '../models/vendor_notification.dart';
import 'vendor_notification_service.dart';

/// In-memory notification feed used by the vendor demo experience.
class MockVendorNotificationService implements VendorNotificationService {
  MockVendorNotificationService({
    this.delay = const Duration(milliseconds: 350),
  });

  final Duration delay;
  late final List<VendorNotification> _items = _seed();

  @override
  bool get isDemo => true;

  @override
  Future<List<VendorNotification>> notifications({
    NotificationCategory? category,
  }) async {
    await Future<void>.delayed(delay);
    final result =
        category == null
            ? _items
            : _items.where((item) => item.category == category).toList();
    return List.unmodifiable(result);
  }

  @override
  Future<VendorNotification> setRead(String id, bool read) async {
    await Future<void>.delayed(delay);
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Notification $id was not found');
    _items[index] = _items[index].copyWith(read: read);
    return _items[index];
  }

  List<VendorNotification> _seed() {
    final now = DateTime.now();
    return [
      VendorNotification(
        id: 'ntf-1',
        at: now.subtract(const Duration(minutes: 12)),
        category: NotificationCategory.order,
        severity: NotificationSeverity.info,
        title: 'New order received',
        body:
            'Jean Bosco Nshimiyimana placed order MV-1041. Payment is secured in escrow.',
        read: false,
        actionPath: '/vendor/orders',
        actionLabel: 'Review order',
        orderId: 'ord-1041',
        orderNumber: 'MV-1041',
      ),
      VendorNotification(
        id: 'ntf-2',
        at: now.subtract(const Duration(hours: 1)),
        category: NotificationCategory.dispute,
        severity: NotificationSeverity.warning,
        title: 'Delivery case needs attention',
        body:
            'A buyer opened a delivery inquiry for order MV-1035. Respond before the review window closes.',
        read: false,
        actionPath: '/vendor/orders',
        actionLabel: 'View order',
        orderId: 'ord-1035',
        orderNumber: 'MV-1035',
      ),
      VendorNotification(
        id: 'ntf-3',
        at: now.subtract(const Duration(hours: 5)),
        category: NotificationCategory.financial,
        severity: NotificationSeverity.success,
        title: 'Escrow released',
        body:
            'RWF 571,990 from order MV-1030 is now included in your available balance.',
        read: false,
        amount: 571990,
        actionPath: '/vendor/sales',
        actionLabel: 'View ledger',
      ),
      VendorNotification(
        id: 'ntf-4',
        at: now.subtract(const Duration(days: 1)),
        category: NotificationCategory.policy,
        severity: NotificationSeverity.warning,
        title: 'Delivery policy updated',
        body:
            'Please confirm delivery with the buyer OTP before marking an order complete.',
        read: true,
        actionPath: '/vendor/settings',
        actionLabel: 'Review settings',
      ),
      VendorNotification(
        id: 'ntf-5',
        at: now.subtract(const Duration(days: 2)),
        category: NotificationCategory.financial,
        severity: NotificationSeverity.info,
        title: 'Withdrawal is processing',
        body: 'Your RWF 900,000 Airtel Money payout is being verified.',
        read: true,
        amount: 900000,
        actionPath: '/vendor/sales',
        actionLabel: 'View payout',
      ),
      VendorNotification(
        id: 'ntf-6',
        at: now.subtract(const Duration(days: 3)),
        category: NotificationCategory.order,
        severity: NotificationSeverity.success,
        title: 'Order delivered',
        body: 'Order MV-1028 was confirmed and escrow has been released.',
        read: true,
        actionPath: '/vendor/orders',
        actionLabel: 'View order',
        orderId: 'ord-1028',
        orderNumber: 'MV-1028',
      ),
      VendorNotification(
        id: 'ntf-7',
        at: now.subtract(const Duration(days: 5)),
        category: NotificationCategory.policy,
        severity: NotificationSeverity.info,
        title: 'Store verification complete',
        body:
            'Your business profile is verified and visible to marketplace buyers.',
        read: true,
        actionPath: '/vendor/profile',
        actionLabel: 'View profile',
      ),
    ];
  }
}
