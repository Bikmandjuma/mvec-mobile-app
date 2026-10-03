/// Order domain for the vendor portal — the subset of a platform order that a
/// store owner is allowed to see and act on.
///
/// Parsing is deliberately forgiving: the same record arrives from two shapes
/// (the platform's `order` envelope and the demo dataset), and both use
/// slightly different key names for money and status.
library;

import '../../../models/user.dart';
import '../../../core/utils.dart';

/// The vendor-facing order lifecycle.
///
/// Deliberately narrower than the buyer-facing `OrderStatus` in
/// `models/order.dart`: a vendor confirms fulfilment, never payment.
enum VendorOrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled;

  /// Stable slugs sent to the API, e.g. `PATCH /orders/{id}/status`.
  String get slug => switch (this) {
        VendorOrderStatus.pending => 'PENDING',
        VendorOrderStatus.processing => 'PROCESSING',
        VendorOrderStatus.shipped => 'SHIPPED',
        VendorOrderStatus.delivered => 'DELIVERED',
        VendorOrderStatus.cancelled => 'CANCELLED',
      };

  /// Title shown in the status chip, filter tabs and timeline.
  String get label => switch (this) {
        VendorOrderStatus.pending => 'Pending',
        VendorOrderStatus.processing => 'Processing',
        VendorOrderStatus.shipped => 'Shipped',
        VendorOrderStatus.delivered => 'Delivered',
        VendorOrderStatus.cancelled => 'Cancelled',
      };

  /// One-line explanation shown under the status chip so the vendor always
  /// knows what the current state means and what unlocks next.
  String get description => switch (this) {
        VendorOrderStatus.pending => 'Payment is held in escrow. Confirm and start packing to move this order forward.',
        VendorOrderStatus.processing => 'You are packing this order. Add a courier tracking code once it leaves your store.',
        VendorOrderStatus.shipped => 'Handed to the courier. Confirm delivery with the buyer OTP to release escrow.',
        VendorOrderStatus.delivered => 'Delivered and confirmed. Escrow has been released to your balance.',
        VendorOrderStatus.cancelled => 'Cancelled. The buyer has been refunded and this order is closed.',
      };

  /// True while the order still needs work from the vendor. Drives the
  /// "action needed" badge on the order card.
  bool get isOpen =>
      this == VendorOrderStatus.pending ||
      this == VendorOrderStatus.processing ||
      this == VendorOrderStatus.shipped;

  /// The statuses a vendor may move this order to.
  ///
  /// Keeps the UI honest: a delivered or cancelled order has no forward
  /// transition, and the platform rejects the invalid moves anyway.
  List<VendorOrderStatus> get allowedNext => switch (this) {
        VendorOrderStatus.pending => const [VendorOrderStatus.processing, VendorOrderStatus.cancelled],
        VendorOrderStatus.processing => const [VendorOrderStatus.shipped, VendorOrderStatus.cancelled],
        VendorOrderStatus.shipped => const [VendorOrderStatus.delivered],
        VendorOrderStatus.delivered || VendorOrderStatus.cancelled => const [],
      };

  /// The primary forward action, i.e. the "next step" button. Cancellation is
  /// deliberately excluded — it is offered as a secondary destructive action.
  VendorOrderStatus? get primaryNext =>
      allowedNext.where((s) => s != VendorOrderStatus.cancelled).firstOrNull;

  /// Filter tabs on the orders screen, in order, with counts filled in later.
  static const filterOrder = <VendorOrderStatus?>[
    null, // "All"
    VendorOrderStatus.pending,
    VendorOrderStatus.processing,
    VendorOrderStatus.shipped,
    VendorOrderStatus.delivered,
    VendorOrderStatus.cancelled,
  ];

  /// Parses a backend or mock status slug (`"out_for_delivery"`, `"shipped"`).
  static VendorOrderStatus parse(String? raw) {
    final v = raw?.trim().toLowerCase().replaceAll('-', '_');
    return switch (v) {
      'processing' || 'confirmed' || 'preparing' => VendorOrderStatus.processing,
      'shipped' || 'in_transit' || 'dispatched' => VendorOrderStatus.shipped,
      'delivered' || 'completed' => VendorOrderStatus.delivered,
      'cancelled' || 'canceled' || 'refunded' => VendorOrderStatus.cancelled,
      _ => VendorOrderStatus.pending,
    };
  }
}

