import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../features/supplier/data/supplier_workspace.dart';
import '../../widgets/common.dart';

/// Wholesale orders placed by vendors, mirroring the web app's
/// `SupplierOrders` ("B2B ORDERS" page head + order table).
///
/// The web's Payment/Funds columns are literal values in a hand-written array
/// (`payment:"SUCCESS"`, `settlement:"HELD"`); no supplier-scoped payment
/// endpoint exists, so this table reports the supply status the API does
/// return and lets the supplier advance it.
class SupplierOrdersScreen extends ConsumerWidget {
  const SupplierOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(supplierWorkspaceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'B2B ORDERS',
          title: 'Vendor orders',
          subtitle: 'Manage wholesale orders and track their supply status.',
        ),
        switch (workspace) {
          AsyncLoading() => const LoadingState(),
          AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry: () => ref.invalidate(supplierWorkspaceProvider),
          ),
          AsyncData(:final value) =>
            _Orders(orders: value.orders, unavailable: value.ordersUnavailable),
          _ => const LoadingState(),
        },
      ],
    );
  }
}

class _Orders extends ConsumerWidget {
  const _Orders({required this.orders, required this.unavailable});

  final List<SupplierOrder> orders;
  final bool unavailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return DataCard(
        title: 'Vendor orders',
        child: EmptyState(
          message: unavailable
              // `GET /orders` is restricted to admins on the backend, so this
              // is a permission gap rather than genuinely zero orders. Saying
              // "no orders yet" here would be a lie the user cannot act on.
              ? 'Vendor orders are not available to supplier accounts yet. The '
                    'orders endpoint currently only responds to administrators, '
                    'so no order data can be shown here.'
              : 'No vendor orders yet. Orders placed by vendors appear here once '
                    'they are placed.',
        ),
      );
    }

    return DataCard(
      title: 'Vendor orders',
      subtitle: '${numFmt(orders.length)} order(s) in your workspace.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final order in orders) _OrderCard(order: order),
        ],
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final SupplierOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = _nextOrderStatus(order.status);
    final muted = context.mv.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.mv.surface,
        border: Border.all(color: context.mv.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.id.isEmpty ? 'Order' : order.id,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
              StatusChip(order.status),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${order.buyer} · ${order.quantity} × ${order.product}',
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${money(order.total)}  ·  ${DateFormat('d MMM yyyy').format(order.requestedAt)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              if (next != null)
                TextButton.icon(
                  onPressed:
                      () => ref
                          .read(supplierWorkspaceProvider.notifier)
                          .updateOrderStatus(order.id, next),
                  icon: const Icon(Icons.local_shipping_outlined, size: 16),
                  label: Text(_actionFor(next)),
                  style: TextButton.styleFrom(
                    foregroundColor: context.mv.accentDeep,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The next step in the supply flow, or `null` once the order is terminal.
String? _nextOrderStatus(String status) => switch (status.toLowerCase()) {
  'pending' => 'Confirmed',
  'confirmed' => 'Ready to ship',
  'ready to ship' => 'Shipped',
  'shipped' => 'Completed',
  _ => null,
};

String _actionFor(String next) => switch (next) {
  'Confirmed' => 'Confirm order',
  'Ready to ship' => 'Mark ready',
  'Shipped' => 'Mark shipped',
  _ => 'Complete order',
};
