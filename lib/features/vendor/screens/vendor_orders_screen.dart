import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../widgets/common.dart';
import '../models/vendor_order.dart';
import '../services/vendor_order_service.dart';
import '../vendor_dependencies.dart';
import '../widgets/vendor_dashboard_widgets.dart';

/// Vendor order queue with status filters and the escrow-aware detail flow.
class VendorOrdersScreen extends ConsumerStatefulWidget {
  const VendorOrdersScreen({super.key, this.initialOrderId});

  final String? initialOrderId;

  @override
  ConsumerState<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends ConsumerState<VendorOrdersScreen> {
  VendorOrderStatus? _filter;
  String? _scheduledInitialOrderId;

  @override
  void didUpdateWidget(covariant VendorOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialOrderId != widget.initialOrderId) {
      _scheduledInitialOrderId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(vendorOrdersPageProvider(null));
    if (ordersAsync case AsyncData(:final value)) {
      final orderId = widget.initialOrderId;
      if (orderId != null && orderId != _scheduledInitialOrderId) {
        final match =
            value.orders
                .where(
                  (order) => order.id == orderId || order.number == orderId,
                )
                .firstOrNull;
        if (match != null) {
          _scheduledInitialOrderId = orderId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showDetails(match);
          });
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'FULFILMENT',
          title: 'Orders',
          subtitle:
              'Move each order forward and keep delivery confirmation secure.',
          actions: [
            IconButton(
              tooltip: 'Refresh orders',
              onPressed: () => ref.invalidate(vendorOrdersPageProvider(null)),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        _filters(ordersAsync.valueOrNull),
        const SizedBox(height: 12),
        switch (ordersAsync) {
          AsyncLoading() => const SizedBox(height: 240, child: LoadingState()),
          AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry: () => ref.invalidate(vendorOrdersPageProvider(null)),
          ),
          AsyncData(:final value) => _orderList(value.orders),
          _ => const SizedBox(height: 240, child: LoadingState()),
        },
      ],
    );
  }

  Widget _filters(VendorOrderPage? page) {
    final labels = <(String, VendorOrderStatus?)>[
      ('All', null),
      for (final status in VendorOrderStatus.values) (status.label, status),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            ChoiceChip(
              label: Text(
                '${labels[i].$1}  ${labels[i].$2 == null ? page?.total ?? '—' : page?.counts[labels[i].$2] ?? 0}',
              ),
              selected: _filter == labels[i].$2,
              onSelected: (_) => setState(() => _filter = labels[i].$2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _orderList(List<VendorOrder> orders) {
    final filtered =
        _filter == null
            ? orders
            : orders.where((order) => order.status == _filter).toList();
    if (filtered.isEmpty) {
      return const EmptyState(message: 'No orders in this status yet.');
    }
    return Column(
      children: [
        for (final order in filtered)
          VendorOrderCard(order: order, onTap: () => _showDetails(order)),
      ],
    );
  }

  Future<void> _showDetails(VendorOrder order) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _VendorOrderDetails(order: order),
    );
    if (mounted) {
      ref.invalidate(vendorOrdersPageProvider(null));
    }
  }
}

class _VendorOrderDetails extends ConsumerStatefulWidget {
  const _VendorOrderDetails({required this.order});
  final VendorOrder order;

  @override
  ConsumerState<_VendorOrderDetails> createState() =>
      _VendorOrderDetailsState();
}

class _VendorOrderDetailsState extends ConsumerState<_VendorOrderDetails> {
  final _tracking = TextEditingController();
  final _courier = TextEditingController(text: 'Rwanda Post');
  final _otp = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _tracking.dispose();
    _courier.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final palette = context.mv;
    final next = order.status.primaryNext;
    return FractionallySizedBox(
      heightFactor: .94,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.number,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      StatusChip(order.status.label),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close details',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                if (order.disputeOpen)
                  const InfoBox(
                    'An open dispute locks status updates until the case is resolved.',
                    icon: 'bell',
                  ),
                _section('BUYER', [
                  _detailLine('Name', order.buyerName),
                  _detailLine('Phone', order.buyerPhone ?? 'Not provided'),
                  _detailLine('Email', order.buyerEmail ?? 'Not provided'),
                  _detailLine(
                    'Delivery address',
                    order.deliveryAddress ?? 'Not provided',
                  ),
                  if (order.deliveryNote?.isNotEmpty == true)
                    _detailLine('Delivery note', order.deliveryNote!),
                ]),
                _section('ITEMS', [
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${item.variant == null ? '' : '${item.variant} · '}${item.quantity} × ${money(item.unitPrice)}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            money(item.lineTotal),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  _detailLine('Items subtotal', money(order.subtotal)),
                  _detailLine('Delivery', money(order.shipping)),
                  _detailLine(
                    'Platform commission',
                    '−${money(order.commission)}',
                  ),
                  _detailLine(
                    'Your net earnings',
                    money(order.vendorNet),
                    strong: true,
                  ),
                ]),
                _section('STATUS TIMELINE', [
                  for (final event in order.timeline.reversed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: MvColors.primaryDeep,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${event.status.label}${event.actor == null ? '' : ' · ${event.actor}'}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (event.note != null)
                                  Text(
                                    event.note!,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                Text(
                                  shortDateTime(event.at),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ]),
                if (order.status == VendorOrderStatus.processing) ...[
                  _textInput(_courier, 'Courier service', 'Courier name'),
                  const SizedBox(height: 9),
                  _textInput(
                    _tracking,
                    'Tracking code',
                    'Enter courier tracking code',
                  ),
                ],
                if (order.status == VendorOrderStatus.shipped) ...[
                  const InfoBox(
                    'Confirm delivery with the buyer’s one-time code. Escrow is released only after this check.',
                    icon: 'shield',
                  ),
                  if (order.deliveryOtp != null &&
                      ref.read(vendorOrderModuleProvider).isDemo) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Demo buyer OTP: ${order.deliveryOtp}',
                      style: TextStyle(color: palette.textMuted, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 9),
                  _textInput(
                    _otp,
                    'Buyer delivery OTP',
                    'Enter the code shared by the buyer',
                  ),
                ],
              ],
            ),
          ),
          if (next != null ||
              order.status.allowedNext.contains(VendorOrderStatus.cancelled))
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
              child: Column(
                children: [
                  if (next != null)
                    GradientButton(
                      label:
                          _busy
                              ? 'Updating…'
                              : switch (next) {
                                VendorOrderStatus.processing =>
                                  'Start processing',
                                VendorOrderStatus.shipped => 'Mark as shipped',
                                VendorOrderStatus.delivered =>
                                  'Confirm delivery',
                                VendorOrderStatus.cancelled => 'Cancel order',
                                VendorOrderStatus.pending => 'Pending',
                              },
                      icon: 'check',
                      expanded: true,
                      onPressed:
                          _busy || order.disputeOpen
                              ? null
                              : () => _advance(next),
                    ),
                  if (order.status.allowedNext.contains(
                    VendorOrderStatus.cancelled,
                  ))
                    TextButton.icon(
                      onPressed: _busy || order.disputeOpen ? null : _cancel,
                      icon: const Icon(Icons.cancel_outlined, size: 17),
                      label: const Text('Cancel order'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _textInput(
    TextEditingController controller,
    String label,
    String hint,
  ) => TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
    ),
  );

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: .6,
            fontWeight: FontWeight.w900,
            color: MvColors.primaryDeep,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );

  Widget _detailLine(String label, String value, {bool strong = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 125,
              child: Text(
                label,
                style: TextStyle(fontSize: 11, color: context.mv.textMuted),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _advance(VendorOrderStatus status) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(vendorOrderModuleProvider)
          .updateStatus(
            widget.order.id,
            status,
            trackingCode: _tracking.text,
            courierName: _courier.text,
            deliveryOtp: _otp.text,
          );
      ref.invalidate(vendorOrdersPageProvider(null));
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final message =
            status == VendorOrderStatus.delivered
                ? 'Delivery confirmed and escrow released'
                : 'Order moved to ${status.label}';
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: MvColors.successText2,
          ),
        );
      }
    } catch (error) {
      if (mounted) showMvSnack(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel order?'),
            content: TextField(
              controller: reason,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep order'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cancel order'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(vendorOrderModuleProvider)
          .cancel(widget.order.id, reason: reason.text);
      ref.invalidate(vendorOrdersPageProvider(null));
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Order cancelled'),
            backgroundColor: MvColors.successText2,
          ),
        );
      }
    } catch (error) {
      if (mounted) showMvSnack(context, friendlyError(error));
    } finally {
      reason.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }
}
