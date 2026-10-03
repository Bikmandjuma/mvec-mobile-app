import '../../../core/api_client.dart';
import '../models/vendor_notification.dart';

/// Notification feed contract shared by the live API and local demo adapter.
abstract class VendorNotificationService {
  bool get isDemo;

  Future<List<VendorNotification>> notifications({
    NotificationCategory? category,
  });

  Future<VendorNotification> setRead(String id, bool read);
}

/// Reads and updates the vendor notification feed through the platform API.
class ApiVendorNotificationService implements VendorNotificationService {
  ApiVendorNotificationService(this._api);

  final ApiClient _api;

  @override
  bool get isDemo => false;

  @override
  Future<List<VendorNotification>> notifications({
    NotificationCategory? category,
  }) async {
    final response = await _api.get(
      '/stores/mine/notifications',
      query: {if (category != null) 'category': category.slug},
    );
    return listJson(response, [
      'notifications',
      'data',
    ]).map(VendorNotification.fromJson).toList();
  }

  @override
  Future<VendorNotification> setRead(String id, bool read) async {
    final response = await _api.patch(
      '/stores/mine/notifications/$id/read',
      body: {'read': read},
    );
    return VendorNotification.fromJson(
      singleJson(response, ['notification', 'data']),
    );
  }
}
