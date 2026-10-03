/// Money domain for the vendor sales module: what the store earned, what the
/// platform took, and what is still locked in escrow.
library;

import '../../../models/user.dart';

/// How money reaches the vendor.
enum PayoutMethod {
  mtnMomo,
  airtelMoney,
  bankTransfer;

  String get slug => switch (this) {
    PayoutMethod.mtnMomo => 'MTN_MOMO',
    PayoutMethod.airtelMoney => 'AIRTEL_MONEY',
    PayoutMethod.bankTransfer => 'BANK_TRANSFER',
  };

  String get label => switch (this) {
    PayoutMethod.mtnMomo => 'MTN Mobile Money',
    PayoutMethod.airtelMoney => 'Airtel Money',
    PayoutMethod.bankTransfer => 'Bank transfer',
  };

  /// Masked account hint shown next to the method, e.g. `+250 78••• 214`.
  String get hint => switch (this) {
    PayoutMethod.mtnMomo => 'MTN MoMo · +250 78••• 214',
    PayoutMethod.airtelMoney => 'Airtel Money · +250 73••• 908',
    PayoutMethod.bankTransfer => 'Equity Bank · ••••4471',
  };

  /// Mobile money settles instantly, bank transfers take a day or two.
  String get settlementNote => switch (this) {
    PayoutMethod.mtnMomo => 'Arrives on your MoMo wallet within minutes.',
    PayoutMethod.airtelMoney => 'Arrives on your Airtel wallet within minutes.',
    PayoutMethod.bankTransfer => 'Settles within 1–2 business days.',
  };

  static PayoutMethod parse(String? raw) {
    final v = raw?.trim().toLowerCase().replaceAll('-', '_');
    return switch (v) {
      'airtel_money' || 'airtel' => PayoutMethod.airtelMoney,
      'bank' || 'bank_transfer' || 'banktransfer' => PayoutMethod.bankTransfer,
      _ => PayoutMethod.mtnMomo,
    };
  }
}

/// The four headline money numbers on the sales screen.
class VendorFinanceSummary {
  const VendorFinanceSummary({
    this.grossRevenue = 0,
    this.commission = 0,
    this.netEarnings = 0,
    this.escrowHeld = 0,
    this.availablePayout = 0,
    this.pendingPayouts = 0,
    this.commissionRate = 0.1,
    this.revenueDelta = 0,
    this.earningsDelta = 0,
    this.series = const <EarningsPoint>[],
    this.lastPayoutAt,
  });

  /// Everything the buyers paid for goods, before the platform takes its cut.
  final num grossRevenue;

  /// Platform commission deducted across the same period.
  final num commission;

  /// [grossRevenue] minus [commission] — the store's true take.
  final num netEarnings;

  /// Money held by the platform on orders that are not delivered yet.
  final num escrowHeld;

  /// Cleared money the vendor can withdraw right now.
  final num availablePayout;

  /// Sum of withdrawal requests still processing, excluded from
  /// [availablePayout] so the vendor cannot double-request it.
  final num pendingPayouts;

  /// Effective platform rate, shown as a footnote under the commission card.
  final num commissionRate;

  /// Period-over-period change, as a fraction (`0.12` = +12%).
  final num revenueDelta;
  final num earningsDelta;

  /// Daily earnings for the sparkline on the sales screen.
  final List<EarningsPoint> series;

  /// When the last successful withdrawal landed, if any.
  final DateTime? lastPayoutAt;

  /// Total the platform is holding for the store: escrow plus in-flight
  /// withdrawals. Explains why gross revenue exceeds the withdrawable balance.
  num get totalHeld => escrowHeld + pendingPayouts;

  /// Sanity invariant used by the mock data and asserted in tests: the net
  /// figure must equal gross minus commission.
  bool get isConsistent =>
      (netEarnings - (grossRevenue - commission)).abs() < 1;

