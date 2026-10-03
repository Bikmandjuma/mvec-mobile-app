import '../../../core/api_client.dart';
import '../models/vendor_settings.dart';

/// Contract for reading and changing the vendor's store configuration.
abstract class VendorSettingsService {
  bool get isDemo;

  Future<VendorStoreSettings> settings();
  Future<VendorStoreSettings> save(VendorStoreSettings settings);
  Future<VendorStoreSettings> inviteStaff({
    required VendorStaffMember member,
    required String password,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<VendorStoreSettings> setStaffActive(String id, bool active);
}

/// Live adapter for the vendor settings endpoints.
class ApiVendorSettingsService implements VendorSettingsService {
  ApiVendorSettingsService(this._api);

  final ApiClient _api;

  @override
  bool get isDemo => false;

  @override
  Future<VendorStoreSettings> settings() async {
    final response = await _api.get('/stores/mine/settings');
    return VendorStoreSettings.fromJson(
      singleJson(response, ['settings', 'store', 'data']),
    );
  }

  @override
  Future<VendorStoreSettings> save(VendorStoreSettings settings) async {
    final response = await _api.put(
      '/stores/mine/settings',
      body: settings.toJson(),
    );
    return VendorStoreSettings.fromJson(
      singleJson(response, ['settings', 'store', 'data']),
    );
  }

  @override
  Future<VendorStoreSettings> inviteStaff({
    required VendorStaffMember member,
    required String password,
  }) async {
    final response = await _api.post(
      '/stores/mine/settings/staff',
      body: {
        'name': member.name,
        'email': member.email,
        'role': member.role.name,
        'permissions': [
          for (final permission in member.permissions) permission.slug,
        ],
        'password': password,
      },
    );
    return VendorStoreSettings.fromJson(
      singleJson(response, ['settings', 'store', 'data']),
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post(
      '/stores/mine/security/password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  @override
  Future<VendorStoreSettings> setStaffActive(String id, bool active) async {
    final response = await _api.patch(
      '/stores/mine/settings/staff/$id',
      body: {'active': active},
    );
    return VendorStoreSettings.fromJson(
      singleJson(response, ['settings', 'store', 'data']),
    );
  }
}
