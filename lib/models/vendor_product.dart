import 'user.dart';


/// Coerces a JSON value to an int, tolerating strings and doubles.
int? _toInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : (v is String ? int.tryParse(v) : null));

/// Normalises a status slug: `"out-of-stock"` → `"OUT_OF_STOCK"`.
String? _toStatus(dynamic v) => v?.toString().trim().toUpperCase().replaceAll('-', '_');

/// A purchasable variation of a product (colour / size / weight). Vendors list
/// these as a flat list of specs rather than a full variant matrix, matching
/// how the storefront renders product options.
class ProductVariant {
  ProductVariant({this.id, this.color, this.size, this.weight, this.sku, this.stock, this.price});

  String? id;
  String? color;
  String? size;
  String? weight;
  String? sku;
  int? stock;
  num? price;

  factory ProductVariant.fromJson(Map<String, dynamic> j) {
    final attrs = j['attributes'] is Map ? Map<String, dynamic>.from(j['attributes']) : const <String, dynamic>{};
    return ProductVariant(
      id: j['_id'] ?? j['id'],
      color: j['color'] ?? j['colour'] ?? attrs['color'],
      size: j['size'] ?? attrs['size'],
      weight: j['weight'] ?? attrs['weight'],
      sku: j['sku'],
      stock: _toInt(j['stock'] ?? j['stockQuantity'] ?? j['quantity']),
      price: (j['price'] ?? j['salePrice']) as num?,
    );
  }

  bool get isEmpty =>
      (color == null || color!.trim().isEmpty) &&
      (size == null || size!.trim().isEmpty) &&
      (weight == null || weight!.trim().isEmpty) &&
      (sku == null || sku!.trim().isEmpty);

  /// Compact "Red · L · 500g" label for tables and chips.
  String get label {
    final parts = [
      if (color != null && color!.trim().isNotEmpty) color!.trim(),
      if (size != null && size!.trim().isNotEmpty) size!.trim(),
      if (weight != null && weight!.trim().isNotEmpty) weight!.trim(),
    ];
    return parts.isEmpty ? 'Default' : parts.join(' · ');
  }

  /// Payload for the product create/update endpoints; empty specs are dropped
  /// so the backend never receives a variant made only of empty strings.
  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (color != null && color!.trim().isNotEmpty) 'color': color!.trim(),
        if (size != null && size!.trim().isNotEmpty) 'size': size!.trim(),
        if (weight != null && weight!.trim().isNotEmpty) 'weight': weight!.trim(),
        if (sku != null && sku!.trim().isNotEmpty) 'sku': sku!.trim(),
        if (stock != null) 'stock': stock,
        if (price != null) 'price': price,
      };

  ProductVariant copy() => ProductVariant(
        id: id,
        color: color,
        size: size,
        weight: weight,
        sku: sku,
        stock: stock,
        price: price,
      );
}

/// A product in the vendor's own catalogue.
///
/// Extends the marketplace [ProductRecord] shape with the fields only the
/// owning vendor can edit: SKU, brand, variant specs, gallery media and the
/// availability status.
class VendorProduct {
  VendorProduct({
    this.id,
    this.name,
    this.sku,
    this.slug,
    this.brand,
    this.category,
    this.categoryId,
    this.description,
    this.price,
    this.discountPrice,
    this.stockQuantity,
    this.lowStockThreshold,
    this.status,
    this.thumbnail,
    this.images,
    this.variants,
    this.rating,
    this.sold,
    this.deleted,
    this.createdAt,
    this.updatedAt,
    this.raw,
  });

  String? id;
  String? name;
  String? sku;
  String? slug;
  String? brand;
  String? category;
  String? categoryId;
  String? description;
  num? price;
  num? discountPrice;
  int? stockQuantity;
  int? lowStockThreshold;

  /// One of [VendorProductStatus.all].
  String? status;

  String? thumbnail;
  List<String>? images;
  List<ProductVariant>? variants;
  double? rating;
  int? sold;
  bool? deleted;
  DateTime? createdAt;
  DateTime? updatedAt;
  Map<String, dynamic>? raw;