/// One line of an order: a product, the variant bought and the price agreed.
class VendorOrderItem {
  const VendorOrderItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.variant,
    this.imageUrl,
    this.sku,
  });

  final String productId;
  final String name;
  final num unitPrice;
  final int quantity;

  /// Human-readable variant summary, e.g. `"Red · Large"`.
  final String? variant;
  final String? imageUrl;
  final String? sku;

  /// Line total, derived rather than trusted from the payload so a stale
  /// server-side `lineTotal` can never disagree with price × quantity.
  num get lineTotal => unitPrice * quantity;

  factory VendorOrderItem.fromJson(Map<String, dynamic> j) {
    final product = j['product'] is Map
        ? Map<String, dynamic>.from(j['product'] as Map)
        : const <String, dynamic>{};
    final attrs = j['attributes'] is Map
        ? Map<String, dynamic>.from(j['attributes'] as Map)
        : const <String, dynamic>{};
    final variants = <String>[
      if ((j['variant'] ?? j['size'] ?? attrs['size']) != null) '${j['variant'] ?? j['size'] ?? attrs['size']}',
      if ((j['color'] ?? attrs['color']) != null) '${j['color'] ?? attrs['color']}',
    ];
    return VendorOrderItem(
      productId: '${j['productId'] ?? j['_id'] ?? product['_id'] ?? product['id'] ?? ''}',
      name: '${j['name'] ?? j['title'] ?? product['name'] ?? 'Product'}',
      unitPrice: _num(j['unitPrice'] ?? j['price'] ?? product['price']) ?? 0,
      quantity: _int(j['quantity'] ?? j['qty']) ?? 1,
      variant: variants.isEmpty ? null : variants.join(' · '),
      imageUrl: _firstUrl(j['image'] ?? j['imageUrl'] ?? product['thumbnail'] ?? product['image']),
      sku: j['sku'] == null ? null : '${j['sku']}',
    );
  }
}

/// A single entry in the order's status history. Powers the vertical timeline
/// on the order detail sheet.
class OrderEvent {
  const OrderEvent({
    required this.status,
    required this.at,
    this.note,
    this.actor,
  });

  final VendorOrderStatus status;
  final DateTime at;

  /// Optional free text, e.g. the courier name when the order shipped.
  final String? note;

  /// Who caused the transition: the vendor, the buyer, the platform or a courier.
  final String? actor;

  factory OrderEvent.fromJson(Map<String, dynamic> j) => OrderEvent(
        status: VendorOrderStatus.parse('${j['status'] ?? ''}'),
        at: parseDate(j['at'] ?? j['createdAt'] ?? j['timestamp']) ?? DateTime.now(),
        note: j['note'] == null ? null : '${j['note']}',
        actor: j['actor'] == null ? null : '${j['actor']}',
      );
}

/// An order as the vendor sees it.
///
/// Money is split three ways, matching the platform's escrow flow:
///  * [subtotal] — what the buyer paid for the goods,
///  * [commission] — the platform fee deducted from it,
///  * [vendorNet] — what lands in the vendor's balance (`subtotal - commission`).
class VendorOrder {
  const VendorOrder({
    required this.id,
    required this.number,
    required this.placedAt,
    required this.buyerName,
    required this.items,
    this.status = VendorOrderStatus.pending,
    this.buyerPhone,
    this.buyerEmail,
    this.deliveryAddress,
    this.deliveryNote,
    this.paymentMethod = 'Mobile Money',
    this.paid = false,
    this.subtotal = 0,
    this.commission = 0,
    this.shipping = 0,
    this.courierName,
    this.trackingCode,
    this.deliveryOtp,
    this.timeline = const [],
    this.disputeOpen = false,
  });

  final String id;

  /// Human order number shown to the vendor and the buyer, e.g. `MV-4821`.
  final String number;
  final DateTime placedAt;

  final String buyerName;
  final String? buyerPhone;
  final String? buyerEmail;
  final String? deliveryAddress;
  final String? deliveryNote;
  final String paymentMethod;

  /// True once the buyer's money is confirmed and sitting in escrow.
  final bool paid;

  final num subtotal;
  final num commission;
  final num shipping;
  final VendorOrderStatus status;
  final List<VendorOrderItem> items;

  /// Courier assigned once the order ships.
  final String? courierName;
  final String? trackingCode;

  /// Code the buyer quotes to the courier. Releasing escrow requires the
  /// vendor to confirm delivery with it.
  final String? deliveryOtp;

  final List<OrderEvent> timeline;

  /// Set when the platform has an open dispute against this order — the
  /// detail sheet surfaces a warning and blocks status changes.
  final bool disputeOpen;

  /// What the vendor earns on this order.
  num get vendorNet => subtotal - commission;

  /// What the buyer paid in total, goods plus delivery.
  num get grandTotal => subtotal + shipping;

