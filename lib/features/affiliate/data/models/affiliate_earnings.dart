import 'affiliate_marketing.dart';
import '../../../../models/user.dart';

/// Commission balance for the signed-in affiliate.
///
/// The three balances mirror the backend `affiliateWallet` model:
/// `totalEarned`, `pendingBalance` (awaiting order completion) and
/// `availableBalance` (withdrawable).
class AffiliateWallet {
  const AffiliateWallet({
    this.totalEarned = 0,
    this.availableBalance = 0,
    this.pendingBalance = 0,
    this.totalWithdrawn = 0,
    this.currency = 'RWF',
    this.minimumPayout = 10000,
    this.lastPayoutAt,
  });

  final num totalEarned;
  final num availableBalance;
  final num pendingBalance;
  final num totalWithdrawn;
  final String currency;
  final num minimumPayout;
  final DateTime? lastPayoutAt;

  factory AffiliateWallet.fromJson(Map<String, dynamic> j) => AffiliateWallet(
        totalEarned: numOrNull(j['totalEarned'] ?? j['totalCommission'] ?? j['earnings']) ?? 0,
        availableBalance: numOrNull(j['availableBalance'] ?? j['available']) ?? 0,
        pendingBalance: numOrNull(j['pendingBalance'] ?? j['pending']) ?? 0,
        totalWithdrawn: numOrNull(j['totalWithdrawn'] ?? j['withdrawn']) ?? 0,
        currency: j['currency'] ?? 'RWF',
        minimumPayout: numOrNull(j['minimumPayout'] ?? j['minimumWithdrawal']) ?? 10000,
        lastPayoutAt: parseDate(j['lastPayoutAt'] ?? j['lastWithdrawal']),
      );

  bool get canWithdraw => availableBalance >= minimumPayout;

  /// Amount still required before a withdrawal can be requested.
  num get shortfall {
    final gap = minimumPayout - availableBalance;
    return gap > 0 ? gap : 0;
  }
}

/// One commission line: a click, signup, conversion or released sale.
class AffiliateCommission {
  const AffiliateCommission({
    this.id,
    this.type,
    this.status,
    this.product,
    this.order,
    this.linkCode,
    this.amount,
    this.rate,
    this.orderTotal,
    this.notes,
    this.createdAt,
    this.releasedAt,
  });

  final String? id;

  /// `CLICK`, `REGISTRATION`, `CONVERSION` or `SALE`.
  final String? type;

  /// `PENDING` (awaiting completion), `AVAILABLE`, `PAID` or `REVERSED`.
  final String? status;
  final String? product;
  final String? order;
  final String? linkCode;
  final num? amount;
  final num? rate;
  final num? orderTotal;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? releasedAt;

  factory AffiliateCommission.fromJson(Map<String, dynamic> j) {
    final product = j['product'] ?? j['targetProduct'];
    final order = j['order'];
    return AffiliateCommission(
      id: j['_id'] ?? j['id'] ?? j['commissionId'],
      type: (j['type'] ?? j['event'] ?? j['source'] ?? 'CONVERSION').toString().toUpperCase(),
      status: (j['status'] ?? 'PENDING').toString().toUpperCase(),
      product: product is Map ? (product['name'] ?? product['_id'])?.toString() : product?.toString(),
      order: order is Map ? (order['orderNumber'] ?? order['_id'])?.toString() : order?.toString() ?? j['orderNumber']?.toString(),
      linkCode: j['affiliateCode'] ?? j['linkCode'] ?? j['referralCode'],
      amount: (j['amount'] ?? j['commission'] ?? j['commissionAmount']) as num?,
      rate: (j['rate'] ?? j['commissionRate']) as num?,
      orderTotal: (j['orderTotal'] ?? j['orderAmount'] ?? j['totalAmount']) as num?,
      notes: j['notes'] ?? j['description'],
      createdAt: parseDate(j['createdAt'] ?? j['creditedAt']),
      releasedAt: parseDate(j['releasedAt'] ?? j['availableAt']),
    );
  }

  String get typeLabel {
    switch (type) {
      case 'CLICK':
        return 'Click';
      case 'REGISTRATION':
        return 'Registration';
      case 'CONVERSION':
        return 'Conversion';
      default:
        return 'Completed sale';
    }
  }

  String get title => product ?? order ?? typeLabel;
}

/// A withdrawal request and its processing state.
class AffiliatePayout {
  const AffiliatePayout({
    this.id,
    this.payoutNumber,
    this.amount,
    this.status,
    this.paymentMethod,
    this.accountName,
    this.accountNumber,
    this.bankName,
    this.transactionReference,
    this.rejectionReason,
    this.note,
    this.createdAt,
    this.processedAt,
  });

  final String? id;
  final String? payoutNumber;
  final num? amount;
  final String? status;
  final String? paymentMethod;
  final String? accountName;
  final String? accountNumber;
  final String? bankName;
  final String? transactionReference;
  final String? rejectionReason;
  final String? note;
  final DateTime? createdAt;
  final DateTime? processedAt;

