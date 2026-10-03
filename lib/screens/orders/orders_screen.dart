import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  static const _orderStatuses = ['PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Orders',
          subtitle: 'Monitor orders, fulfilment and payments.',
        ),
        ordersAsync.when(
          data: (orders) => SmartTable(
            columns: const [
              MvColumn('Order', 'Order', bold: true),
              MvColumn('Buyer', 'Buyer'),
              MvColumn('Vendor', 'Vendor'),
              MvColumn('Total', 'Total'),
              MvColumn('Payment', 'Payment'),
              MvColumn('Status', 'Status'),
            ],
            rows: [
              for (final o in orders)
                {
                  'Order': o.display,
                  'Buyer': o.buyer ?? '—',
                  'Vendor': o.vendor ?? '—',
                  'Total': money(o.total),
                  'Payment': o.paymentStatus ?? '—',
                  'Status': o.status ?? 'PENDING',
                  '_order': o,
                },
            ],
            pageSize: 8,
            filterKey: 'Status',
            filterLabel: 'Status',
            filterOptions: _orderStatuses,
            rowActions: (row) => TableActionBtn(
              icon: 'eye',
              tooltip: 'View order',
              onPressed: () => _showOrderDetail(context, ref, row['_order'] as OrderRecord),
            ),
          ),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(ordersProvider)),
          loading: () => const LoadingState(),
        ),
      ],
    );
  }

  void _showOrderDetail(BuildContext context, WidgetRef ref, OrderRecord order) {
    showMvDetailModal(
      context,
      title: 'ORDER DETAIL',
      children: [
        KeyValueGrid(
          entries: [
            MapEntry('Order', order.display),
            MapEntry('Buyer', order.buyer ?? '—'),
            MapEntry('Vendor', order.vendor ?? '—'),
            MapEntry('Total', money(order.total)),
            MapEntry('Payment method', (order.paymentMethod ?? '—').toString()),
            MapEntry('Payment status', order.paymentStatus ?? '—'),
            MapEntry('Order status', order.status ?? '—'),
            MapEntry('Date', shortDateTime(order.createdAt)),
          ],
        ),
      ],
      footer: _OrderDetailFooter(order: order, ref: ref),
    );
  }
}

class _OrderDetailFooter extends StatefulWidget {
  const _OrderDetailFooter({required this.order, required this.ref});

  final OrderRecord order;
  final WidgetRef ref;

  @override
  State<_OrderDetailFooter> createState() => _OrderDetailFooterState();
}

class _OrderDetailFooterState extends State<_OrderDetailFooter> {
  final TextEditingController _otp = TextEditingController();
  late String _status = _initialStatus();
  bool _busy = false;

  String _initialStatus() {
    final s = widget.order.status ?? 'PENDING';
    return OrdersScreen._orderStatuses.contains(s) ? s : 'PENDING';
  }

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _saveStatus() async {
    final id = widget.order.id;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      await widget.ref.read(adminServiceProvider).patchOrderStatus(id, _status);
      if (mounted) {
        Navigator.pop(context);
        showMvSnack(context, 'Order status updated', success: true);
      }
      widget.ref.invalidate(ordersProvider);
    } catch (e) {
      if (mounted) showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deliver() async {
    final id = widget.order.id;
    if (id == null) return;
    final otp = _otp.text.trim();
    if (otp.isEmpty) {
      showMvSnack(context, 'Enter the delivery OTP');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.ref.read(adminServiceProvider).deliverOrder(id, otp);
      if (mounted) {
        Navigator.pop(context);
        showMvSnack(context, 'Marked as delivered', success: true);
      }
      widget.ref.invalidate(ordersProvider);
    } catch (e) {
      if (mounted) showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Update status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).canvasColor,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _status,
              isExpanded: true,
              items: [
                for (final s in OrdersScreen._orderStatuses)
                  DropdownMenuItem(value: s, child: Text(titleCase(s))),
              ],
              onChanged: _busy
                  ? null
                  : (v) {
                      if (v != null) setState(() => _status = v);
                    },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _otp,
                decoration: const InputDecoration(labelText: 'Delivery OTP', isDense: true),
              ),
            ),
            const SizedBox(width: 10),
            OutlineMvButton(label: 'Deliver', icon: 'box', onPressed: _busy ? null : _deliver),
          ],
        ),
        const SizedBox(height: 14),
        GradientButton(label: 'Save status', icon: 'check', expanded: true, onPressed: _busy ? null : _saveStatus),
      ],
    );
  }
}