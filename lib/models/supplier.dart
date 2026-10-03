import 'supplier_product.dart';

export 'supplier_product.dart';

/// A supplier's own business profile.
///
/// Mirrors `Mvec_backend/src/models/Supplier.js`. That document is
/// deliberately thin — business identity, contact details, a verification
/// state and a `ratingAvg`. Notably there is no nested address object, no
/// tax/registration number and no document list: `location` is a nullable
/// `ObjectId` referencing a `Location` document, which the supplier portal
/// does not yet own.
class SupplierDetail {
  SupplierDetail({
    this.id,
    this.publicId,
    this.userId,
    this.businessName,
    this.slug,
    this.logoUrl,
    this.description,
    this.phone,
    this.email,
    this.verificationStatus,
    this.ratingAvg,
    this.status,
    this.locationId,
    this.createdAt,
    this.updatedAt,
    this.raw,
  });

  String? id;

  /// Human-facing id, e.g. `MVEC-SUP-1A2B3C4D`.
  String? publicId;
  String? userId;
  String? businessName;
  String? slug;
  String? logoUrl;
  String? description;
  String? phone;
  String? email;

  /// One of `UNVERIFIED`, `PENDING`, `VERIFIED`, `REJECTED`.
  String? verificationStatus;

  /// 0–5, maintained by the marketplace rather than the supplier.
  double? ratingAvg;

  /// One of `ACTIVE`, `SUSPENDED`, `BLOCKED`, `UNDER_REVIEW`.
  String? status;

  /// Id of the linked `Location`; null until the location feature lands.
  String? locationId;

  DateTime? createdAt;
  DateTime? updatedAt;
  Map<String, dynamic>? raw;

  factory SupplierDetail.fromJson(Map<String, dynamic> j) {
    double? rating(j, key) {
      final v = j[key];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return SupplierDetail(
      id: (j['_id'] ?? j['id'])?.toString(),
      publicId: j['publicId']?.toString(),
      userId: j['user'] is Map ? j['user']['_id']?.toString() : j['user']?.toString(),
      businessName: j['businessName']?.toString(),
      slug: j['slug']?.toString(),
      logoUrl: j['logoUrl']?.toString(),
      description: j['description']?.toString(),
      phone: j['phone']?.toString(),
      email: j['email']?.toString(),
      verificationStatus: j['verificationStatus']?.toString(),
      ratingAvg: rating(j, 'ratingAvg'),
      status: j['status']?.toString(),
      locationId: j['location'] is Map ? j['location']['_id']?.toString() : j['location']?.toString(),
      createdAt: _parseDate(j['createdAt'] ?? j['created_at']),
      updatedAt: _parseDate(j['updatedAt'] ?? j['updated_at']),
      raw: j,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  /// The payload accepted by `POST /suppliers/onboard` and
  /// `PATCH /suppliers/me/profile`. `businessName`, `phone` and `email` are
  /// required by the schema.
  Map<String, dynamic> toRequestBody() => {
        if (businessName != null) 'businessName': businessName,
        if (description != null) 'description': description,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (locationId != null) 'location': locationId,
      };

  String get display => businessName ?? 'Unnamed supplier';

  String? get verificationStatusOrDefault => verificationStatus ?? 'UNVERIFIED';

  bool get isVerified => verificationStatusOrDefault == 'VERIFIED';
  bool get isPending => verificationStatusOrDefault == 'PENDING';
  bool get isRejected => verificationStatusOrDefault == 'REJECTED';
  bool get isUnverified => verificationStatusOrDefault == 'UNVERIFIED';

  /// The supplier cannot change their own verification state — only an
  /// admin can verify — so the admin status is authoritative for badges.
  bool get isSuspended => status?.toUpperCase() == 'SUSPENDED' || status?.toUpperCase() == 'BLOCKED';

  /// Shows the verification state when one applies, otherwise the account
  /// state, so the dashboard always has something meaningful to render.
  String get effectiveStatus {
    if (isVerified) return 'VERIFIED';
    if (isPending) return 'PENDING';
    if (isRejected) return 'REJECTED';
    return status?.toUpperCase() ?? 'UNVERIFIED';
  }

  /// True until the profile exists — `GET /suppliers/me/profile` 404s in this
  /// state and the portal must fall back to onboarding.
  bool get isOnboarded => businessName != null && businessName!.isNotEmpty;

  String get logo => logoUrl ?? '';
}

/// Dashboard counters for the supplier portal.
///
/// The backend has no metrics endpoint, so [SupplierMetrics.fromCatalog]
/// derives the inventory figures from the supplier's own product list. The
/// commerce figures (revenue, orders, views) have no source yet and stay at
/// zero rather than being invented.
class SupplierMetrics {
  SupplierMetrics({
    this.totalProducts = 0,
    this.activeProducts = 0,
    this.lowStockProducts = 0,
    this.outOfStockProducts = 0,
    this.totalUnitsInStock = 0,
    this.totalCatalogValue = 0.0,
  });

  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int totalUnitsInStock;

  /// Sum of `wholesalePrice * stockQuantity` across the catalogue.
  final double totalCatalogValue;

  /// Derives inventory metrics from `GET /suppliers/me/products`.
  factory SupplierMetrics.fromCatalog(List<SupplierProduct> products) {
    var active = 0;
    var low = 0;
    var out = 0;
    var units = 0;
    var value = 0.0;
    for (final p in products) {
      if (p.isArchived) continue;
      if (p.isOutOfStock) {
        out++;
      } else if (p.isLowStock) {
        low++;
      }
      if (p.isActive) active++;
      units += p.stockQuantity ?? 0;
      value += (p.wholesalePrice ?? 0) * (p.stockQuantity ?? 0);
    }
    return SupplierMetrics(
      totalProducts: products.length,
      activeProducts: active,
      lowStockProducts: low,
      outOfStockProducts: out,
      totalUnitsInStock: units,
      totalCatalogValue: value,
    );
  }

  bool get hasInventory => totalProducts > 0;
}
