import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/api_config.dart';

/// A supplier's own wholesale catalogue item.
///
/// Mirrors `Mvec_backend/src/models/WholesaleProduct.js`: the entity is
/// wholesale-oriented, so it carries a `wholesalePrice` *and* a `retailPrice`,
/// a minimum order quantity, a bulk discount and a `media` object — none of
/// which belong on a retail marketplace product.
class SupplierProduct {
  const SupplierProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.stock,
    required this.status,
    this.shortDescription = '',
    this.unit = 'piece',
    this.retailPrice,
    this.minimumOrderQuantity = 1,
    this.bulkDiscount = 0,
    this.gallery = const <String>[],
  });

  final String id;
  final String name;
  final String category;
  final String description;

  /// `media.mainImage` in the backend payload.
  final String imageUrl;

  /// `wholesalePrice` — what the supplier charges per unit at MOQ volume.
  final double price;

  final int stock;

  /// One of `ACTIVE`, `OUT_OF_STOCK` (forced by the backend), `ARCHIVED`.
  final String status;

  final String shortDescription;

  /// Selling unit: `piece`, `kg`, `crate`…
  final String unit;

  final double? retailPrice;
  final int minimumOrderQuantity;

  /// Percentage 0–100.
  final double bulkDiscount;

  final List<String> gallery;

  factory SupplierProduct.fromJson(Map<String, dynamic> json) {
    final media = json['media'] is Map
        ? Map<String, dynamic>.from(json['media'] as Map)
        : const <String, dynamic>{};
    final rawGallery = media['gallery'] ?? json['gallery'];
    return SupplierProduct(
      id: _str(json['_id'] ?? json['id']),
      name: _str(json['name'] ?? json['title'], fallback: 'Untitled product'),
      category: _str(
        json['category'] ?? json['categoryName'],
        fallback: 'General',
      ),
      description: _str(json['shortDescription'] ?? json['description']),
      shortDescription: _str(json['shortDescription'] ?? json['description']),
      imageUrl: _str(
        media['mainImage'] ?? json['mainImage'] ?? json['imageUrl'] ?? json['image'],
      ),
      price:
          (json['wholesalePrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0,
      retailPrice:
          (json['retailPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble(),
      stock:
          (json['stockQuantity'] as num?)?.toInt() ??
          (json['stock'] as num?)?.toInt() ??
          0,
      status: _str(json['status'], fallback: 'ACTIVE'),
      unit: _str(json['unit'], fallback: 'piece'),
      minimumOrderQuantity:
          (json['moq'] as num?)?.toInt() ??
          (json['minimumOrderQuantity'] as num?)?.toInt() ??
          1,
      bulkDiscount: (json['bulkDiscount'] as num?)?.toDouble() ?? 0,
      gallery:
          rawGallery is List
              ? rawGallery.map((e) => e.toString()).toList()
              : const <String>[],
    );
  }

  /// The payload the backend's `sanitizeWholesalePayload` understands.
  ///
  /// Deliberately limited to the seven fields the web supplier form collects:
  /// name, category, wholesale price, MOQ, stock, bulk discount, description.
  ///
  /// `unit`, `retailPrice`, `media` and `status` are omitted on purpose. The
  /// supplier form no longer collects them, and every one has a safe backend
  /// default on create (`unit: "piece"`, `retailPrice: 0`, empty `media`,
  /// `status: "ACTIVE"` demoted to `OUT_OF_STOCK` when stock is 0). On update
  /// `sanitizeWholesalePayload` falls back to the stored product, so omitting
  /// them preserves existing data instead of blanking it.
  Map<String, dynamic> toJson() => {
    'name': name,
    // The backend's WholesaleProduct has no `description` field; the long text
    // is stored as `shortDescription`.
    'shortDescription': description,
    'category': category,
    'wholesalePrice': price,
    'moq': minimumOrderQuantity,
    'stockQuantity': stock,
    'bulkDiscount': bulkDiscount,
  };

  SupplierProduct copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? imageUrl,
    double? price,
    double? retailPrice,
    int? stock,
    String? status,
    String? unit,
    int? minimumOrderQuantity,
    double? bulkDiscount,
    List<String>? gallery,
  }) => SupplierProduct(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    description: description ?? this.description,
    shortDescription: description ?? shortDescription,
    imageUrl: imageUrl ?? this.imageUrl,
    price: price ?? this.price,
    retailPrice: retailPrice ?? this.retailPrice,
    stock: stock ?? this.stock,
    status: status ?? this.status,
    unit: unit ?? this.unit,
    minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
    bulkDiscount: bulkDiscount ?? this.bulkDiscount,
    gallery: gallery ?? this.gallery,
  );

  /// The backend flips status to `OUT_OF_STOCK` whenever `stockQuantity <= 0`,
  /// so it is not a choice the supplier can make.
  bool get isOutOfStock => stock <= 0 || status.toUpperCase() == 'OUT_OF_STOCK';
  bool get isArchived => status.toUpperCase() == 'ARCHIVED';
  bool get isActive => status.toUpperCase() == 'ACTIVE' && !isOutOfStock;

  /// There is no `minStock` on the wholesale model, so low stock is derived
  /// from the MOQ: fewer units left than one order needs.
  bool get isLowStock => !isOutOfStock && stock < minimumOrderQuantity;

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  /// Unit price after the bulk discount, i.e. what a vendor actually pays.
  double get effectivePrice =>
      price * (1 - bulkDiscount.clamp(0, 100) / 100);
}

/// A wholesale order placed against the supplier's catalogue.
///
/// The backend has no `/supplier/orders` route, so these are read from the
/// role-scoped `GET /orders` collection — see [ApiSupplierWorkspaceService].
class SupplierOrder {
  const SupplierOrder({
    required this.id,
    required this.buyer,
    required this.product,
    required this.quantity,
    required this.total,
    required this.status,
    required this.requestedAt,
  });

  final String id;
  final String buyer;
  final String product;
  final int quantity;
  final double total;
  final String status;
  final DateTime requestedAt;

  factory SupplierOrder.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'] ?? json['buyerName'] ?? json['vendor'];
    final items = json['items'];
    final first = items is List && items.isNotEmpty ? items.first : null;
    final firstItem = first is Map ? Map<String, dynamic>.from(first) : null;
    final product =
        firstItem?['name'] ?? json['productName'] ?? json['product'] ?? 'Supplier item';
    return SupplierOrder(
      id: _str(json['_id'] ?? json['id'] ?? json['orderNumber']),
      buyer:
          buyer is Map
              ? _str(
                buyer['businessName'] ?? buyer['Fullname'] ?? buyer['name'],
                fallback: 'Marketplace buyer',
              )
              : _str(buyer, fallback: 'Marketplace buyer'),
      product: _str(product, fallback: 'Supplier item'),
      quantity:
          (firstItem?['quantity'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          1,
      total:
          (json['total'] as num?)?.toDouble() ??
          (json['totalAmount'] as num?)?.toDouble() ??
          0,
      status: _str(json['status'] ?? json['fulfillmentStatus'], fallback: 'Pending'),
      requestedAt:
          DateTime.tryParse(_str(json['createdAt'] ?? json['requestedAt'])) ??
          DateTime.now(),
    );
  }
}

/// A supplier-facing notification, read from the role-scoped
/// `GET /notifications` collection.
class SupplierNotice {
  const SupplierNotice({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;

  factory SupplierNotice.fromJson(Map<String, dynamic> json) {
    final status = _str(json['status']).toUpperCase();
    return SupplierNotice(
      id: _str(json['_id'] ?? json['id']),
      title: _str(
        json['title'] ?? json['type'],
        fallback: 'Supplier update',
      ),
      message: _str(json['message'] ?? json['body']),
      createdAt:
          DateTime.tryParse(_str(json['createdAt'])) ?? DateTime.now(),
      read: json['read'] == true || status == 'READ',
    );
  }
}

/// The supplier's own business record.
///
/// Mirrors `Mvec_backend/src/models/Supplier.js`: business identity, contact
/// details, a verification state and a `ratingAvg`. `verificationStatus` is
/// owned by the admin — a supplier can read it but never change it.
class SupplierProfile {
  const SupplierProfile({
    required this.businessName,
    required this.email,
    required this.phone,
    required this.address,
    required this.orderNotifications,
    required this.stockNotifications,
    this.id = '',
    this.publicId,
    this.slug,
    this.description = '',
    this.logoUrl = '',
    this.verificationStatus = 'UNVERIFIED',
    this.accountStatus = 'ACTIVE',
    this.ratingAvg,
  });

  final String id;

  /// Human-facing id, e.g. `MVEC-SUP-1A2B3C4D`.
  final String? publicId;
  final String businessName;
  final String? slug;
  final String description;
  final String logoUrl;
  final String email;
  final String phone;
  final String address;

  /// One of `UNVERIFIED`, `PENDING`, `VERIFIED`, `REJECTED`.
  final String verificationStatus;

  /// One of `ACTIVE`, `SUSPENDED`, `BLOCKED`, `UNDER_REVIEW`.
  final String accountStatus;
  final double? ratingAvg;

  final bool orderNotifications;
  final bool stockNotifications;

  factory SupplierProfile.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    return SupplierProfile(
      id: _str(json['_id'] ?? json['id']),
      publicId: json['publicId']?.toString(),
      businessName: _str(json['businessName'] ?? json['companyName']),
      slug: json['slug']?.toString(),
      description: _str(json['description']),
      logoUrl: _str(json['logoUrl']),
      email: _str(json['email']),
      phone: _str(json['phone']),
      address: _str(
        location is Map ? location['name'] : location,
      ),
      verificationStatus: _str(
        json['verificationStatus'],
        fallback: 'UNVERIFIED',
      ),
      accountStatus: _str(json['status'], fallback: 'ACTIVE'),
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble(),
      orderNotifications: json['orderNotifications'] != false,
      stockNotifications: json['stockNotifications'] != false,
    );
  }

  /// The payload `POST /suppliers/onboard` and `PATCH /suppliers/me/profile`
  /// accept — `businessName`, `description`, `phone`, `email` and `logoUrl`.
  /// Keys outside that set are dropped server-side, so they are not sent.
  Map<String, dynamic> toJson() => {
    'businessName': businessName,
    'description': description,
    'email': email,
    'phone': phone,
    'logoUrl': logoUrl,
    if (publicId != null) 'publicId': publicId,
  };

  String get display => businessName.isEmpty ? 'Unnamed supplier' : businessName;

  String get verificationStatusOrDefault =>
      verificationStatus.isEmpty ? 'UNVERIFIED' : verificationStatus;

  bool get isVerified => verificationStatusOrDefault == 'VERIFIED';
  bool get isPending =>
      verificationStatusOrDefault == 'PENDING' ||
      verificationStatusOrDefault == 'UNDER_REVIEW';
  bool get isRejected => verificationStatusOrDefault == 'REJECTED';
  bool get isSuspended =>
      accountStatus.toUpperCase() == 'SUSPENDED' ||
      accountStatus.toUpperCase() == 'BLOCKED';

  /// Shows the verification state when one applies, otherwise the account
  /// state, so the portal always has something meaningful to render.
  String get effectiveStatus {
    if (isVerified) return 'VERIFIED';
    if (isPending) return 'PENDING';
    if (isRejected) return 'REJECTED';
    return accountStatus.toUpperCase();
  }

  /// True until the profile exists — `GET /suppliers/me/profile` 404s in this
  /// state, which is a normal first-run state rather than a failure.
  bool get isOnboarded => businessName.isNotEmpty;
}

/// Dashboard counters derived from the catalogue.
///
/// The backend exposes no metrics endpoint, so [SupplierMetrics.fromCatalog]
/// computes the inventory figures from the supplier's own product list. The
/// commerce figures (revenue, order count) come from the order list instead of
/// being invented.
class SupplierMetrics {
  const SupplierMetrics({
    this.totalProducts = 0,
    this.activeProducts = 0,
    this.lowStockProducts = 0,
    this.outOfStockProducts = 0,
    this.totalUnitsInStock = 0,
    this.totalCatalogValue = 0,
    this.openOrders = 0,
    this.salesTotal = 0,
    this.protectedFunds = 0,
  });

  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int totalUnitsInStock;

  /// Sum of `wholesalePrice * stockQuantity` across the catalogue.
  final double totalCatalogValue;

  final int openOrders;

  /// Value of the completed orders.
  final double salesTotal;

  /// Value of the orders that are paid but not yet fulfilled — held by MVEC
  /// until delivery is confirmed.
  final double protectedFunds;

  factory SupplierMetrics.fromCatalog(
    List<SupplierProduct> products, {
    List<SupplierOrder> orders = const <SupplierOrder>[],
  }) {
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
      units += p.stock;
      value += p.price * p.stock;
    }

    var open = 0;
    var sales = 0.0;
    var held = 0.0;
    for (final o in orders) {
      final status = o.status.toLowerCase();
      if (status == 'completed' || status == 'delivered') {
        sales += o.total;
      } else if (status != 'pending' && status != 'cancelled') {
        open++;
        held += o.total;
      }
    }

    return SupplierMetrics(
      totalProducts: products.length,
      activeProducts: active,
      lowStockProducts: low,
      outOfStockProducts: out,
      totalUnitsInStock: units,
      totalCatalogValue: value,
      openOrders: open,
      salesTotal: sales,
      protectedFunds: held,
    );
  }

  bool get hasInventory => totalProducts > 0;
}

class SupplierWorkspaceData {
  const SupplierWorkspaceData({
    required this.products,
    required this.orders,
    required this.notifications,
    required this.profile,
    this.ordersUnavailable = false,
    this.notificationsUnavailable = false,
  });

  final List<SupplierProduct> products;
  final List<SupplierOrder> orders;
  final List<SupplierNotice> notifications;
  final SupplierProfile profile;

  /// `GET /orders` is admin-only on the backend, so a supplier gets 403 rather
  /// than an empty list. The Orders page needs to tell those apart to avoid
  /// claiming "no orders yet" when the truth is "not readable by your role".
  final bool ordersUnavailable;

  /// `GET /notifications/mine` should always work; flag it only so the page can
  /// report a genuine fault instead of a false "you're all caught up".
  final bool notificationsUnavailable;

  SupplierMetrics get metrics => SupplierMetrics.fromCatalog(
    products,
    orders: orders,
  );
}

abstract interface class SupplierWorkspaceService {
  Future<List<SupplierProduct>> products();
  Future<List<SupplierOrder>> orders();
  Future<List<SupplierNotice>> notifications();
  Future<SupplierProfile> profile();
  /// Creates the product when [SupplierProduct.id] is empty, otherwise updates
  /// the existing one.
  Future<void> saveProduct(SupplierProduct product);
  Future<void> deleteProduct(String id);
  Future<void> updateStock(String id, int stock);
  Future<void> updateOrderStatus(String id, String status);
  Future<void> markNotificationRead(String id);
  Future<void> saveProfile(SupplierProfile profile, {required bool isNewProfile});
}

class DemoSupplierWorkspaceService implements SupplierWorkspaceService {
  final List<SupplierProduct> _products = [
    const SupplierProduct(
      id: 'sp-101',
      name: 'Arabica Coffee Beans',
      category: 'Beverages',
      description: 'Washed specialty beans from Nyamasheke, medium roast.',
      imageUrl: 'https://picsum.photos/seed/mvec-coffee/320/240',
      price: 12500,
      stock: 84,
      status: 'ACTIVE',
      minimumOrderQuantity: 10,
      bulkDiscount: 8,
      retailPrice: 16000,
      unit: 'kg',
    ),
    const SupplierProduct(
      id: 'sp-102',
      name: 'Fresh Avocados',
      category: 'Produce',
      description: 'Ripe Hass avocados, packed in reusable crates.',
      imageUrl: 'https://picsum.photos/seed/mvec-avocado/320/240',
      price: 900,
      stock: 12,
      status: 'ACTIVE',
      minimumOrderQuantity: 5,
      bulkDiscount: 5,
      unit: 'crate',
    ),
    const SupplierProduct(
      id: 'sp-103',
      name: 'Dried Red Kidney Beans',
      category: 'Grains & pulses',
      description: 'Sorted, clean and ready for wholesale delivery.',
      imageUrl: 'https://picsum.photos/seed/mvec-beans/320/240',
      price: 2400,
      stock: 0,
      status: 'OUT_OF_STOCK',
      minimumOrderQuantity: 10,
      bulkDiscount: 8,
      unit: 'kg',
    ),
    const SupplierProduct(
      id: 'sp-104',
      name: 'Raw Forest Honey',
      category: 'Pantry',
      description: 'Unfiltered honey sourced from local beekeepers.',
      imageUrl: 'https://picsum.photos/seed/mvec-honey/320/240',
      price: 7800,
      stock: 31,
      status: 'ACTIVE',
      minimumOrderQuantity: 5,
      bulkDiscount: 5,
      unit: 'jar',
    ),
  ];

  final List<SupplierOrder> _orders = [
    SupplierOrder(
      id: 'MV-4821',
      buyer: 'Kigali Market Kitchen',
      product: 'Arabica Coffee Beans',
      quantity: 8,
      total: 100000,
      status: 'Pending',
      requestedAt: DateTime(2026, 9, 28),
    ),
    SupplierOrder(
      id: 'MV-4814',
      buyer: 'Green Basket Ltd',
      product: 'Fresh Avocados',
      quantity: 24,
      total: 21600,
      status: 'Confirmed',
      requestedAt: DateTime(2026, 9, 27),
    ),
    SupplierOrder(
      id: 'MV-4792',
      buyer: 'Umurimo Grocers',
      product: 'Raw Forest Honey',
      quantity: 6,
      total: 46800,
      status: 'Ready to ship',
      requestedAt: DateTime(2026, 9, 25),
    ),
    SupplierOrder(
      id: 'MV-4760',
      buyer: 'Kivu Cafe',
      product: 'Arabica Coffee Beans',
      quantity: 4,
      total: 50000,
      status: 'Completed',
      requestedAt: DateTime(2026, 9, 22),
    ),
  ];

  final List<SupplierNotice> _notifications = [
    SupplierNotice(
      id: 'sn-1',
      title: 'New order request',
      message:
          'Kigali Market Kitchen requested 8 bags of Arabica Coffee Beans.',
      createdAt: DateTime(2026, 9, 28, 9),
      read: false,
    ),
    SupplierNotice(
      id: 'sn-2',
      title: 'Low stock reminder',
      message: 'Fresh Avocados are down to 12 units.',
      createdAt: DateTime(2026, 9, 27, 14),
      read: false,
    ),
    SupplierNotice(
      id: 'sn-3',
      title: 'Payout processed',
      message: 'Your RWF 50,000 payout for MV-4760 is complete.',
      createdAt: DateTime(2026, 9, 23, 11),
      read: true,
    ),
  ];

  SupplierProfile _profile = const SupplierProfile(
    id: 'demo-supplier',
    publicId: 'MVEC-SUP-7F3A21C4',
    businessName: 'Rwanda Fresh Produce Co.',
    description:
        'Wholesale produce and pantry goods sourced from cooperatives across '
        'Rwanda.',
    email: 'supplier@mvec.rw',
    phone: '+250 788 245 610',
    address: 'KN 5 Road, Kigali, Rwanda',
    verificationStatus: 'VERIFIED',
    accountStatus: 'ACTIVE',
    ratingAvg: 4.6,
    orderNotifications: true,
    stockNotifications: true,
  );

  @override
  Future<List<SupplierProduct>> products() async =>
      List.unmodifiable(_products);
  @override
  Future<List<SupplierOrder>> orders() async => List.unmodifiable(_orders);
  @override
  Future<List<SupplierNotice>> notifications() async =>
      List.unmodifiable(_notifications);
  @override
  Future<SupplierProfile> profile() async => _profile;

  @override
  Future<void> saveProduct(SupplierProduct product) async {
    final index = _products.indexWhere((item) => item.id == product.id);
    // The backend forces `OUT_OF_STOCK` whenever `stockQuantity <= 0`, so the
    // status follows the stock rather than being set independently.
    final status = product.stock == 0 ? 'OUT_OF_STOCK' : product.status;
    if (index < 0) {
      _products.insert(
        0,
        product.copyWith(
          id: 'sp-${DateTime.now().microsecondsSinceEpoch}',
          status: status,
        ),
      );
    } else {
      _products[index] = product.copyWith(status: status);
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    _products.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> updateStock(String id, int stock) async {
    final index = _products.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Product not found');
    _products[index] = _products[index].copyWith(
      stock: stock,
      status: stock == 0 ? 'OUT_OF_STOCK' : 'ACTIVE',
    );
  }

  @override
  Future<void> updateOrderStatus(String id, String status) async {
    final index = _orders.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Order not found');
    final order = _orders[index];
    _orders[index] = SupplierOrder(
      id: order.id,
      buyer: order.buyer,
      product: order.product,
      quantity: order.quantity,
      total: order.total,
      status: status,
      requestedAt: order.requestedAt,
    );
  }

  @override
  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final notice = _notifications[index];
    _notifications[index] = SupplierNotice(
      id: notice.id,
      title: notice.title,
      message: notice.message,
      createdAt: notice.createdAt,
      read: true,
    );
  }

  @override
  Future<void> saveProfile(
    SupplierProfile profile, {
    required bool isNewProfile,
  }) async => _profile = profile;
}

/// Live supplier portal, backed by the marketplace backend.
///
/// Every supplier route is resolved from the bearer token (`/me/*`), so no
/// supplier id is ever sent by the app. The catalogue and profile come from
/// `supplier.routes.js`; orders and notifications have no supplier-scoped
/// route, so they are read from the token-scoped collections the rest of the
/// app already uses. A missing collection degrades to an empty list instead of
/// failing the whole workspace.
class ApiSupplierWorkspaceService implements SupplierWorkspaceService {
  ApiSupplierWorkspaceService(this._api);
  final ApiClient _api;

  /// `GET /suppliers/me/products` → `{ success, supplier, count, products }`.
  /// The backend returns the whole catalogue unpaginated.
  @override
  Future<List<SupplierProduct>> products() async =>
      listJson(await _api.get('/suppliers/me/products'), [
        'products',
        'data',
      ]).map(SupplierProduct.fromJson).toList();

  /// `GET /orders`, scoped to the signed-in supplier by the bearer token.
  @override
  Future<List<SupplierOrder>> orders() async =>
      _tolerant(
        () async =>
            listJson(await _api.get('/orders'), ['orders', 'data'])
                .map(SupplierOrder.fromJson)
                .toList(),
      );

  /// `GET /notifications/mine?limit=200` → `{ data, meta }`.
  ///
  /// Must be `/mine`: the collection root `GET /api/notifications` is the admin
  /// oversight route (`authorize("super_admin")`) and 403s for a supplier.
  @override
  Future<List<SupplierNotice>> notifications() async =>
      _tolerant(
        () async =>
            listJson(
              await _api.get('/notifications/mine', query: {'limit': '200'}),
              ['data', 'notifications'],
            ).map(SupplierNotice.fromJson).toList(),
      );

  /// `GET /suppliers/me/profile` → `{ supplier }`.
  ///
  /// 404s until onboarding is complete. That is a normal first-run state, so it
  /// becomes an empty profile and the portal offers onboarding instead of an
  /// error state.
  @override
  Future<SupplierProfile> profile() async {
    try {
      return SupplierProfile.fromJson(
        singleJson(await _api.get('/suppliers/me/profile'), [
          'supplier',
          'profile',
          'data',
        ]),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return const SupplierProfile(
          businessName: '',
          email: '',
          phone: '',
          address: '',
          orderNotifications: true,
          stockNotifications: true,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> saveProduct(SupplierProduct product) async {
    if (product.id.isEmpty) {
      await _api.post('/suppliers/me/products', body: product.toJson());
    } else {
      await _api.put(
        '/suppliers/me/products/${product.id}',
        body: product.toJson(),
      );
    }
  }

  @override
  Future<void> deleteProduct(String id) =>
      _api.delete('/suppliers/me/products/$id');

  /// `PUT` replaces the whole wholesale document, so a stock change is sent as
  /// a full payload rather than a partial one that would blank the rest.
  @override
  Future<void> updateStock(String id, int stock) async {
    final current = (await products()).where((p) => p.id == id).firstOrNull;
    if (current == null) throw StateError('Product not found');
    await saveProduct(
      current.copyWith(
        stock: stock,
        status: stock == 0 ? 'OUT_OF_STOCK' : 'ACTIVE',
      ),
    );
  }

  @override
  Future<void> updateOrderStatus(String id, String status) =>
      _api.patch('/orders/$id/status', body: {'status': status});

  /// `PATCH /notifications/:id/read` — the backend exposes this as a PATCH;
  /// there is no POST twin, so the verb has to match or it 404s.
  @override
  Future<void> markNotificationRead(String id) =>
      _api.patch('/notifications/$id/read');

  /// `POST /suppliers/onboard` creates the profile; `PATCH
  /// /suppliers/me/profile` updates it. A 404 from [profile] is what signals
  /// "not onboarded yet".
  @override
  Future<void> saveProfile(
    SupplierProfile profile, {
    required bool isNewProfile,
  }) async {
    if (isNewProfile) {
      await _api.post('/suppliers/onboard', body: profile.toJson());
    } else {
      await _api.patch('/suppliers/me/profile', body: profile.toJson());
    }
  }

  /// Keeps a secondary collection from taking the whole portal down: a route
  /// the backend does not expose yet yields an empty list, not an error.
  Future<List<T>> _tolerant<T>(Future<List<T>> Function() load) async {
    try {
      return await load();
    } on ApiException {
      return const [];
    }
  }
}

String _str(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value is Map || value is List ? fallback : value.toString();
  return text.isEmpty ? fallback : text;
}

final supplierWorkspaceServiceProvider = Provider<SupplierWorkspaceService>(
  (ref) =>
      kDemoMode
          ? DemoSupplierWorkspaceService()
          : ApiSupplierWorkspaceService(ref.watch(apiProvider)),
);

final supplierWorkspaceProvider =
    AsyncNotifierProvider<SupplierWorkspaceController, SupplierWorkspaceData>(
      SupplierWorkspaceController.new,
    );

class SupplierWorkspaceController extends AsyncNotifier<SupplierWorkspaceData> {
  late SupplierWorkspaceService _service;

  @override
  Future<SupplierWorkspaceData> build() async {
    _service = ref.watch(supplierWorkspaceServiceProvider);
    return _load();
  }

  Future<SupplierWorkspaceData> _load() async {
    // Each section loads independently and in its own error scope. A single
    // unreadable endpoint used to fail this Future.wait, which flipped the one
    // shared provider into AsyncError and blanked *every* supplier page — even
    // pages whose own endpoints were fine. Now a failure degrades only its own
    // section, and the page says so honestly.
    var ordersUnavailable = false;
    var notificationsUnavailable = false;

    final results = await Future.wait<dynamic>([
      _service.products(),
      _service.orders().catchError((Object _) {
        ordersUnavailable = true;
        return <SupplierOrder>[];
      }),
      _service.notifications().catchError((Object _) {
        notificationsUnavailable = true;
        return <SupplierNotice>[];
      }),
      _service.profile(),
    ]);

    return SupplierWorkspaceData(
      products: results[0] as List<SupplierProduct>,
      orders: results[1] as List<SupplierOrder>,
      notifications: results[2] as List<SupplierNotice>,
      profile: results[3] as SupplierProfile,
      ordersUnavailable: ordersUnavailable,
      notificationsUnavailable: notificationsUnavailable,
    );
  }

  Future<void> _change(Future<void> Function() action) async {
    state = const AsyncLoading<SupplierWorkspaceData>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await action();
      return _load();
    });
  }

  Future<void> saveProduct(SupplierProduct product) =>
      _change(() => _service.saveProduct(product));
  Future<void> deleteProduct(String id) =>
      _change(() => _service.deleteProduct(id));
  Future<void> updateStock(String id, int stock) =>
      _change(() => _service.updateStock(id, stock));
  Future<void> updateOrderStatus(String id, String status) =>
      _change(() => _service.updateOrderStatus(id, status));
  Future<void> markNotificationRead(String id) =>
      _change(() => _service.markNotificationRead(id));
  /// `isNewProfile` keys off the record's identity, not off whether the user
  /// typed a business name: `id` is empty exactly when `GET
  /// /suppliers/me/profile` 404s, which is the first-run state. Deriving it
  /// from [SupplierProfile.isOnboarded] would PATCH a supplier that does not
  /// exist yet, since onboarding requires a non-empty `businessName`.
  Future<void> saveProfile(SupplierProfile profile) =>
      _change(
        () => _service.saveProfile(profile, isNewProfile: profile.id.isEmpty),
      );

  /// True once the supplier has a business profile, i.e. `GET
  /// /suppliers/me/profile` no longer 404s.
  bool get isOnboarded => state.valueOrNull?.profile.isOnboarded ?? false;
}