  factory VendorProduct.fromJson(Map<String, dynamic> j) {
    final category = j['category'];
    final variants = j['variants'];
    return VendorProduct(
      id: j['_id'] ?? j['id'],
      name: j['name'] ?? j['title'],
      sku: j['sku'] ?? j['productCode'],
      slug: j['slug'],
      brand: j['brand'],
      category: category is Map ? (category['name'] ?? category['_id'])?.toString() : category?.toString(),
      categoryId: category is Map ? category['_id']?.toString() : j['categoryId']?.toString(),
      description: j['description'] ?? j['details'],
      price: (j['price'] ?? j['regularPrice'] ?? j['basePrice']) as num?,
      discountPrice: (j['discountPrice'] ?? j['salePrice'] ?? j['sellingPrice']) as num?,
      stockQuantity: _toInt(j['stockQuantity'] ?? j['stock'] ?? j['quantity']),
      lowStockThreshold: _toInt(j['lowStockThreshold'] ?? j['lowStockAt'] ?? j['reorderPoint']),
      status: _toStatus(j['status'] ?? j['availability'] ?? (j['isActive'] == false ? VendorProductStatus.inactive : null)),
      thumbnail: _firstImage(j),
      images: _images(j),
      variants: variants is List
          ? variants
              .whereType<Map>()
              .map((e) => ProductVariant.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
      rating: (j['rating'] ?? j['averageRating'])?.toDouble(),
      sold: _toInt(j['sold'] ?? j['totalSold'] ?? j['unitsSold']),
      deleted: j['isDeleted'] is bool ? j['isDeleted'] : (j['deleted'] is bool ? j['deleted'] : null),
      createdAt: parseDate(j['createdAt']),
      updatedAt: parseDate(j['updatedAt']),
      raw: j,
    );
  }

  /// Collects every image reference the backend may use: `thumbnail`,
  /// `image`, or a `images` array of strings/objects.
  static List<String> _images(Map<String, dynamic> j) {
    final out = <String>[];
    final imgs = j['images'] ?? j['gallery'];
    if (imgs is List) {
      for (final f in imgs) {
        final url = f is String
            ? f
            : (f is Map ? (f['url'] ?? f['src'] ?? f['path'])?.toString() : null);
        if (url != null && url.trim().isNotEmpty) out.add(url.trim());
      }
    }
    for (final k in ['thumbnail', 'image', 'imageUrl']) {
      final v = j[k];
      if (v is String && v.trim().isNotEmpty) out.add(v.trim());
    }
    return out;
  }

  static String? _firstImage(Map<String, dynamic> j) {
    final all = _images(j);
    final thumb = j['thumbnail'] ?? j['image'] ?? j['imageUrl'];
    if (thumb is String && thumb.trim().isNotEmpty) return thumb.trim();
    return all.isEmpty ? null : all.first;
  }

  String get display => name ?? 'Unnamed product';

  /// Normalised availability status; a product with no status is live.
  String get availability => status ?? VendorProductStatus.active;

  /// Price the buyer actually pays, preferring the discount price.
  num? get effectivePrice => discountPrice ?? price;

  bool get hasDiscount => discountPrice != null && price != null && discountPrice! < price!;

  int get discountPercent {
    if (!hasDiscount || price == null || price == 0) return 0;
    return (((price! - discountPrice!) / price!) * 100).round();
  }

  /// At or below the reorder point. Threshold defaults to 5 units.
  bool get isLowStock {
    final qty = stockQuantity ?? 0;
    return qty > 0 && qty <= (lowStockThreshold ?? 5);
  }

  bool get isOutOfStock => (stockQuantity ?? 0) <= 0;

  /// Stock label for the list view: quantity plus a health suffix.
  String get stockLabel {
    final qty = stockQuantity ?? 0;
    if (isOutOfStock) return 'Out of stock';
    return isLowStock ? '$qty · Low' : '$qty';
  }

  List<ProductVariant> get variantList => variants ?? const <ProductVariant>[];

  /// The image list shown in the gallery editor: thumbnail first, then any
  /// additional gallery entries, de-duplicated.
  List<String> get gallery {
    final out = <String>[];
    for (final url in [thumbnail, ...?images]) {
      if (url != null && url.trim().isNotEmpty && !out.contains(url.trim())) out.add(url.trim());
    }
    return out;
  }

  /// Request body for the product create/update endpoints. Blank text fields
  /// are omitted so an edit never nulls out a value the vendor left alone.
  Map<String, dynamic> toBody() {
    final body = <String, dynamic>{
      'name': _v(name),
      'sku': _v(sku),
      'brand': _v(brand),
      'description': _v(description),
      'price': price,
      'discountPrice': discountPrice,
      'stockQuantity': stockQuantity,
      'lowStockThreshold': lowStockThreshold,
      'status': availability,
      'thumbnail': _v(thumbnail),
      'images': gallery.where((u) => u != thumbnail).toList(),
      'variants': [for (final v in variantList) if (!v.isEmpty) v.toJson()],
    };
    if (categoryId != null && categoryId!.isNotEmpty) {
      body['category'] = categoryId;
    } else if (category != null && category!.trim().isNotEmpty) {
      body['category'] = category!.trim();
    }
    body.removeWhere((_, v) => v == null);
    return body;
  }

  static Object? _v(String? s) {
    final t = (s ?? '').trim();
    return t.isEmpty ? null : t;
  }
}

/// Availability states a vendor can put a listing in.
class VendorProductStatus {
  VendorProductStatus._();

  static const active = 'ACTIVE';
  static const draft = 'DRAFT';
  static const outOfStock = 'OUT_OF_STOCK';
  static const inactive = 'INACTIVE';

  static const all = <String>[active, draft, outOfStock, inactive];

  /// Explanations shown under the status switch in the product form.
  static const descriptions = <String, String>{
    active: 'Visible in the marketplace and purchasable',
    draft: 'Saved but hidden from buyers while you finish it',
    outOfStock: 'Listed but cannot be ordered until you restock',
    inactive: 'Hidden from the marketplace; keeps its history',
  };

  /// Whether a listing in this state can accept orders.
  static bool isSellable(String status) => status == active;
}