  factory VendorFinanceSummary.fromJson(
    Map<String, dynamic> j,
  ) => VendorFinanceSummary(
    grossRevenue:
        _num(j['grossRevenue'] ?? j['totalRevenue'] ?? j['revenue']) ?? 0,
    commission:
        _num(j['commission'] ?? j['platformCommission'] ?? j['fees']) ?? 0,
    netEarnings: _num(j['netEarnings'] ?? j['earnings']) ?? 0,
    escrowHeld:
        _num(j['escrowHeld'] ?? j['pendingEscrow'] ?? j['inEscrow']) ?? 0,
    availablePayout:
        _num(
          j['availablePayout'] ?? j['availableBalance'] ?? j['payoutBalance'],
        ) ??
        0,
    pendingPayouts: _num(j['pendingPayouts'] ?? j['processingPayouts']) ?? 0,
    commissionRate: _num(j['commissionRate'] ?? j['platformFeeRate']) ?? 0.1,
    revenueDelta: _num(j['revenueDelta'] ?? j['revenueChange']) ?? 0,
    earningsDelta: _num(j['earningsDelta'] ?? j['earningsChange']) ?? 0,
    series:
        (j['series'] ?? j['trend']) is List
            ? (j['series'] ?? j['trend'])
                .whereType<Map>()
                .map(
                  (e) => EarningsPoint.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
            : const <EarningsPoint>[],
    lastPayoutAt: parseDate(j['lastPayoutAt'] ?? j['lastPayout']),
  );
}

/// One day on the earnings sparkline.
class EarningsPoint {
  const EarningsPoint({required this.at, required this.net});

  final DateTime at;

  /// Net earnings for that day, after commission.
  final num net;

  factory EarningsPoint.fromJson(Map<String, dynamic> j) => EarningsPoint(
    at: parseDate(j['at'] ?? j['date'] ?? j['_id']) ?? DateTime.now(),
    net: _num(j['net'] ?? j['value'] ?? j['amount']) ?? 0,
  );
}

/// What a single ledger line represents.
enum LedgerEntryKind {
  sale,
  commission,
  escrowRelease,
  payout,
  refund,
  adjustment;

  String get slug => switch (this) {
    LedgerEntryKind.sale => 'SALE',
    LedgerEntryKind.commission => 'COMMISSION',
    LedgerEntryKind.escrowRelease => 'ESCROW_RELEASE',
    LedgerEntryKind.payout => 'PAYOUT',
    LedgerEntryKind.refund => 'REFUND',
    LedgerEntryKind.adjustment => 'ADJUSTMENT',
  };

  String get label => switch (this) {
    LedgerEntryKind.sale => 'Order sale',
    LedgerEntryKind.commission => 'Platform commission',
    LedgerEntryKind.escrowRelease => 'Escrow released',
    LedgerEntryKind.payout => 'Withdrawal',
    LedgerEntryKind.refund => 'Refund',
    LedgerEntryKind.adjustment => 'Adjustment',
  };

  /// Icon key for the shared icon set, chosen so the row reads at a glance.
  String get icon => switch (this) {
    LedgerEntryKind.sale => 'cart',
    LedgerEntryKind.commission => 'tag',
    LedgerEntryKind.escrowRelease => 'shield',
    LedgerEntryKind.payout => 'wallet',
    LedgerEntryKind.refund => 'arrow',
    LedgerEntryKind.adjustment => 'edit',
  };

  /// Sign convention applied to the amount when rendering: money in is
  /// positive, money out negative.
  int get sign => switch (this) {
    LedgerEntryKind.commission ||
    LedgerEntryKind.payout ||
    LedgerEntryKind.refund => -1,
    _ => 1,
  };

