import '../../../core/api_client.dart';
import '../models/vendor_finance.dart';

/// Contract for the vendor's money: summary metrics, the transaction ledger and
/// withdrawal requests.
///
/// [MockVendorFinanceService] and [ApiVendorFinanceService] are interchangeable;
/// see `vendor_dependencies.dart` for the DEMO_MODE switch.
abstract class VendorFinanceService {
  bool get isDemo;

  /// The four headline balances plus the commission rate and the daily series.
  Future<VendorFinanceSummary> summary();

  /// The money ledger, newest first, optionally narrowed to one [kind].
  Future<List<LedgerEntry>> ledger({LedgerEntryKind? kind, int limit = 50});

  /// Withdrawal requests, newest first. Pending ones are excluded from the
  /// available balance, so this list is what the payout form validates against.
  Future<List<PayoutRequest>> payouts();

  /// Requests a withdrawal of [amount].
  ///
  /// Throws when [amount] exceeds the available balance, falls under the
  /// platform minimum, or the destination is missing for the chosen [method].
  Future<PayoutRequest> requestPayout({
    required num amount,
    required PayoutMethod method,
    required String destination,
    String? note,
  });
}

/// Minimum withdrawal the platform will process, in RWF.
const double kMinPayoutAmount = 50000;

/// Talks to the platform's finance API.
class ApiVendorFinanceService implements VendorFinanceService {
  ApiVendorFinanceService(this._api);
  final ApiClient _api;

  @override
  bool get isDemo => false;

  @override
  Future<VendorFinanceSummary> summary() async {
    final res = await _api.get('/stores/mine/finance/summary');
    return VendorFinanceSummary.fromJson(singleJson(res, ['summary', 'finance', 'data']));
  }

  @override
  Future<List<LedgerEntry>> ledger({LedgerEntryKind? kind, int limit = 50}) async {
    final res = await _api.get('/stores/mine/finance/ledger', query: {
      'limit': limit,
      if (kind != null) 'kind': kind.slug,
    });
    return listJson(res, ['entries', 'ledger', 'data']).map(LedgerEntry.fromJson).toList();
  }

  @override
  Future<List<PayoutRequest>> payouts() async {
    final res = await _api.get('/stores/mine/finance/payouts', query: {'limit': 30});
    return listJson(res, ['payouts', 'withdrawals', 'data']).map(PayoutRequest.fromJson).toList();
  }

  @override
  Future<PayoutRequest> requestPayout({
    required num amount,
    required PayoutMethod method,
    required String destination,
    String? note,
  }) async {
    final res = await _api.post('/stores/mine/finance/payouts', body: {
      'amount': amount,
      'method': method.slug,
      'destination': destination.trim(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return PayoutRequest.fromJson(singleJson(res, ['payout']));
  }
}
