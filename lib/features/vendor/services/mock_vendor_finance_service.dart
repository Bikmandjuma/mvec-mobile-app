import '../../../core/api_client.dart';
import '../models/vendor_finance.dart';
import 'vendor_finance_service.dart';

/// Local demo implementation of [VendorFinanceService].
///
/// The dataset is a small double-entry style ledger: each delivered order
/// posts a SALE, a COMMISSION and an ESCROW_RELEASE; withdrawals post a
/// PAYOUT; one refunded order posts a REFUND. The balances on
/// [summary] are derived from those same rows, so the numbers on the metric
/// cards can always be reconciled against the ledger shown underneath —
/// which is exactly what a vendor (or an auditor) will try to do in a demo.
///
/// Balances are seeded to a realistic Kigali produce store and then move as
/// the vendor requests payouts in the UI.
class MockVendorFinanceService implements VendorFinanceService {
  MockVendorFinanceService({this.delay = const Duration(milliseconds: 550)});

  final Duration delay;

  /// Opening balances, before the demo session's own payouts. Chosen so the
  /// first payout request has something to draw from.
  static const _openingEscrow = 1845000;
  static const _openingAvailable = 4260000;

  late final List<LedgerEntry> _ledger = _seed();
  late final List<PayoutRequest> _payouts = _seedPayouts();

  /// Payouts requested during this session, prepended to the seeded history.
  final List<PayoutRequest> _sessionPayouts = [];

  @override
  bool get isDemo => true;

  Future<void> _latency() => Future<void>.delayed(delay);

  // ── reads ────────────────────────────────────────────────────────────────

  @override
  Future<VendorFinanceSummary> summary() async {
    await _latency();
    final sales = _sum(LedgerEntryKind.sale);
    final refunds = _sum(LedgerEntryKind.refund);
    final commission = _sum(LedgerEntryKind.commission);

    // Money already committed to a request that has not settled yet. A
    // withdrawal in flight must not be withdrawable a second time.
    final pending = [
      ..._sessionPayouts,
      ..._payouts,
    ].where((p) => p.isPending).fold<num>(0, (s, p) => s + p.amount);

    // The opening balance already accounts for the *seeded* history (those
    // payouts and the seeded pending request), so only this session's
    // requests come off it.
    final sessionCommitted = _sessionPayouts.fold<num>(
      0,
      (s, p) => s + p.amount,
    );

    return VendorFinanceSummary(
      grossRevenue: sales - refunds,
      commission: commission,
      netEarnings: sales - refunds - commission,
      escrowHeld: _openingEscrow,
      availablePayout: _openingAvailable - sessionCommitted,
      pendingPayouts: pending,
      commissionRate: 0.08,
      revenueDelta: 0.14,
      earningsDelta: 0.11,
      series: _seedSeries(),
      lastPayoutAt:
          [
            ..._sessionPayouts,
            ..._payouts,
          ].where((p) => !p.isPending).firstOrNull?.arrivedAt,
    );
  }

  @override
  Future<List<LedgerEntry>> ledger({
    LedgerEntryKind? kind,
    int limit = 50,
  }) async {
    await _latency();
    final rows =
        kind == null ? _ledger : _ledger.where((e) => e.kind == kind).toList();
    return rows.take(limit).toList();
  }

  @override
  Future<List<PayoutRequest>> payouts() async {
    await _latency();
    return [..._sessionPayouts, ..._payouts];
  }

  // ── writes ───────────────────────────────────────────────────────────────

