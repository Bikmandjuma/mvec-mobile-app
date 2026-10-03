import 'user.dart';

class ProductRecord {
  ProductRecord({
    this.id,
    this.name,
    this.slug,
    this.price,
    this.stock,
    this.status,
    this.vendor,
    this.category,
    this.image,
    this.rating,
    this.raw,
  });

  String? id;
  String? name;
  String? slug;
  num? price;
  int? stock;
  String? status;
  String? vendor;
  String? category;
  String? image;
  double? rating;
  Map<String, dynamic>? raw;

  factory ProductRecord.fromJson(Map<String, dynamic> j) {
    final vendor = j['vendor'];
    final cat = j['category'];
    return ProductRecord(
      id: j['_id'] ?? j['id'],
      name: j['name'] ?? j['title'],
      slug: j['slug'],
      price: (j['price'] ?? j['salePrice'] ?? j['basePrice']) as num?,
      stock: j['stockQuantity'] is int ? j['stockQuantity'] : (j['stock'] is int ? j['stock'] : null),
      status: j['status'],
      vendor: vendor is Map ? (vendor['businessName'] ?? vendor['name'] ?? vendor['_id'])?.toString() : vendor?.toString(),
      category: cat is Map ? (cat['name'] ?? cat['_id'])?.toString() : cat?.toString(),
      image: _image(j),
      rating: (j['rating'] ?? j['averageRating'])?.toDouble(),
      raw: j,
    );
  }

  static String? _image(Map<String, dynamic> j) {
    final imgs = j['images'];
    if (imgs is List && imgs.isNotEmpty) {
      final f = imgs.first;
      if (f is String) return f;
      if (f is Map && f['url'] is String) return f['url'];
    }
    return j['thumbnail'] is String ? j['thumbnail'] : (j['image'] is String ? j['image'] : null);
  }

  String get display => name ?? 'Unnamed product';
}

class CategoryRecord {
  CategoryRecord({this.id, this.name, this.slug, this.active, this.parent, this.products, this.description});
  String? id;
  String? name;
  String? slug;
  bool? active;
  String? parent;
  int? products;
  String? description;

  factory CategoryRecord.fromJson(Map<String, dynamic> j) => CategoryRecord(
        id: j['_id'] ?? j['id'],
        name: j['name'],
        slug: j['slug'],
        active: j['active'] is bool ? j['active'] : true,
        parent: j['parent'] is Map ? j['parent']['_id']?.toString() : j['parent']?.toString(),
        products: j['productCount'] is int ? j['productCount'] : (j['products'] is int ? j['products'] : null),
        description: j['description'],
      );
}

class OrderRecord {
  OrderRecord({
    this.id,
    this.orderNumber,
    this.buyer,
    this.vendor,
    this.total,
    this.status,
    this.paymentStatus,
    this.paymentMethod,
    this.createdAt,
    this.itemsCount,
    this.raw,
  });

  String? id;
  String? orderNumber;
  String? buyer;
  String? vendor;
  num? total;
  String? status;
  String? paymentStatus;
  String? paymentMethod;
  DateTime? createdAt;
  int? itemsCount;
  Map<String, dynamic>? raw;

  factory OrderRecord.fromJson(Map<String, dynamic> j) {
    final buyer = j['buyer'];
    final vendors = j['vendors'];
    String? vendorName;
    if (vendors is List && vendors.isNotEmpty) {
      final v = vendors.first;
      vendorName = v is Map ? (v['businessName'] ?? v['name'] ?? v['_id'])?.toString() : v.toString();
    } else if (j['vendor'] is Map) {
      vendorName = (j['vendor']['businessName'] ?? j['vendor']['_id'])?.toString();
    }
    final items = j['items'];
    return OrderRecord(
      id: j['_id'] ?? j['id'],
      orderNumber: j['orderNumber'] ?? j['orderId'] ?? (j['_id'] != null ? 'MVEC-${j['_id'].toString().substring(j['_id'].toString().length > 6 ? j['_id'].toString().length - 6 : 0)}' : null),
      buyer: buyer is Map ? (buyer['Fullname'] ?? buyer['email'] ?? buyer['_id'])?.toString() : buyer?.toString(),
      vendor: vendorName,
      total: (j['totalAmount'] ?? j['total'] ?? j['grandTotal']) as num?,
      status: j['status'],
      paymentStatus: j['paymentStatus'] ?? (j['payment'] is Map ? j['payment']['status'] : null),
      paymentMethod: j['paymentMethod'] ?? (j['payment'] is Map ? j['payment']['method'] : null),
      createdAt: parseDate(j['createdAt']),
      itemsCount: items is List ? items.length : null,
      raw: j,
    );
  }

