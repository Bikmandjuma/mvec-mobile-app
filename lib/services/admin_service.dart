import '../core/api_client.dart';
import '../models/catalog.dart';
import '../models/party.dart';
import '../models/user.dart';

/// Admin-facing API calls. Everything here either requires `super_admin`
/// or is available to super_admin per the backend route guards.
class AdminService {
  AdminService(this._api);
  final ApiClient _api;

  // ---------- Users / buyers ----------
  Future<Paged<UserRecord>> users({int page = 1, int limit = 20, String? role, String? status, String? search}) async {
    final res = await _api.get('/users', query: {
      'page': page,
      'limit': limit,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
      if (search != null) 'search': search,
    });
    return Paged.parse(res, UserRecord.fromJson);
  }

  Future<UserRecord> userDetail(String id) async {
    final res = await _api.get('/users/$id');
    return UserRecord.fromJson(singleJson(res, ['user']));
  }

  Future<UserRecord> patchUser(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/users/$id', body: body);
    return UserRecord.fromJson(singleJson(res, ['user']));
  }

  // ---------- Account / profile ----------
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _api.patch('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // ---------- Vendors ----------
  Future<Paged<PartyRecord>> vendors({int page = 1, int pageSize = 20, String? status, String? verificationStatus}) async {
    final res = await _api.get('/admin/vendors', query: {
      'page': page,
      'pageSize': pageSize,
      if (status != null) 'status': status,
      if (verificationStatus != null) 'verificationStatus': verificationStatus,
    });
    return Paged.parse(res, PartyRecord.fromJson);
  }

  Future<PartyRecord> vendorVerify(String id, String decision) async {
    final res = await _api.patch('/admin/vendors/$id/verify', body: {'decision': decision});
    return PartyRecord.fromJson(singleJson(res, ['vendor']));
  }

  Future<PartyRecord> vendorStatus(String id, String status) async {
    final res = await _api.patch('/admin/vendors/$id/status', body: {'status': status});
    return PartyRecord.fromJson(singleJson(res, ['vendor']));
  }

  // ---------- Suppliers ----------
  Future<Paged<PartyRecord>> suppliers({int page = 1, int pageSize = 20, String? status, String? verificationStatus}) async {
    final res = await _api.get('/admin/suppliers', query: {
      'page': page,
      'pageSize': pageSize,
      if (status != null) 'status': status,
      if (verificationStatus != null) 'verificationStatus': verificationStatus,
    });
    return Paged.parse(res, PartyRecord.fromJson);
  }

  Future<PartyRecord> supplierVerify(String id, String decision) async {
    final res = await _api.patch('/admin/suppliers/$id/verify', body: {'decision': decision});
    return PartyRecord.fromJson(singleJson(res, ['supplier']));
  }

  Future<PartyRecord> supplierStatus(String id, String status) async {
    final res = await _api.patch('/admin/suppliers/$id/status', body: {'status': status});
    return PartyRecord.fromJson(singleJson(res, ['supplier']));
  }

  // ---------- Affiliates ----------
  Future<List<PartyRecord>> affiliates() async {
    final res = await _api.get('/affiliates');
    return listJson(res, ['data']).map(PartyRecord.fromJson).toList();
  }

  Future<List<PayoutRecord>> affiliatePayouts() async {
    final res = await _api.get('/affiliates/admin/payouts');
    return listJson(res, ['data']).map(PayoutRecord.fromJson).toList();
  }

  Future<void> processAffiliatePayout(String payoutId, String status, {String? reference, String? reason}) async {
    await _api.post('/affiliates/payouts/$payoutId/process', body: {
      'status': status,
      if (reference != null) 'transactionReference': reference,
      if (reason != null) 'rejectionReason': reason,
    });
  }

  // ---------- Categories ----------
  Future<List<CategoryRecord>> categories() async {
    final res = await _api.get('/categories', query: {'tree': 'false'});
    return listJson(res, ['categories', 'data']).map(CategoryRecord.fromJson).toList();
  }

  Future<void> createCategory(Map<String, dynamic> body) async {
    await _api.post('/categories', body: body);
  }

  Future<void> patchCategory(String id, Map<String, dynamic> body) async {
    await _api.patch('/categories/$id', body: body);
  }

  Future<void> deleteCategory(String id) async {
    await _api.delete('/categories/$id');
  }

  // ---------- Products ----------
  Future<List<ProductRecord>> products({int page = 1, int limit = 50}) async {
    final res = await _api.get('/products', query: {'page': page, 'limit': limit, 'status': 'ACTIVE'});
    return listJson(res, ['data']).map(ProductRecord.fromJson).toList();
  }

  Future<void> createProduct(Map<String, dynamic> body) async {
    await _api.post('/products', body: body);
  }

  Future<void> patchProduct(String id, Map<String, dynamic> body) async {
    await _api.put('/products/$id', body: body);
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete('/products/$id');
  }

  // ---------- Orders ----------
  Future<List<OrderRecord>> orders() async {
    final res = await _api.get('/orders');
    return listJson(res, ['orders']).map(OrderRecord.fromJson).toList();
  }

  Future<OrderRecord> orderDetail(String id) async {
    final res = await _api.get('/orders/$id');
    return OrderRecord.fromJson(singleJson(res, ['order']));
  }

  Future<void> patchOrderStatus(String id, String status) async {
    await _api.patch('/orders/$id/status', body: {'status': status});
  }

  Future<void> deliverOrder(String id, String otp) async {
    await _api.patch('/orders/$id/deliver', body: {'deliveryOtp': otp});
  }
}