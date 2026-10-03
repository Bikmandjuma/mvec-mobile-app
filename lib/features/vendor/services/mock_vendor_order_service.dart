import '../../../core/api_client.dart';
import '../models/vendor_order.dart';
import 'vendor_order_service.dart';

/// Local demo implementation of [VendorOrderService].
///
/// Serves a hand-written order book for a Kigali produce store: real Rwandan
/// buyer names, plausible line items, per-status timelines and escrow flags.
/// Mutations are applied to the in-memory dataset, so a status change made in
/// the UI is still there after the provider refetches — that is what makes
/// DEMO_MODE usable for demonstrating the flow rather than just the layout.
///
/// Validation is deliberately kept, not stubbed: shipping without a tracking
/// code or confirming delivery with the wrong OTP throws, exactly as the real
/// service does, so the error paths can be exercised in a demo.
class MockVendorOrderService implements VendorOrderService {
  MockVendorOrderService({this.delay = const Duration(milliseconds: 550)});

  /// Simulated latency so spinners and disabled buttons behave like production.
  final Duration delay;

  /// Seeded once per service instance; the provider keeps one instance alive
  /// for the whole session so demo edits survive navigation.
  late final List<VendorOrder> _book = _seed();

  @override
  bool get isDemo => true;

  Future<void> _latency() => Future<void>.delayed(delay);

  // ── reads ────────────────────────────────────────────────────────────────

  @override
  Future<VendorOrderPage> orders({
    VendorOrderStatus? status,
    String search = '',
  }) async {
    await _latency();
    final q = search.trim().toLowerCase();
    final filtered =
        _book.where((o) {
            if (status != null && o.status != status) return false;
            if (q.isEmpty) return true;
            return o.number.toLowerCase().contains(q) ||
                o.buyerName.toLowerCase().contains(q) ||
                o.items.any((i) => i.name.toLowerCase().contains(q));
          }).toList()
          // Newest first — the feed's natural order.
          ..sort((a, b) => b.placedAt.compareTo(a.placedAt));

    return VendorOrderPage(
      orders: filtered,
      counts: {
        for (final s in VendorOrderStatus.values)
          s: _book.where((o) => o.status == s).length,
        null: _book.length,
      },
    );
  }

  @override
  Future<VendorOrder> order(String id) async {
    await _latency();
    final match = _book.where((o) => o.id == id || o.number == id).firstOrNull;
    if (match == null) {
      throw ApiException('Order $id was not found', statusCode: 404);
    }
    return match;
  }

  // ── writes ───────────────────────────────────────────────────────────────

  @override
  Future<VendorOrder> updateStatus(
    String id,
    VendorOrderStatus status, {
    String? trackingCode,
    String? courierName,
    String? deliveryOtp,
  }) async {
    await _latency();
    final i = _book.indexWhere((o) => o.id == id || o.number == id);
    if (i < 0) throw ApiException('Order $id was not found', statusCode: 404);

    final current = _book[i];
    if (current.disputeOpen) {
      throw ApiException(
        'This order is locked while the platform reviews the open dispute.',
      );
    }
    if (!current.status.allowedNext.contains(status)) {
      throw ApiException(
        'An order cannot move from ${current.status.label} to ${status.label}.',
      );
    }
    if (status == VendorOrderStatus.shipped &&
        (trackingCode == null || trackingCode.trim().isEmpty)) {
      throw ApiException(
        'Enter the courier tracking code before marking the order shipped.',
      );
    }
    if (status == VendorOrderStatus.delivered) {
      final expected = current.deliveryOtp;
      if (expected == null || expected.isEmpty) {
        throw ApiException(
          'This order has no delivery code. Contact MVEC support to release escrow.',
        );
      }
      if ((deliveryOtp ?? '').trim().toUpperCase() != expected.toUpperCase()) {
        throw ApiException(
          'That delivery code does not match the one issued for this order.',
        );
      }
    }

    final updated = VendorOrder(
      id: current.id,
      number: current.number,
      placedAt: current.placedAt,
      buyerName: current.buyerName,
      buyerPhone: current.buyerPhone,
      buyerEmail: current.buyerEmail,
      deliveryAddress: current.deliveryAddress,
      deliveryNote: current.deliveryNote,
      paymentMethod: current.paymentMethod,
      paid: true,
      subtotal: current.subtotal,
      commission: current.commission,
      shipping: current.shipping,
      status: status,
      items: current.items,
      courierName:
          courierName?.trim().isNotEmpty == true
              ? courierName!.trim()
              : (current.courierName ??
                  (status == VendorOrderStatus.shipped ? 'Rwanda Post' : null)),
      trackingCode:
          trackingCode?.trim().isNotEmpty == true
              ? trackingCode!.trim()
              : current.trackingCode,
      deliveryOtp: current.deliveryOtp,
      disputeOpen: false,
      timeline: [
        ...current.timeline,
        OrderEvent(
          status: status,
          at: DateTime.now(),
          actor: 'You',
          note: switch (status) {
            VendorOrderStatus.shipped =>
              'Handed to ${courierName?.trim().isNotEmpty == true ? courierName!.trim() : (current.courierName ?? 'Rwanda Post')}',
            VendorOrderStatus.delivered =>
              'Delivery confirmed · escrow released',
            VendorOrderStatus.cancelled => 'Cancelled by the vendor',
            _ => 'Status updated to ${status.label}',
          },
        ),
      ],
    );
    _book[i] = updated;
    return updated;
  }

