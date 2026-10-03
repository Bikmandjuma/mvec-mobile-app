/// A supplier's own wholesale catalogue item.
///
/// Mirrors `Mvec_backend/src/models/WholesaleProduct.js`. Note the model is
/// wholesale-oriented: it has a `wholesalePrice` and a `retailPrice`, a
/// minimum order quantity and a bulk discount, and no retail `stock`/SKU
/// fields — the catalogue is not the same entity as a marketplace product.
class SupplierProduct {
  SupplierProduct({
    this.id,
    this.supplierId,
    this.name,
    this.shortDescription,
    this.category,
    this.unit,
    this.wholesalePrice,
    this.retailPrice,
    this.moq,
    this.stockQuantity,
    this.bulkDiscount,
    this.mainImage,
    this.gallery,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.raw,
  });

  String? id;
  String? supplierId;
  String? name;
  String? shortDescription;

  /// Free-text category; the backend defaults it to "General".
  String? category;

  /// Selling unit, e.g. "piece", "kg"; the backend defaults it to "piece".
  String? unit;

  num? wholesalePrice;
  num? retailPrice;

  /// Minimum order quantity; the backend enforces a floor of 1.
  int? moq;

  int? stockQuantity;

  /// Percentage 0–100.
  num? bulkDiscount;

  String? mainImage;
  List<String>? gallery;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  Map<String, dynamic>? raw;

  factory SupplierProduct.fromJson(Map<String, dynamic> j) {
    final media = j['media'] is Map ? Map<String, dynamic>.from(j['media'] as Map) : const <String, dynamic>{};
    final gallery = (media['gallery'] ?? j['gallery']) is List
        ? ((media['gallery'] ?? j['gallery']) as List).map((e) => e.toString()).toList()
        : const <String>[];
    return SupplierProduct(
      id: (j['_id'] ?? j['id'])?.toString(),
      supplierId: (j['supplier'] ?? j['supplierId']) is Map
          ? ((j['supplier'] as Map)['_id'] ?? (j['supplier'] as Map)['id'])?.toString()
          : (j['supplier'] ?? j['supplierId'])?.toString(),
      name: j['name']?.toString(),
      shortDescription: (j['shortDescription'] ?? j['description'])?.toString(),
      category: j['category']?.toString(),
      unit: j['unit']?.toString(),
      wholesalePrice: _num(j['wholesalePrice'] ?? j['price']),
      retailPrice: _num(j['retailPrice']),
      moq: _int(j['moq'] ?? j['minimumOrderQuantity']),
      stockQuantity: _int(j['stockQuantity'] ?? j['stock']),
      bulkDiscount: _num(j['bulkDiscount']),
      mainImage: (media['mainImage'] ?? j['mainImage'] ?? j['image'])?.toString(),
      gallery: gallery,
      status: j['status']?.toString(),
      createdAt: _parseDate(j['createdAt'] ?? j['created_at']),
      updatedAt: _parseDate(j['updatedAt'] ?? j['updated_at']),
      raw: j,
    );
  }

  static num? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  static int? _int(dynamic v) {
    final n = _num(v);
    return n?.toInt();
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) {
      return DateTime.fromMillisecondsSinceEpoch(v);
    }
    return null;
  }

  /// The payload the backend's `sanitizeWholesalePayload` understands.
  Map<String, dynamic> toRequestBody() => {
        'name': name,
        'shortDescription': shortDescription,
        'category': category,
        'unit': unit,
        'wholesalePrice': wholesalePrice ?? 0,
        'retailPrice': retailPrice ?? 0,
        'moq': moq ?? 1,
        'stockQuantity': stockQuantity ?? 0,
        'bulkDiscount': bulkDiscount ?? 0,
        'media': {
          'mainImage': mainImage ?? '',
          'gallery': gallery ?? const <String>[],
        },
        if (status != null) 'status': status,
      };

  String get display => name ?? 'Unnamed product';

  /// The backend flips status to `OUT_OF_STOCK` whenever stockQuantity <= 0.
  bool get isOutOfStock => (stockQuantity ?? 0) <= 0 || status?.toUpperCase() == 'OUT_OF_STOCK';
  bool get isArchived => status?.toUpperCase() == 'ARCHIVED';
  bool get isActive => status?.toUpperCase() == 'ACTIVE' && !isOutOfStock;

  /// No `minStock` exists on the wholesale model, so a low-stock warning is
  /// derived from the MOQ instead: fewer units left than one order needs.
  bool get isLowStock => !isOutOfStock && (stockQuantity ?? 0) < (moq ?? 1);

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  /// Wholesale price after the bulk discount is applied, which is what the
  /// supplier actually receives per unit at that volume.
  num get effectivePrice {
    final base = wholesalePrice ?? 0;
    final discount = (bulkDiscount ?? 0).clamp(0, 100);
    return base * (1 - discount / 100);
  }
}
