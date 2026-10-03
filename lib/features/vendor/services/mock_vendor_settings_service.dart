import '../models/vendor_settings.dart';
import 'vendor_settings_service.dart';

/// Mutable local store profile used in demos; edits remain during navigation.
class MockVendorSettingsService implements VendorSettingsService {
  MockVendorSettingsService({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  VendorStoreSettings _settings = VendorStoreSettings(
    storeName: 'Umucyo Harvest Market',
    storeSlug: 'umucyo-harvest',
    phone: '+250 788 410 226',
    supportEmail: 'hello@umucyo.rw',
    description:
        'Fresh produce and pantry staples, sourced from local growers across Rwanda.',
    businessAddress: 'KN 5 Rd, Kacyiru, Gasabo, Kigali',
    businessPhone: '+250 788 410 226',
    taxId: 'TIN 103482761',
    hours: OperatingHours([
      for (final day in const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
      ])
        OperatingDay(label: day, open: true, from: '08:00', to: '18:00'),
      const OperatingDay(
        label: 'Saturday',
        open: true,
        from: '09:00',
        to: '15:00',
      ),
      const OperatingDay(label: 'Sunday', open: false),
    ]),
    shippingRules: const [
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
    twoFactorEnabled: true,
    staff: const [
      VendorStaffMember(
        id: 'staff-owner',
        name: 'Aline Mukamana',
        email: 'aline@umucyo.rw',
        phone: '+250 788 100 301',
        role: StaffRole.owner,
        permissions: {
          VendorPermission.viewDashboard,
          VendorPermission.manageProducts,
          VendorPermission.manageOrders,
          VendorPermission.managePayouts,
          VendorPermission.manageStaff,
          VendorPermission.viewAnalytics,
        },
      ),
      VendorStaffMember(
        id: 'staff-manager',
        name: 'Eric Ndayisaba',
        email: 'eric@umucyo.rw',
        phone: '+250 783 221 190',
        role: StaffRole.manager,
        permissions: {
          VendorPermission.viewDashboard,
          VendorPermission.manageProducts,
          VendorPermission.manageOrders,
          VendorPermission.viewAnalytics,
        },
      ),
      VendorStaffMember(
        id: 'staff-fulfilment',
        name: 'Claudine Uwera',
        email: 'claudine@umucyo.rw',
        role: StaffRole.staff,
        permissions: {
          VendorPermission.viewDashboard,
          VendorPermission.manageOrders,
        },
      ),
    ],
  );

  @override
  bool get isDemo => true;

  Future<void> _latency() => Future<void>.delayed(delay);

  @override
  Future<VendorStoreSettings> settings() async {
    await _latency();
    return _settings;
  }

  @override
  Future<VendorStoreSettings> save(VendorStoreSettings settings) async {
    await _latency();
    _settings = settings;
    return _settings;
  }

  @override
  Future<VendorStoreSettings> inviteStaff({
    required VendorStaffMember member,
    required String password,
  }) async {
    await _latency();
    if (password.length < 8) {
      throw StateError('Staff password must contain at least 8 characters.');
    }
    if (_settings.staff.any((existing) => existing.email.toLowerCase() == member.email.toLowerCase())) {
      throw StateError('A team member with this email already exists.');
    }
    _settings = _settings.copyWith(staff: [..._settings.staff, member]);
    return _settings;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _latency();
    if (currentPassword.isEmpty || newPassword.length < 8) {
      throw StateError(
        'Enter your current password and a new password of at least 8 characters.',
      );
    }
  }

  @override
  Future<VendorStoreSettings> setStaffActive(String id, bool active) async {
    await _latency();
    final index = _settings.staff.indexWhere((member) => member.id == id);
    if (index < 0) throw StateError('Team member was not found');
    final staff = [..._settings.staff];
    staff[index] = staff[index].copyWith(active: active);
    _settings = _settings.copyWith(staff: staff);
    return _settings;
  }
}