  /// Total units across all lines — the card's "3 items" summary.
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  /// True when the order still needs a next step from the vendor.
  bool get needsAction => status.isOpen && !disputeOpen;

  /// Escrow releases on confirmed delivery, not on dispatch.
  bool get escrowReleased => status == VendorOrderStatus.delivered;

  factory VendorOrder.fromJson(Map<String, dynamic> j) {
    final buyer = j['buyer'] is Map
        ? Map<String, dynamic>.from(j['buyer'] as Map)
        : const <String, dynamic>{};
    final address = j['deliveryAddress'] is Map
        ? Map<String, dynamic>.from(j['deliveryAddress'] as Map)
        : const <String, dynamic>{};
    final courier = j['courier'] is Map
        ? Map<String, dynamic>.from(j['courier'] as Map)
        : const <String, dynamic>{};

    final rawItems = (j['items'] ?? j['lines'] ?? j['products']);
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => VendorOrderItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <VendorOrderItem>[];

    final subtotal = _num(j['subtotal'] ?? j['itemsTotal'] ?? j['total']) ?? 0;
    final commission =
        _num(j['commission'] ?? j['platformFee'] ?? j['platformCommission']) ?? (subtotal * 0.1);

    return VendorOrder(
      id: '${j['_id'] ?? j['id'] ?? j['number'] ?? ''}',
      number: '${j['number'] ?? j['orderNumber'] ?? j['reference'] ?? '—'}',
      placedAt: parseDate(j['placedAt'] ?? j['createdAt'] ?? j['orderDate']) ?? DateTime.now(),
      buyerName: '${j['buyerName'] ?? buyer['name'] ?? buyer['fullname'] ?? 'Guest buyer'}',
      buyerPhone: _str(j['buyerPhone'] ?? j['phone'] ?? buyer['phone'] ?? buyer['telephone']),
      buyerEmail: _str(j['buyerEmail'] ?? j['email'] ?? buyer['email']),
      deliveryAddress: _str(j['deliveryAddress'] ?? j['address']) ??
          _joinAddress(address),
      deliveryNote: _str(j['deliveryNote'] ?? j['note'] ?? address['note']),
      paymentMethod: '${j['paymentMethod'] ?? j['payment'] ?? 'Mobile Money'}',
      paid: (j['paid'] ?? j['isPaid'] ?? j['paymentStatus'] == 'PAID') == true,
      subtotal: subtotal,
      commission: commission,
      shipping: _num(j['shipping'] ?? j['shippingFee'] ?? j['deliveryFee']) ?? 0,
      status: VendorOrderStatus.parse('${j['status'] ?? ''}'),
      items: items,
      courierName: _str(j['courierName'] ?? courier['name']),
      trackingCode: _str(j['trackingCode'] ?? j['trackingNumber'] ?? courier['trackingNumber']),
      deliveryOtp: _str(j['deliveryOtp'] ?? j['otp'] ?? j['confirmationCode']),
      disputeOpen: (j['disputeOpen'] ?? j['hasDispute'] ?? false) == true,
      timeline: (j['timeline'] ?? j['history'] ?? j['events']) is List
          ? (j['timeline'] ?? j['history'] ?? j['events'])
              .whereType<Map>()
              .map((e) => OrderEvent.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const <OrderEvent>[],
    );
  }

  /// Flattens a structured delivery address into one printable line.
  static String? _joinAddress(Map<String, dynamic> a) {
    final parts = <String>[
      if (a['street'] != null) '${a['street']}',
      if (a['district'] != null) '${a['district']}',
      if (a['city'] != null) '${a['city']}',
      if (a['country'] != null) '${a['country']}',
    ].where((p) => p.trim().isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }
}

// ── parsing helpers ────────────────────────────────────────────────────────
int? _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : (v is String ? int.tryParse(v) : null));

num? _num(dynamic v) => v is num ? v : (v is String ? num.tryParse(v) : null);

String? _str(dynamic v) => v == null ? null : '$v';

/// Accepts either a bare URL string or the `media.mainImage` object the
/// catalogue API returns.
String? _firstUrl(dynamic v) {
  if (v == null) return null;
  if (v is String) return v.isEmpty ? null : v;
  if (v is Map) {
    final m = Map<String, dynamic>.from(v);
    final url = m['mainImage'] ?? m['url'] ?? m['src'];
    return url == null ? null : '$url';
  }
  if (v is List && v.isNotEmpty) return _firstUrl(v.first);
  return null;
}

/// Formats an amount the way the vendor ledger does (RWF, no decimals).
String rwf(num? amount) => money(amount);