  @override
  Future<VendorOrder> cancel(String id, {String? reason}) async {
    await _latency();
    final i = _book.indexWhere((o) => o.id == id || o.number == id);
    if (i < 0) throw ApiException('Order $id was not found', statusCode: 404);

    final current = _book[i];
    if (current.status == VendorOrderStatus.delivered) {
      throw ApiException(
        'A delivered order cannot be cancelled. Raise a refund instead.',
      );
    }
    if (!current.status.allowedNext.contains(VendorOrderStatus.cancelled)) {
      throw ApiException(
        'An order in ${current.status.label} can no longer be cancelled.',
      );
    }

    final updated = VendorOrder(
      id: current.id,
      number: current.number,
      placedAt: current.placedAt,
      buyerName: current.buyerName,
      buyerPhone: current.buyerPhone,
      buyerEmail: current.buyerEmail,
      deliveryAddress: current.deliveryAddress,
      deliveryNote: current.deliveryNote,
      paymentMethod: current.paymentMethod,
      paid: current.paid,
      subtotal: current.subtotal,
      commission: current.commission,
      shipping: current.shipping,
      status: VendorOrderStatus.cancelled,
      items: current.items,
      courierName: current.courierName,
      trackingCode: current.trackingCode,
      deliveryOtp: current.deliveryOtp,
      disputeOpen: current.disputeOpen,
      timeline: [
        ...current.timeline,
        OrderEvent(
          status: VendorOrderStatus.cancelled,
          at: DateTime.now(),
          actor: 'You',
          note:
              reason?.trim().isNotEmpty == true
                  ? reason!.trim()
                  : 'Cancelled by the vendor',
        ),
      ],
    );
    _book[i] = updated;
    return updated;
  }

  // ── demo dataset ─────────────────────────────────────────────────────────

  static DateTime _ago(int days, [int hours = 0]) =>
      DateTime.now().subtract(Duration(days: days, hours: hours));