  static LedgerEntryKind parse(String? raw) {
    final v = raw?.trim().toLowerCase().replaceAll('-', '_');
    return switch (v) {
      'commission' || 'fee' || 'platform_fee' => LedgerEntryKind.commission,
      'escrow_release' ||
      'escrow' ||
      'release' => LedgerEntryKind.escrowRelease,
      'payout' || 'withdrawal' || 'withdraw' => LedgerEntryKind.payout,
      'refund' => LedgerEntryKind.refund,
      'adjustment' || 'adjust' => LedgerEntryKind.adjustment,
      _ => LedgerEntryKind.sale,
    };
  }
}

/// A movement on the vendor's money ledger — an order sale, the platform's cut,
/// an escrow release, a withdrawal or a refund.
///
/// [amount] is always stored as a positive magnitude; [LedgerEntryKind.sign]
/// decides the direction, so the ledger never double-negates a backend value.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.at,
    required this.kind,
    required this.amount,
    required this.description,
    this.orderNumber,
    this.balanceAfter,
    this.payoutMethod,
    this.payoutStatus,
  });

  final String id;
  final DateTime at;
  final LedgerEntryKind kind;
  final num amount;
  final String description;

  /// Set on entries that belong to an order, so the row can deep-link into it.
  final String? orderNumber;

  /// Running balance once this entry posted — makes the table self-checking.
  final num? balanceAfter;

  final PayoutMethod? payoutMethod;

  /// `PENDING` / `PAID` / `FAILED` for withdrawal rows.
  final String? payoutStatus;

  /// Signed amount for display: positive for money in, negative for money out.
  num get signedAmount => amount * kind.sign;

  /// True for entries that leave the store's balance.
  bool get isCredit => kind.sign > 0;

  factory LedgerEntry.fromJson(Map<String, dynamic> j) {
    final method = j['method'] ?? j['payoutMethod'];
    return LedgerEntry(
      id: '${j['_id'] ?? j['id'] ?? ''}',
      at: parseDate(j['at'] ?? j['createdAt'] ?? j['date']) ?? DateTime.now(),
      kind: LedgerEntryKind.parse('${j['kind'] ?? j['type'] ?? ''}'),
      amount: (_num(j['amount'] ?? j['total']) ?? 0).abs(),
      description:
          '${j['description'] ?? j['note'] ?? j['title'] ?? 'Transaction'}',
      orderNumber: j['orderNumber'] == null ? null : '${j['orderNumber']}',
      balanceAfter: _num(j['balanceAfter'] ?? j['balance']),
      payoutMethod: method == null ? null : PayoutMethod.parse('$method'),
      payoutStatus: j['payoutStatus'] == null ? null : '${j['payoutStatus']}',
    );
  }
}

/// A withdrawal the vendor has requested.
class PayoutRequest {
  const PayoutRequest({
    required this.id,
    required this.amount,
    required this.method,
    required this.requestedAt,
    this.status = 'PENDING',
    this.destination,
    this.note,
    this.arrivedAt,
  });

  final String id;
  final num amount;
  final PayoutMethod method;
  final DateTime requestedAt;

  /// `PENDING` | `PAID` | `FAILED` | `REJECTED`.
  final String status;

  /// The phone number or bank account the money goes to.
  final String? destination;
  final String? note;
  final DateTime? arrivedAt;

  bool get isPending => status == 'PENDING';

  factory PayoutRequest.fromJson(Map<String, dynamic> j) => PayoutRequest(
    id: '${j['_id'] ?? j['id'] ?? ''}',
    amount: (_num(j['amount']) ?? 0),
    method: PayoutMethod.parse('${j['method'] ?? j['payoutMethod'] ?? ''}'),
    requestedAt:
        parseDate(j['requestedAt'] ?? j['createdAt'] ?? j['date']) ??
        DateTime.now(),
    status: '${j['status'] ?? 'PENDING'}'.toUpperCase(),
    destination: j['destination'] == null ? null : '${j['destination']}',
    note: j['note'] == null ? null : '${j['note']}',
    arrivedAt: parseDate(j['arrivedAt'] ?? j['paidAt']),
  );
}

// ── parsing helpers ────────────────────────────────────────────────────────
num? _num(dynamic v) => v is num ? v : (v is String ? num.tryParse(v) : null);