  String get display => orderNumber ?? id ?? 'Order';
}

class PaymentRecord {
  PaymentRecord({this.id, this.order, this.payer, this.amount, this.method, this.status, this.createdAt});
  String? id;
  String? order;
  String? payer;
  num? amount;
  String? method;
  String? status;
  DateTime? createdAt;

  factory PaymentRecord.fromJson(Map<String, dynamic> j) => PaymentRecord(
        id: j['_id'] ?? j['id'] ?? j['paymentId'] ?? j['transactionId'],
        order: j['order'] is Map ? (j['order']['orderNumber'] ?? j['order']['_id'])?.toString() : j['order']?.toString() ?? j['orderId']?.toString(),
        payer: j['payer'] ?? j['payerName'] ?? j['customer'] ?? j['phone'] ?? j['phoneNumber'],
        amount: (j['amount'] ?? j['totalAmount'] ?? j['value']) as num?,
        method: j['method'] ?? j['provider'] ?? (j['channel']),
        status: j['status'] ?? j['settlement'] ?? j['state'],
        createdAt: parseDate(j['createdAt'] ?? j['date']),
      );
}

class LedgerEntry {
  LedgerEntry({this.id, this.entryType, this.event, this.order, this.amount, this.status, this.date, this.description});
  String? id;
  String? entryType;
  String? event;
  String? order;
  num? amount;
  String? status;
  DateTime? date;
  String? description;

  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(
        id: j['_id'] ?? j['id'] ?? j['entryId'] ?? j['ledgerId'],
        entryType: j['entryType'] ?? j['type'],
        event: j['event'] ?? j['description'] ?? j['narration'],
        order: j['relatedOrder'] is Map
            ? (j['relatedOrder']['orderNumber'] ?? j['relatedOrder']['_id'])?.toString()
            : j['relatedOrder']?.toString() ?? j['order']?.toString(),
        amount: (j['amount'] ?? j['value']) as num?,
        status: j['status'],
        date: parseDate(j['createdAt'] ?? j['date']),
        description: j['description'] ?? j['narration'],
      );
}

class CommissionRule {
  CommissionRule({this.id, this.name, this.ruleType, this.target, this.rateType, this.rateValue, this.priority, this.active});
  String? id;
  String? name;
  String? ruleType;
  String? target;
  String? rateType;
  num? rateValue;
  int? priority;
  bool? active;

  factory CommissionRule.fromJson(Map<String, dynamic> j) => CommissionRule(
        id: j['_id'] ?? j['id'],
        name: j['name'],
        ruleType: j['ruleType'],
        target: j['targetCategory'] ?? j['targetVendor'] ?? j['targetProduct'] ?? j['target'],
        rateType: j['rateType'],
        rateValue: (j['rateValue'] ?? j['rate'] ?? j['commission']) as num?,
        priority: j['priority'] is int ? j['priority'] : null,
        active: j['active'] is bool ? j['active'] : (j['status'] == 'ACTIVE'),
      );

  String get rateLabel => rateType == 'FIXED' ? '${rateValue ?? 0} RWF' : '${rateValue ?? 0}%';
}

class PayoutRecord {
  PayoutRecord({this.id, this.account, this.amount, this.status, this.method, this.reference, this.createdAt, this.cycle});
  String? id;
  String? account;
  num? amount;
  String? status;
  String? method;
  String? reference;
  String? cycle;
  DateTime? createdAt;

  factory PayoutRecord.fromJson(Map<String, dynamic> j) => PayoutRecord(
        id: j['_id'] ?? j['id'] ?? j['payoutId'],
        account: j['account'] ?? j['vendor'] ?? j['affiliate'] ?? j['holder'] ?? j['beneficiary'],
        amount: (j['amount'] ?? j['netAmount']) as num?,
        status: j['status'],
        method: j['method'] ?? j['type'],
        reference: j['transactionReference'] ?? j['reference'],
        cycle: j['cycle'] ?? j['period'],
        createdAt: parseDate(j['createdAt'] ?? j['requestedAt']),
      );
}