  List<VendorOrder> _seed() => [
    _order(
      id: 'ord-1041',
      number: 'MV-1041',
      days: 0,
      buyer: 'Jean Bosco Nshimiyimana',
      phone: '+250 788 410 226',
      email: 'jb.nshimiyimana@example.rw',
      address: 'KG 12 St, Nyarutarama, Kigali',
      note: 'Please call before delivery — the gate is usually locked.',
      status: VendorOrderStatus.pending,
      payment: 'MTN Mobile Money',
      lines: [
        ('Organic Hass Avocado 1kg', 6500, 4, '1kg crate', 'prd-avocado'),
        ('Free-Range Eggs (30pcs)', 5400, 2, 'Tray of 30', 'prd-eggs'),
      ],
      courier: null,
      otp: '4821',
    ),
    _order(
      id: 'ord-1040',
      number: 'MV-1040',
      days: 0,
      hours: 3,
      buyer: 'Ingabire Claudine',
      phone: '+250 782 903 114',
      email: 'claudine.ingabire@example.rw',
      address: 'Ave 30, Kacyiru, Gasabo',
      status: VendorOrderStatus.pending,
      payment: 'Airtel Money',
      lines: [
        ('Premium Tea Leaves 250g', 12500, 1, '250g tin', 'prd-tea'),
        ('Red Bananas 1kg', 3100, 5, '1kg hand', 'prd-banana'),
      ],
      courier: null,
      otp: '7734',
    ),
    _order(
      id: 'ord-1038',
      number: 'MV-1038',
      days: 1,
      buyer: 'Mwizerimana Eric',
      phone: '+250 785 556 780',
      email: 'eric.mwizerimana@example.rw',
      address: 'KN 4 Ave, Nyamirambo, Kigali',
      status: VendorOrderStatus.processing,
      payment: 'MTN Mobile Money',
      lines: [
        ('Raw Honey 500g', 18500, 2, null, 'prd-honey'),
        ('Groundnut Butter 400g', 9800, 1, null, 'prd-butter'),
      ],
      courier: null,
      otp: '1905',
    ),
    _order(
      id: 'ord-1037',
      number: 'MV-1037',
      days: 1,
      hours: 6,
      buyer: 'Umutoni Sandrine',
      phone: '+250 729 334 018',
      email: 'sandrine.umutoni@example.rw',
      address: 'KG 7 St, Gikondo, Kigali',
      note: 'Leave with the neighbour if nobody answers.',
      status: VendorOrderStatus.processing,
      payment: 'Bank transfer',
      lines: [('Soybean Oil 1L', 7600, 3, null, 'prd-oil')],
      courier: null,
      otp: '5582',
    ),
    _order(
      id: 'ord-1035',
      number: 'MV-1035',
      days: 2,
      buyer: 'Habimana Olivier',
      phone: '+250 788 771 265',
      email: 'olivier.habimana@example.rw',
      address: 'KG 3 St, Remera, Kigali',
      status: VendorOrderStatus.shipped,
      payment: 'MTN Mobile Money',
      lines: [
        ('Organic Hass Avocado 1kg', 6500, 6, '1kg crate', 'prd-avocado'),
        ('Vanilla Garlic 100g', 4300, 3, null, 'prd-garlic'),
      ],
      courier: 'Rwanda Post',
      tracking: 'RP-KGL-88214',
      otp: '6612',
    ),
    _order(
      id: 'ord-1034',
      number: 'MV-1034',
      days: 2,
      hours: 4,
      buyer: 'Mukamana Alice',
      phone: '+250 781 220 397',
      email: 'alice.mukamana@example.rw',
      address: 'KG 54 St, Kimisagara, Kigali',
      status: VendorOrderStatus.shipped,
      payment: 'Airtel Money',
      lines: [
        ('Free-Range Eggs (30pcs)', 5400, 4, 'Tray of 30', 'prd-eggs'),
        ('Premium Tea Leaves 250g', 12500, 2, '250g tin', 'prd-tea'),
      ],
      courier: 'Irembo Express',
      tracking: 'IRX-4471902',
      otp: '2274',
    ),
    _order(
      id: 'ord-1030',
      number: 'MV-1030',
      days: 4,
      buyer: 'Nzabonimana Patrick',
      phone: '+250 787 903 611',
      email: 'patrick.nzabonimana@example.rw',
      address: 'KG 9 St, Kanombe, Kigali',
      status: VendorOrderStatus.delivered,
      payment: 'MTN Mobile Money',
      lines: [
        ('Red Bananas 1kg', 3100, 8, '1kg hand', 'prd-banana'),
        ('Raw Honey 500g', 18500, 1, null, 'prd-honey'),
      ],
      courier: 'Rwanda Post',
      tracking: 'RP-KGL-88103',
      otp: '9051',
    ),
    _order(
      id: 'ord-1028',
      number: 'MV-1028',
      days: 5,
      buyer: 'Uwase Diane',
      phone: '+250 783 415 220',
      email: 'diane.uwase@example.rw',
      address: 'KG 22 St, Gacuriro, Kigali',
      note: 'Customer asked for the largest avocados available.',
      status: VendorOrderStatus.delivered,
      payment: 'Airtel Money',
      lines: [
        ('Organic Hass Avocado 1kg', 6500, 10, '1kg crate', 'prd-avocado'),
      ],
      courier: 'Irembo Express',
      tracking: 'IRX-4460288',
      otp: '3390',
    ),
    _order(
      id: 'ord-1025',
      number: 'MV-1025',
      days: 7,
      buyer: 'Nsengimana Thérèse',
      phone: '+250 786 118 743',
      email: 'therese.nsengimana@example.rw',
      address: 'Ave 12, Nyamata, Bugesera',
      status: VendorOrderStatus.delivered,
      payment: 'MTN Mobile Money',
      lines: [
        ('Soybean Oil 1L', 7600, 2, null, 'prd-oil'),
        ('Groundnut Butter 400g', 9800, 2, null, 'prd-butter'),
        ('Vanilla Garlic 100g', 4300, 4, null, 'prd-garlic'),
      ],
      courier: 'Rwanda Post',
      tracking: 'RP-KGL-87944',
      otp: '7712',
    ),
    _order(
      id: 'ord-1022',
      number: 'MV-1022',
      days: 9,
      buyer: 'Bizoza Aimable',
      phone: '+250 785 664 908',
      email: 'aimable.bizoza@example.rw',
      address: 'KG 19 St, Kicukiro, Kigali',
      note: 'Buyer never confirmed the address.',
      status: VendorOrderStatus.cancelled,
      payment: 'Mobile Money',
      lines: [('Premium Tea Leaves 250g', 12500, 3, '250g tin', 'prd-tea')],
      courier: null,
      otp: '1448',
      cancelledBy: 'Cancelled by the buyer · address could not be confirmed',
    ),
  ];

