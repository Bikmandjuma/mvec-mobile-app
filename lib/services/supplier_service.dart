import '../core/api_client.dart';
import '../models/supplier.dart';

/// Supplier-facing API calls.
///
/// These mirror `Mvec_backend/src/routes/supplier.routes.js`, which is
/// mounted at `/api/suppliers` and owns the supplier's own wholesale
/// catalogue. Every `/me/*` route is resolved from the bearer token, so no
/// supplier id is ever sent by the app.
class SupplierService {
  SupplierService(this._api);
  final ApiClient _api;

  // ---------- Profile ----------
  /// The supplier's own profile, or `null` when they have not onboarded yet.
  ///
  /// `GET /suppliers/me/profile` 404s until onboarding is complete. That is a
  /// normal first-run state rather than a failure, so it is mapped to `null`
  /// and the UI offers onboarding instead of surfacing an error.
  Future<SupplierDetail?> profile() async {
    try {
      final res = await _api.get('/suppliers/me/profile');
      return SupplierDetail.fromJson(singleJson(res, ['supplier', 'profile', 'data']));
    } catch (e) {
      if (statusCodeOf(e) == 404) return null;
      rethrow;
    }
  }

  /// `POST /suppliers/onboard` → creates the profile on first save.
  /// 409s if a profile already exists.
  Future<SupplierDetail> onboard(Map<String, dynamic> body) async {
    final res = await _api.post('/suppliers/onboard', body: body);
    return SupplierDetail.fromJson(singleJson(res, ['supplier', 'profile', 'data']));
  }

  /// `PATCH /suppliers/me/profile`. The backend only honours
  /// businessName, description, phone, email, logoUrl and location — the
  /// other keys are dropped server-side, so [body] is trimmed to match.
  Future<SupplierDetail> updateProfile(Map<String, dynamic> body) async {
    final res = await _api.patch('/suppliers/me/profile', body: {
      if (body['businessName'] != null) 'businessName': body['businessName'],
      if (body['description'] != null) 'description': body['description'],
      if (body['phone'] != null) 'phone': body['phone'],
      if (body['email'] != null) 'email': body['email'],
      if (body['logoUrl'] != null) 'logoUrl': body['logoUrl'],
      if (body['location'] != null) 'location': body['location'],
    });
    return SupplierDetail.fromJson(singleJson(res, ['supplier', 'profile', 'data']));
  }

  /// Creates the profile when it is missing, otherwise patches it. A 404 from
  /// [profile] is what signals "not onboarded yet".
  Future<SupplierDetail> saveProfile(Map<String, dynamic> body, {required bool isNewProfile}) async {
    return isNewProfile ? onboard(body) : updateProfile(body);
  }

  // ---------- Inventory ----------
  /// `GET /suppliers/me/products` → `{ success, supplier, count, products }`.
  /// The backend returns the whole catalogue unpaginated, so [page] /
  /// [pageSize] are applied by `Paged.parse` consumers.
  Future<List<SupplierProduct>> products() async {
    final res = await _api.get('/suppliers/me/products');
    return listJson(res, ['products', 'data'])
        .map(SupplierProduct.fromJson)
        .toList();
  }

  /// `POST /suppliers/me/products`. Requires `name` and `wholesalePrice`.
  Future<SupplierProduct> createProduct(Map<String, dynamic> body) async {
    final res = await _api.post('/suppliers/me/products', body: body);
    return SupplierProduct.fromJson(singleJson(res, ['product', 'data']));
  }

  Future<SupplierProduct> updateProduct(String id, Map<String, dynamic> body) async {
    final res = await _api.put('/suppliers/me/products/$id', body: body);
    return SupplierProduct.fromJson(singleJson(res, ['product', 'data']));
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete('/suppliers/me/products/$id');
  }
}
