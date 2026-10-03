import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvec_mobile/core/api_client.dart';
import 'package:mvec_mobile/features/supplier/data/supplier_workspace.dart';

const _forbidden =
    "User role 'supplier' is not authorized to access this route";

/// Stands in for the real backend: everything a supplier may read works, while
/// the admin-only order routes answer 403 exactly like `GET /api/orders` does.
class _ForbiddenOrdersService implements SupplierWorkspaceService {
  _ForbiddenOrdersService({
    this.forbidNotifications = false,
    this.forbidOrders = true,
  });

  final bool forbidNotifications;
  final bool forbidOrders;

  ApiException get _denied => ApiException(_forbidden, statusCode: 403);

  @override
  Future<List<SupplierProduct>> products() async => const [
    SupplierProduct(
      id: 'sp-1',
      name: 'Arabica Beans',
      category: 'Beverages',
      description: 'Washed beans',
      imageUrl: 'https://example.test/a.png',
      price: 12500,
      stock: 84,
      status: 'ACTIVE',
      minimumOrderQuantity: 10,
      bulkDiscount: 8,
    ),
  ];

  @override
  Future<List<SupplierOrder>> orders() async {
    if (forbidOrders) throw _denied;
    return const [];
  }

  @override
  Future<List<SupplierNotice>> notifications() async {
    if (forbidNotifications) throw _denied;
    return const [];
  }

  @override
  Future<SupplierProfile> profile() async => const SupplierProfile(
    id: 's-1',
    businessName: 'Verify Ltd',
    email: 'supplier@example.test',
    phone: '0799000000',
    address: 'Kigali',
    orderNotifications: true,
    stockNotifications: true,
  );

  @override
  Future<void> saveProduct(SupplierProduct product) async {}

  @override
  Future<void> saveProfile(
    SupplierProfile profile, {
    required bool isNewProfile,
  }) async {}

  @override
  Future<void> deleteProduct(String id) async {}

  @override
  Future<void> updateStock(String id, int stock) async {}

  @override
  Future<void> updateOrderStatus(String id, String status) async {}

  @override
  Future<void> markNotificationRead(String id) async {}
}

ProviderContainer _container(_ForbiddenOrdersService service) =>
    ProviderContainer(
      overrides: [supplierWorkspaceServiceProvider.overrideWithValue(service)],
    );

void main() {
  test('a 403 on orders does not blank the rest of the portal', () async {
    // Regression: `_load()` used to Future.wait every section together, so the
    // admin-only `GET /orders` 403 failed the single shared provider and every
    // supplier page rendered the "not authorized" error state at once.
    final container = _container(_ForbiddenOrdersService());
    addTearDown(container.dispose);

    final data = await container.read(supplierWorkspaceProvider.future);

    expect(data.orders, isEmpty);
    expect(data.ordersUnavailable, isTrue, reason: '403 must be recorded');
    // The healthy sections still load, which is the whole point.
    expect(data.products, hasLength(1));
    expect(data.profile.businessName, 'Verify Ltd');
    expect(data.notificationsUnavailable, isFalse);
  });

  test('a 403 on notifications degrades only notifications', () async {
    final container = _container(_ForbiddenOrdersService(forbidNotifications: true));
    addTearDown(container.dispose);

    final data = await container.read(supplierWorkspaceProvider.future);

    expect(data.notifications, isEmpty);
    expect(data.notificationsUnavailable, isTrue);
    expect(data.products, hasLength(1));
    expect(data.ordersUnavailable, isTrue);
  });

  test('a healthy backend reports no unavailable sections', () async {
    final container = _container(_ForbiddenOrdersService(forbidOrders: false));
    addTearDown(container.dispose);

    final data = await container.read(supplierWorkspaceProvider.future);

    expect(data.ordersUnavailable, isFalse);
    expect(data.notificationsUnavailable, isFalse);
    expect(data.metrics.activeProducts, 1);
  });
}