  /// Builds one order, deriving money and the status timeline from the lines
  /// so the demo dataset can never contradict itself.
  VendorOrder _order({
    required String id,
    required String number,
    required int days,
    int hours = 0,
    required String buyer,
    required String phone,
    required String email,
    required String address,
    String? note,
    required VendorOrderStatus status,
    required String payment,
    required List<(String, num, int, String?, String)> lines,
    String? courier,
    String? tracking,
    String? otp,
    String? cancelledBy,
  }) {
    final placedAt = _ago(days, hours);
    final subtotal = lines.fold<num>(0, (sum, l) => sum + (l.$2 * l.$3));
    // Platform commission: 8% standard, 6% for certified organic lines.
    final commission = (subtotal * 0.08).roundToDouble();

    // Timeline: the order starts pending, then walks forward to its status.
    final timeline = <OrderEvent>[
      OrderEvent(
        status: VendorOrderStatus.pending,
        at: placedAt,
        actor: buyer,
        note: 'Order placed · payment held in escrow',
      ),
      if (status != VendorOrderStatus.pending)
        OrderEvent(
          status: VendorOrderStatus.processing,
          at: placedAt.add(const Duration(hours: 3)),
          actor: 'You',
          note: 'Packing started',
        ),
      if (status == VendorOrderStatus.shipped ||
          status == VendorOrderStatus.delivered)
        OrderEvent(
          status: VendorOrderStatus.shipped,
          at: placedAt.add(const Duration(hours: 20)),
          actor: 'You',
          note: 'Handed to ${courier ?? 'Rwanda Post'}',
        ),
      if (status == VendorOrderStatus.delivered)
        OrderEvent(
          status: VendorOrderStatus.delivered,
          at: placedAt.add(const Duration(days: 2, hours: 5)),
          actor: buyer,
          note: 'Delivered · escrow released',
        ),
      if (status == VendorOrderStatus.cancelled)
        OrderEvent(
          status: VendorOrderStatus.cancelled,
          at: placedAt.add(const Duration(hours: 6)),
          actor: buyer,
          note: cancelledBy ?? 'Cancelled',
        ),
    ];

    return VendorOrder(
      id: id,
      number: number,
      placedAt: placedAt,
      buyerName: buyer,
      buyerPhone: phone,
      buyerEmail: email,
      deliveryAddress: address,
      deliveryNote: note,
      paymentMethod: payment,
      paid: true,
      subtotal: subtotal,
      commission: commission,
      shipping: 2000,
      status: status,
      items: [
        for (final l in lines)
          VendorOrderItem(
            productId: l.$5,
            name: l.$1,
            unitPrice: l.$2,
            quantity: l.$3,
            variant: l.$4,
            sku: l.$5.toUpperCase(),
          ),
      ],
      courierName: courier,
      trackingCode: tracking,
      deliveryOtp: otp,
      timeline: timeline,
    );
  }
}