  factory AffiliatePayout.fromJson(Map<String, dynamic> j) => AffiliatePayout(
        id: j['_id'] ?? j['id'] ?? j['payoutId'],
        payoutNumber: j['payoutNumber'] ?? j['reference'] ?? j['transactionReference'] ?? (j['_id'] ?? j['id'])?.toString(),
        amount: (j['amount'] ?? j['netAmount']) as num?,
        status: (j['status'] ?? 'PENDING').toString().toUpperCase(),
        paymentMethod: j['paymentMethod'] ?? j['method'],
        accountName: j['accountName'],
        accountNumber: j['accountNumber'] ?? j['phoneNumber'],
        bankName: j['bankName'],
        transactionReference: j['transactionReference'],
        rejectionReason: j['rejectionReason'],
        note: j['note'] ?? j['adminNotes'],
        createdAt: parseDate(j['createdAt'] ?? j['requestedAt']),
        processedAt: parseDate(j['processedAt'] ?? j['updatedAt']),
      );

  String get destination {
    if (accountNumber != null && accountNumber!.isNotEmpty) return accountNumber!;
    if (bankName != null && bankName!.isNotEmpty) return bankName!;
    return '—';
  }

  /// The four payout states the backend walks a request through.
  List<({String label, bool done})> get steps => [
        (label: 'Request submitted', done: true),
        (label: 'Destination and balance validated', done: status != 'PENDING'),
        (label: 'Sent through the payment channel', done: status == 'COMPLETED' || status == 'PROCESSING'),
        (label: 'Transfer confirmed', done: status == 'COMPLETED'),
      ];
}

/// Aggregated referral performance across every link the affiliate owns.
class AffiliateStats {
  const AffiliateStats({
    this.clicks = 0,
    this.registrations = 0,
    this.conversions = 0,
    this.revenue = 0,
    this.commission = 0,
    this.activeLinks = 0,
    this.labels = const [],
    this.clicksSeries = const [],
    this.registrationsSeries = const [],
    this.conversionsSeries = const [],
    this.topLinks = const [],
  });

  final int clicks;
  final int registrations;
  final int conversions;
  final num revenue;
  final num commission;
  final int activeLinks;

  /// Day / week / month labels shared by all three series.
  final List<String> labels;
  final List<num> clicksSeries;
  final List<num> registrationsSeries;
  final List<num> conversionsSeries;

  /// Best performing links, already sorted by commission earned.
  final List<AffiliateLink> topLinks;

  factory AffiliateStats.fromJson(Map<String, dynamic> j) {
    final series = j['series'] is Map ? Map<String, dynamic>.from(j['series']) : j;
    return AffiliateStats(
      clicks: _int(j['clicks'] ?? j['totalClicks'] ?? j['clickCount']) ?? 0,
      registrations: _int(j['registrations'] ?? j['signups'] ?? j['registrationCount']) ?? 0,
      conversions: _int(j['conversions'] ?? j['orders'] ?? j['conversionCount']) ?? 0,
      revenue: numOrNull(j['revenue'] ?? j['orderVolume'] ?? j['sales']) ?? 0,
      commission: numOrNull(j['commission'] ?? j['commissionEarned'] ?? j['earnings']) ?? 0,
      activeLinks: _int(j['activeLinks'] ?? j['links']) ?? 0,
      labels: _strList(j['labels'] ?? series['labels']),
      clicksSeries: _numList(series['clicks'] ?? j['clicksSeries']),
      registrationsSeries: _numList(series['registrations'] ?? j['registrationsSeries']),
      conversionsSeries: _numList(series['conversions'] ?? j['conversionsSeries']),
      topLinks: listJsonOf(j['topLinks'], AffiliateLink.fromJson),
    );
  }

  /// Share of clicks that became a completed order.
  double get conversionRate => clicks == 0 ? 0 : (conversions / clicks) * 100;

  /// Share of clicks that produced an account registration.
  double get registrationRate => clicks == 0 ? 0 : (registrations / clicks) * 100;

  /// Average commission per conversion.
  num get averageCommission => conversions == 0 ? 0 : commission / conversions;
}

num? numOrNull(dynamic v) => v is num ? v : (v is String ? num.tryParse(v) : null);

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return v is String ? int.tryParse(v) : null;
}

List<String> _strList(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : const [];

List<num> _numList(dynamic v) => v is List ? v.map((e) => numOrNull(e) ?? 0).toList() : const [];

/// Normalises the handful of list envelopes the backend uses.
List<T> listJsonOf<T>(dynamic json, T Function(Map<String, dynamic>) map) {
  if (json is List) {
    return json.whereType<Map>().map((e) => map(Map<String, dynamic>.from(e))).toList();
  }
  if (json is Map) {
    for (final key in const ['data', 'items', 'results', 'topLinks', 'links']) {
      final v = json[key];
      if (v is List) return v.whereType<Map>().map((e) => map(Map<String, dynamic>.from(e))).toList();
    }
  }
  return [];
}