class DisputeRecord {
  DisputeRecord({this.id, this.order, this.reason, this.description, this.buyer, this.status, this.amount, this.createdAt});
  String? id;
  String? order;
  String? reason;
  String? description;
  String? buyer;
  String? status;
  num? amount;
  DateTime? createdAt;

  factory DisputeRecord.fromJson(Map<String, dynamic> j) {
    final order = j['order'];
    final buyer = j['buyer'] ?? j['raisedBy'];
    return DisputeRecord(
      id: j['_id'] ?? j['id'],
      order: order is Map ? (order['orderNumber'] ?? order['_id'])?.toString() : order?.toString(),
      reason: j['reason'],
      description: j['description'],
      buyer: buyer is Map ? (buyer['Fullname'] ?? buyer['email'])?.toString() : buyer?.toString(),
      status: j['status'],
      amount: (j['disputedAmount'] ?? j['amount']) as num?,
      createdAt: parseDate(j['createdAt']),
    );
  }
}

class ReviewRecord {
  ReviewRecord({this.id, this.product, this.author, this.rating, this.comment, this.status, this.createdAt});
  String? id;
  String? product;
  String? author;
  num? rating;
  String? comment;
  String? status;
  DateTime? createdAt;

  factory ReviewRecord.fromJson(Map<String, dynamic> j) {
    final p = j['product'];
    final a = j['user'] ?? j['author'];
    return ReviewRecord(
      id: j['_id'] ?? j['id'],
      product: p is Map ? (p['name'] ?? p['_id'])?.toString() : p?.toString(),
      author: a is Map ? (a['Fullname'] ?? a['email'])?.toString() : a?.toString(),
      rating: (j['rating'] ?? j['score']) as num?,
      comment: j['comment'] ?? j['body'] ?? j['review'],
      status: j['status'],
      createdAt: parseDate(j['createdAt']),
    );
  }
}

class SupportCase {
  SupportCase({this.id, this.subject, this.order, this.requester, this.message, this.status, this.priority, this.createdAt});
  String? id;
  String? subject;
  String? order;
  String? requester;
  String? message;
  String? status;
  String? priority;
  DateTime? createdAt;

  factory SupportCase.fromJson(Map<String, dynamic> j) {
    final o = j['order'] ?? j['orderId'];
    final u = j['user'] ?? j['requester'] ?? j['createdBy'];
    return SupportCase(
      id: j['_id'] ?? j['id'] ?? j['caseId'],
      subject: j['subject'] ?? j['title'],
      order: o is Map ? (o['orderNumber'] ?? o['_id'])?.toString() : o?.toString(),
      requester: u is Map ? (u['Fullname'] ?? u['email'])?.toString() : u?.toString(),
      message: j['message'] ?? j['description'],
      status: j['status'],
      priority: j['priority'],
      createdAt: parseDate(j['createdAt']),
    );
  }
}

class NotificationRecord {
  NotificationRecord({this.id, this.recipient, this.type, this.message, this.status, this.channel, this.createdAt});
  String? id;
  String? recipient;
  String? type;
  String? message;
  String? status;
  String? channel;
  DateTime? createdAt;

  factory NotificationRecord.fromJson(Map<String, dynamic> j) {
    final r = j['recipient'];
    return NotificationRecord(
      id: j['_id'] ?? j['id'],
      recipient: r is Map ? (r['Fullname'] ?? r['email'] ?? r['_id'])?.toString() : r?.toString(),
      type: j['type'] ?? j['category'],
      message: j['message'] ?? j['title'] ?? j['body'],
      status: j['status'] ?? (j['read'] == true ? 'READ' : 'UNREAD'),
      channel: j['channel'],
      createdAt: parseDate(j['createdAt']),
    );
  }
}

class TranslationRecord {
  TranslationRecord({this.id, this.key, this.module, this.en, this.rw, this.fr});
  String? id;
  String? key;
  String? module;
  String? en;
  String? rw;
  String? fr;

