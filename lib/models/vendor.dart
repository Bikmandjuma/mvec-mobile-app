import '../core/utils.dart';
import 'user.dart';

/// Verification states a store moves through, in pipeline order:
/// submit documents → under review → verified or rejected.
class VendorVerification {
  VendorVerification._();

  static const unverified = 'UNVERIFIED';
  static const pending = 'PENDING';
  static const verified = 'VERIFIED';
  static const rejected = 'REJECTED';

  static const all = <String>[unverified, pending, verified, rejected];
}

/// Operational status of the vendor account, set by the platform. Distinct
/// from [VendorVerification]: a store can be `VERIFIED` yet `SUSPENDED`.
class VendorAccountStatus {
  VendorAccountStatus._();

  static const active = 'ACTIVE';
  static const suspended = 'SUSPENDED';
  static const blocked = 'BLOCKED';
  static const underReview = 'UNDER_REVIEW';

  static const all = <String>[active, underReview, suspended, blocked];
}

/// One uploaded verification document (business registration, tax id, …).
class VerificationDocument {
  VerificationDocument({
    this.id,
    this.type,
    this.label,
    this.url,
    this.status,
    this.uploadedAt,
  });

  String? id;
  String? type;
  String? label;
  String? url;
  String? status;
  DateTime? uploadedAt;

  factory VerificationDocument.fromJson(Map<String, dynamic> j) => VerificationDocument(
        id: j['_id'] ?? j['id'],
        type: j['type'] ?? j['documentType'] ?? j['kind'],
        label: j['label'] ?? j['name'] ?? j['title'],
        url: j['url'] ?? j['file'] ?? j['fileUrl'] ?? j['path'],
        status: j['status'],
        uploadedAt: parseDate(j['uploadedAt'] ?? j['createdAt']),
      );

  /// Human label for the document type, falling back to the type slug.
  String get display {
    if (label != null && label!.trim().isNotEmpty) return label!;
    final t = type ?? '';
    if (t.isEmpty) return 'Document';
    return titleCase(t);
  }
}

/// The vendor's own store, as returned by `GET /stores/mine`.
///
/// Deliberately all-nullable with defensive cascade reads: the store resource
/// is written by both vendors (profile form) and the platform (verification,
/// suspensions), so its shape varies between those writers.
class StoreProfile {
  StoreProfile({
    this.id,
    this.name,
    this.slug,
    this.logo,
    this.description,
    this.email,
    this.phone,
    this.facebook,
    this.instagram,
    this.twitter,
    this.website,
    this.street,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.deliveryNote,
    this.deliveryFee,
    this.deliveryTime,
    this.verificationStatus,
    this.status,
    this.rating,
    this.ratingCount,
    this.productCount,
    this.submittedAt,
    this.rejectionReason,
    this.documents,
    this.raw,
  });

  String? id;
  String? name;
  String? slug;
  String? logo;
  String? description;
  String? email;
  String? phone;
  String? facebook;
  String? instagram;
  String? twitter;
  String? website;
  String? street;
  String? city;
  String? state;
  String? country;
  String? postalCode;
  String? deliveryNote;
  num? deliveryFee;
  String? deliveryTime;

  /// One of [VendorVerification.all].
  String? verificationStatus;

  /// One of [VendorAccountStatus.all].
  String? status;

  double? rating;
  int? ratingCount;
  int? productCount;
  DateTime? submittedAt;
  String? rejectionReason;
  List<VerificationDocument>? documents;
  Map<String, dynamic>? raw;