  @override
  Future<PayoutRequest> requestPayout({
    required num amount,
    required PayoutMethod method,
    required String destination,
    String? note,
  }) async {
    await _latency();
    if (amount < kMinPayoutAmount) {
      throw ApiException(
        'The minimum withdrawal is ${_plain(kMinPayoutAmount)} RWF.',
      );
    }
    if (destination.trim().isEmpty) {
      throw ApiException(
        'Enter the phone number or bank account to receive the money.',
      );
    }
    final available =
        _openingAvailable -
        _sessionPayouts.fold<num>(0, (sum, payout) => sum + payout.amount);
    if (amount > available) {
      throw ApiException(
        'You can withdraw at most ${_plain(available)} RWF right now.',
      );
    }

    final request = PayoutRequest(
      id: 'payout-${_sessionPayouts.length + 1}',
      amount: amount,
      method: method,
      requestedAt: DateTime.now(),
      status: 'PENDING',
      destination: destination.trim(),
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
    );
    _sessionPayouts.insert(0, request);

    // Post the withdrawal to the ledger too, so the two views stay in step.
    _ledger.insert(
      0,
      LedgerEntry(
        id: 'led-${request.id}',
        at: request.requestedAt,
        kind: LedgerEntryKind.payout,
        amount: amount,
        description: 'Withdrawal to ${method.label}',
        balanceAfter: available - amount,
        payoutMethod: method,
        payoutStatus: 'PENDING',
      ),
    );
    return request;
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Total of every ledger row of one [kind].
  num _sum(LedgerEntryKind kind) =>
      _ledger.where((e) => e.kind == kind).fold<num>(0, (s, e) => s + e.amount);

  // ── demo dataset ─────────────────────────────────────────────────────────

  /// Delivered orders the store has been paid for. Each contributes a SALE and
  /// a COMMISSION row, so the ledger visibly shows the platform's cut.
  static const _sales = <(String, String, num, int)>[
    // (order number, description, subtotal, days ago)
    ('MV-1030', '8 × Red Bananas 1kg, 1 × Raw Honey 500g', 621900, 4),
    ('MV-1028', '10 × Organic Hass Avocado 1kg', 650000, 5),
    (
      'MV-1025',
      '2 × Soybean Oil 1L, 2 × Groundnut Butter 400g, 4 × Vanilla Garlic',
      48400,
      7,
    ),
    ('MV-1019', '6 × Free-Range Eggs (30pcs)', 324000, 11),
    (
      'MV-1016',
      '4 × Premium Tea Leaves 250g, 3 × Organic Hass Avocado 1kg',
      695000,
      14,
    ),
    ('MV-1011', '5 × Raw Honey 500g, 2 × Soybean Oil 1L', 107600, 19),
    ('MV-1008', '12 × Red Bananas 1kg', 372000, 23),
    (
      'MV-1002',
      '3 × Organic Hass Avocado 1kg, 1 × Free-Range Eggs (30pcs)',
      249000,
      28,
    ),
    ('MV-0995', '2 × Premium Tea Leaves 250g', 250000, 33),
    ('MV-0988', '8 × Groundnut Butter 400g', 78400, 38),
  ];

  /// One refunded order, to exercise the negative side of the ledger.
  static const _refund = (
    'MV-0991',
    '2 × Vanilla Garlic 100g, address unreachable',
    8600,
    35,
  );

  static DateTime _ago(int days) =>
      DateTime.now().subtract(Duration(days: days));

  List<LedgerEntry> _seed() {
    final rows = <LedgerEntry>[];

    for (final (number, description, subtotal, days) in _sales) {
      final at = _ago(days);
      final commission = (subtotal * 0.08).roundToDouble();
      rows.add(
        LedgerEntry(
          id: 'led-$number',
          at: at,
          kind: LedgerEntryKind.sale,
          amount: subtotal,
          description: description,
          orderNumber: number,
        ),
      );
      rows.add(
        LedgerEntry(
          id: 'led-$number-fee',
          at: at.add(const Duration(minutes: 2)),
          kind: LedgerEntryKind.commission,
          amount: commission,
          description: 'Platform commission (8%) on $number',
          orderNumber: number,
        ),
      );
    }

    final (refundNo, refundDesc, refundAmount, refundDays) = _refund;
    rows.add(
      LedgerEntry(
        id: 'led-$refundNo',
        at: _ago(refundDays),
        kind: LedgerEntryKind.refund,
        amount: refundAmount,
        description: refundDesc,
        orderNumber: refundNo,
      ),
    );

    // Seeded withdrawal history, so the "recent withdrawals" list is not empty
    // on first open. The amounts are already reflected in the opening balance.
    rows.add(
      LedgerEntry(
        id: 'led-payout-hist-1',
        at: _ago(6),
        kind: LedgerEntryKind.payout,
        amount: 1800000,
        description: 'Withdrawal to MTN Mobile Money',
        balanceAfter: _openingAvailable,
        payoutMethod: PayoutMethod.mtnMomo,
        payoutStatus: 'PAID',
      ),
    );
    rows.add(
      LedgerEntry(
        id: 'led-payout-hist-2',
        at: _ago(20),
        kind: LedgerEntryKind.payout,
        amount: 1500000,
        description: 'Withdrawal to Equity Bank',
        balanceAfter: 6060000,
        payoutMethod: PayoutMethod.bankTransfer,
        payoutStatus: 'PAID',
      ),
    );

    // Newest first.
    rows.sort((a, b) => b.at.compareTo(a.at));
    return rows;
  }

  List<PayoutRequest> _seedPayouts() => [
    PayoutRequest(
      id: 'payout-hist-1',
      amount: 1800000,
      method: PayoutMethod.mtnMomo,
      requestedAt: _ago(6),
      arrivedAt: _ago(6).add(const Duration(minutes: 14)),
      status: 'PAID',
      destination: '+250 78••• 214',
      note: 'Weekly settlement',
    ),
    PayoutRequest(
      id: 'payout-hist-2',
      amount: 1500000,
      method: PayoutMethod.bankTransfer,
      requestedAt: _ago(20),
      arrivedAt: _ago(19),
      status: 'PAID',
      destination: 'Equity ••••4471',
    ),
    PayoutRequest(
      id: 'payout-hist-3',
      amount: 900000,
      method: PayoutMethod.airtelMoney,
      requestedAt: _ago(2),
      status: 'PENDING',
      destination: '+250 73••• 908',
      note: 'Awaiting escrow release',
    ),
  ];

  /// Two weeks of daily net earnings for the sparkline on the sales screen.
  static List<EarningsPoint> _seedSeries() {
    const daily = <num>[
      148000, 96000, 212000, 176000, 224000, 86000, 34000, //
      196000, 128000, 268000, 154000, 98000, 42000, 52000,
    ];
    return [
      for (var i = daily.length - 1; i >= 0; i--)
        EarningsPoint(at: _ago(i), net: daily[daily.length - 1 - i]),
    ];
  }

  /// RWF amount without a currency suffix, for messages.
  static String _plain(num v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