  factory TranslationRecord.fromJson(Map<String, dynamic> j) {
    final t = j['translations'];
    return TranslationRecord(
      id: j['_id'] ?? j['id'],
      key: j['key'],
      module: j['module'],
      en: t is Map ? t['en']?.toString() : j['en']?.toString(),
      rw: t is Map ? t['rw']?.toString() : j['rw']?.toString(),
      fr: t is Map ? t['fr']?.toString() : j['fr']?.toString(),
    );
  }
}

class SubscriptionRecord {
  SubscriptionRecord({this.id, this.holder, this.type, this.amount, this.cycle, this.status, this.createdAt, this.expiresAt});
  String? id;
  String? holder;
  String? type;
  num? amount;
  String? cycle;
  String? status;
  DateTime? createdAt;
  DateTime? expiresAt;

  factory SubscriptionRecord.fromJson(Map<String, dynamic> j) {
    final h = j['holder'] ?? j['user'] ?? j['vendor'];
    return SubscriptionRecord(
      id: j['_id'] ?? j['id'],
      holder: h is Map ? (h['Fullname'] ?? h['businessName'] ?? h['email'] ?? h['_id'])?.toString() : h?.toString(),
      type: j['type'] ?? j['plan'] ?? j['tier'],
      amount: (j['amount'] ?? j['price']) as num?,
      cycle: j['cycle'] ?? j['billingCycle'] ?? j['interval'],
      status: j['status'],
      createdAt: parseDate(j['createdAt']),
      expiresAt: parseDate(j['expiresAt'] ?? j['endDate']),
    );
  }
}

class AdvertisementRecord {
  AdvertisementRecord({this.id, this.vendor, this.product, this.placement, this.budget, this.status, this.ctr, this.startDate});
  String? id;
  String? vendor;
  String? product;
  String? placement;
  num? budget;
  String? status;
  double? ctr;
  DateTime? startDate;

  factory AdvertisementRecord.fromJson(Map<String, dynamic> j) {
    final v = j['vendor'];
    final p = j['product'];
    return AdvertisementRecord(
      id: j['_id'] ?? j['id'],
      vendor: v is Map ? (v['businessName'] ?? v['_id'])?.toString() : v?.toString(),
      product: p is Map ? (p['name'] ?? p['_id'])?.toString() : p?.toString(),
      placement: j['placement'] ?? j['slot'] ?? j['type'],
      budget: (j['budget'] ?? j['spend'] ?? j['amount']) as num?,
      status: j['status'],
      ctr: (j['ctr'] ?? j['clickThroughRate'])?.toDouble(),
      startDate: parseDate(j['startDate'] ?? j['createdAt']),
    );
  }
}

class ReportMetric {
  ReportMetric({this.label, this.value, this.delta});
  String? label;
  num? value;
  String? delta;
}

class ReportSummary {
  ReportSummary({this.grossSales, this.orders, this.totalOrders, this.customers, this.activeVendors, this.lowStockProducts, this.paymentVolume, this.commission, this.refunds});
  num? grossSales;
  num? orders;
  num? totalOrders;
  num? customers;
  num? activeVendors;
  num? lowStockProducts;
  num? paymentVolume;
  num? commission;
  num? refunds;

  factory ReportSummary.fromMetrics(Map<String, dynamic> j) => ReportSummary(
        grossSales: (j['grossSales'] ?? j['sales'] ?? j['revenue']) as num?,
        orders: (j['orders'] ?? j['orderCount']) as num?,
        totalOrders: (j['totalOrders'] ?? j['orders']) as num?,
        customers: (j['customers'] ?? j['users'] ?? j['activeUsers']) as num?,
        activeVendors: (j['activeVendors'] ?? j['vendors']) as num?,
        lowStockProducts: (j['lowStockProducts'] ?? j['lowStock']) as num?,
        paymentVolume: (j['paymentVolume'] ?? j['volume']) as num?,
        commission: (j['commission'] ?? j['platformCommission']) as num?,
        refunds: (j['refunds'] ?? j['refundAmount']) as num?,
      );
}

class RevenueSeries {
  RevenueSeries({required this.labels, required this.series});
  final List<String> labels;
  final List<num> series;

  factory RevenueSeries.fromJson(Map<String, dynamic> j) => RevenueSeries(
        labels: (j['labels'] ?? []).map((e) => e.toString()).toList(),
        series: (j['series'] ?? []).map((e) => (e as num)).toList(),
      );
}