  factory StoreProfile.fromJson(Map<String, dynamic> j) {
    final addr = j['address'] is Map ? Map<String, dynamic>.from(j['address']) : const <String, dynamic>{};
    final socials = j['socials'] is Map ? Map<String, dynamic>.from(j['socials']) : const <String, dynamic>{};
    final contact = j['contact'] is Map ? Map<String, dynamic>.from(j['contact']) : const <String, dynamic>{};
    final owner = j['owner'] is Map ? Map<String, dynamic>.from(j['owner']) : const <String, dynamic>{};
    final docs = j['documents'];
    return StoreProfile(
      id: j['_id'] ?? j['id'],
      name: j['storeName'] ?? j['businessName'] ?? j['name'] ?? j['companyName'],
      slug: j['slug'],
      logo: j['logo'] ?? j['logoUrl'] ?? j['image'],
      description: j['description'] ?? j['about'] ?? j['bio'],
      email: j['email'] ?? contact['email'] ?? owner['email'],
      phone: j['phone'] ?? j['telephone'] ?? j['contactNumber'] ?? contact['phone'] ?? owner['phone'],
      facebook: j['facebook'] ?? j['facebookUrl'] ?? socials['facebook'],
      instagram: j['instagram'] ?? j['instagramUrl'] ?? socials['instagram'],
      twitter: j['twitter'] ?? j['twitterUrl'] ?? socials['twitter'] ?? j['x'],
      website: j['website'] ?? j['webUrl'] ?? socials['website'],
      street: j['street'] ?? j['addressLine'] ?? addr['street'] ?? addr['address'],
      city: j['city'] ?? j['town'] ?? addr['city'],
      state: j['state'] ?? j['province'] ?? addr['state'] ?? addr['province'],
      country: j['country'] ?? addr['country'],
      postalCode: j['postalCode'] ?? j['zip'] ?? j['zipCode'] ?? addr['postalCode'] ?? addr['zip'],
      deliveryNote: j['deliveryNote'] ?? j['deliveryInstructions'] ?? (j['delivery'] is Map ? (j['delivery'] as Map)['note']?.toString() : null),
      deliveryFee: (j['deliveryFee'] ?? (j['delivery'] is Map ? (j['delivery'] as Map)['fee'] : null)) as num?,
      deliveryTime: j['deliveryTime'] ?? (j['delivery'] is Map ? (j['delivery'] as Map)['time']?.toString() : null),
      verificationStatus: _up(j['verificationStatus'] ?? j['verification'] ?? j['verified']),
      status: _up(j['status'] ?? j['accountStatus'] ?? j['operationalStatus']),
      rating: (j['rating'] ?? j['averageRating'] ?? j['storeRating'])?.toDouble(),
      ratingCount: _int(j['ratingCount'] ?? j['totalRatings'] ?? j['reviewsCount']),
      productCount: _int(j['productCount'] ?? j['productsCount'] ?? j['totalProducts']),
      submittedAt: parseDate(j['submittedAt'] ?? j['verificationSubmittedAt'] ?? j['createdAt']),
      rejectionReason: j['rejectionReason'] ?? j['verificationNote'] ?? j['rejectionNote'],
      documents: docs is List
          ? docs
              .whereType<Map>()
              .map((e) => VerificationDocument.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
      raw: j,
    );
  }

  static String? _up(dynamic v) => v?.toString().trim().toUpperCase().replaceAll('-', '_');

  static int? _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : (v is String ? int.tryParse(v) : null));

  String get display => name ?? 'Unnamed store';

  /// Normalised verification status; a store with no record yet is unverified.
  String get verification =>
      verificationStatus == null || verificationStatus!.isEmpty ? VendorVerification.unverified : verificationStatus!;

  /// Normalised account status; a store with no record yet is active.
  String get accountStatus => status == null || status!.isEmpty ? VendorAccountStatus.active : status!;

  bool get isVerified => verification == VendorVerification.verified;

  /// The vendor still owes the platform documents, or is waiting on a decision.
  bool get needsVerification =>
      verification == VendorVerification.unverified || verification == VendorVerification.pending;

  /// The store can trade: verified and not blocked by the platform.
  bool get canOperate =>
      isVerified &&
      accountStatus != VendorAccountStatus.blocked &&
      accountStatus != VendorAccountStatus.suspended;

  /// Document types the platform asks for before it can verify a store.
  static const requiredDocumentTypes = <String>[
    'BUSINESS_REGISTRATION',
    'TAX_ID',
    'PROOF_OF_ADDRESS',
  ];

  /// Required document types the vendor has not supplied yet.
  List<String> get missingDocuments {
    final have = (documents ?? const <VerificationDocument>[])
        .map((d) => (d.type ?? '').trim().toUpperCase().replaceAll('-', '_'))
        .toSet();
    return [
      for (final t in requiredDocumentTypes)
        if (!have.contains(t)) t,
    ];
  }

  /// The request body for `PUT /stores`.
  ///
  /// Only non-empty fields are sent so a partial edit never blanks a value the
  /// vendor did not touch.
  Map<String, dynamic> toBody() => {
        'storeName': _v(name),
        'description': _v(description),
        'logo': _v(logo),
        'email': _v(email),
        'phone': _v(phone),
        'facebook': _v(facebook),
        'instagram': _v(instagram),
        'twitter': _v(twitter),
        'website': _v(website),
        'street': _v(street),
        'city': _v(city),
        'state': _v(state),
        'country': _v(country),
        'postalCode': _v(postalCode),
        'deliveryNote': _v(deliveryNote),
        'deliveryFee': deliveryFee,
        'deliveryTime': _v(deliveryTime),
      }..removeWhere((_, v) => v == null);

  static Object? _v(String? s) {
    final t = (s ?? '').trim();
    return t.isEmpty ? null : t;
  }
}

/// One row in the unified vendor activity timeline: a financial, order or
/// operational event. The backend returns them interleaved in a single feed.
class VendorActivity {
  VendorActivity({
    this.id,
    this.type,
    this.title,
    this.description,
    this.amount,
    this.status,
    this.reference,
    this.product,
    this.date,
    this.raw,
  });

  String? id;

  /// Raw type from the API; see [bucket] for the normalised filter value.
  String? type;

  String? title;
  String? description;
  num? amount;
  String? status;
  String? reference;
  String? product;
  DateTime? date;
  Map<String, dynamic>? raw;

  factory VendorActivity.fromJson(Map<String, dynamic> j) {
    final product = j['product'];
    return VendorActivity(
      id: j['_id'] ?? j['id'] ?? j['entryId'],
      type: j['type'] ?? j['activityType'] ?? j['entryType'] ?? j['category'],
      title: j['title'] ?? j['event'] ?? j['name'] ?? j['narration'] ?? j['description'],
      description: j['description'] ?? j['details'] ?? j['note'],
      amount: (j['amount'] ?? j['value'] ?? j['total']) as num?,
      status: j['status'],
      reference: _ref(j['order']) ??
          _ref(j['payout']) ??
          _ref(j['relatedOrder']) ??
          j['reference']?.toString() ??
          j['orderNumber']?.toString(),
      product: product is Map ? (product['name'] ?? product['_id'])?.toString() : product?.toString(),
      date: parseDate(j['createdAt'] ?? j['date'] ?? j['timestamp']),
      raw: j,
    );
  }

  static String? _ref(dynamic v) => v is Map ? (v['orderNumber'] ?? v['_id'] ?? v['reference'])?.toString() : v?.toString();

  /// Activity groups offered by the history filter.
  static const buckets = <String>['ORDERS', 'PAYOUTS', 'INVENTORY'];

  /// Normalised filter bucket. The feed mixes three event families, so each row
  /// is folded into one of [buckets]; anything unrecognised is treated as an
  /// order event, which is the most common kind of entry.
  String get bucket {
    final t = (type ?? '').toLowerCase();
    if (t.contains('payout') || t.contains('payment') || t.contains('settle') || t.contains('transaction')) {
      return 'PAYOUTS';
    }
    if (t.contains('stock') || t.contains('inventory') || t.contains('product')) return 'INVENTORY';
    return 'ORDERS';
  }

  String get display => title ?? description ?? type ?? 'Activity';
}

/// Headline numbers for the vendor dashboard summary cards.
class VendorStats {
  VendorStats({
    this.dailySales,
    this.salesDelta,
    this.activeOrders,
    this.lowStock,
    this.rating,
    this.ratingCount,
    this.totalProducts,
    this.totalOrders,
    this.pendingPayout,
  });

  num? dailySales;
  num? salesDelta;
  num? activeOrders;
  num? lowStock;
  double? rating;
  int? ratingCount;
  num? totalProducts;
  num? totalOrders;
  num? pendingPayout;

  factory VendorStats.fromJson(Map<String, dynamic> j) {
    final overview = j['overview'] is Map ? Map<String, dynamic>.from(j['overview']) : j;
    return VendorStats(
      dailySales: (overview['dailySales'] ?? overview['todaySales'] ?? overview['salesToday'] ?? overview['revenue'] ?? overview['sales']) as num?,
      salesDelta: (overview['salesDelta'] ?? overview['salesChange'] ?? overview['revenueChange']) as num?,
      activeOrders: (overview['activeOrders'] ?? overview['openOrders'] ?? overview['orders'] ?? overview['pendingOrders']) as num?,
      lowStock: (overview['lowStock'] ?? overview['lowStockProducts'] ?? overview['lowStockAlerts'] ?? overview['outOfStock']) as num?,
      rating: (overview['rating'] ?? overview['averageRating'] ?? overview['storeRating'])?.toDouble(),
      ratingCount: _int(overview['ratingCount'] ?? overview['totalRatings'] ?? overview['reviewsCount']),
      totalProducts: (overview['totalProducts'] ?? overview['productCount']) as num?,
      totalOrders: (overview['totalOrders'] ?? overview['ordersCount']) as num?,
      pendingPayout: (overview['pendingPayout'] ?? overview['pendingPayouts'] ?? overview['balance']) as num?,
    );
  }

  static int? _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : (v is String ? int.tryParse(v) : null));
}
