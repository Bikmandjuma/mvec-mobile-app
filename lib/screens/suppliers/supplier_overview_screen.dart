import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../features/supplier/data/supplier_workspace.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';

/// Supplier dashboard, mirroring the web app's `SupplierOverview`
/// (`src/pages/SupplierDashboard.jsx`): the "SUPPLIER PLATFORM" page head, the
/// four-card metric grid, and the MVEC protected-settlement explainer.
///
/// Every figure is derived from real data via [SupplierWorkspaceData.metrics];
/// the web fills these cards with hard-coded mock numbers, which would be
/// misleading here.
class SupplierOverviewScreen extends ConsumerWidget {
  const SupplierOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(supplierWorkspaceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'SUPPLIER PLATFORM',
          title: 'Supplier dashboard',
          subtitle: 'Supply verified MVEC vendors with wholesale products.',
        ),
        switch (workspace) {
          AsyncLoading() => const LoadingState(),
          AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry: () => ref.invalidate(supplierWorkspaceProvider),
          ),
          AsyncData(:final value) => _Overview(data: value),
          _ => const LoadingState(),
        },
      ],
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.data});

  final SupplierWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final metrics = data.metrics;
    final orders = data.orders;
    final now = DateTime.now();
    final thisMonth = orders
        .where(
          (o) =>
              o.requestedAt.year == now.year && o.requestedAt.month == now.month,
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _metricGrid([
          MetricCard(
            label: 'Wholesale products',
            value: numFmt(metrics.activeProducts),
            delta: 'Active catalog',
            icon: 'box',
          ),
          MetricCard(
            label: 'Vendor orders',
            value: numFmt(thisMonth),
            delta: 'This month',
            icon: 'cart',
          ),
          MetricCard(
            label: 'Sales',
            value: money(metrics.salesTotal),
            delta: 'Completed orders',
            icon: 'chart',
          ),
          MetricCard(
            label: 'Protected funds',
            value: money(metrics.protectedFunds),
            delta: 'Held by MVEC pending delivery',
            icon: 'wallet',
          ),
        ]),
        const SizedBox(height: 16),
        const InfoBox(
          'When a vendor pays a supplier through the MVEC workflow, the amount '
          'is recorded as HELD. Fulfill the supply, confirm receipt/delivery, '
          'and MVEC releases the protected amount according to the marketplace '
          'rules.',
        ),
        const SizedBox(height: 16),
        if (orders.isEmpty)
          DataCard(
            title: 'Recent vendor orders',
            child: EmptyState(
              message:
                  'No vendor orders yet. Orders placed by vendors appear here.',
            ),
          )
        else
          DataCard(
            title: 'Recent vendor orders',
            subtitle: 'The five most recent orders in your workspace.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final order in orders.take(5)) _OrderRow(order: order),
              ],
            ),
          ),
      ],
    );
  }
}

/// A single order line: reference, product, buyer and status.
class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final SupplierOrder order;

  @override
  Widget build(BuildContext context) {
    final muted = context.mv.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.mv.surfaceMuted,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: MvIcon('cart', size: 16, color: context.mv.accentDeep),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.product,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.id} · ${order.buyer} · ${order.quantity} unit(s)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(order.total),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              StatusChip(order.status),
            ],
          ),
        ],
      ),
    );
  }
}

/// Responsive metric grid: four across on a wide viewport, two on a phone.
Widget _metricGrid(List<Widget> children) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final cols = constraints.maxWidth >= 1100 ? 4 : 2;
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += cols) {
        if (i > 0) rows.add(const SizedBox(height: 14));
        rows.add(
          Row(
            children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) const SizedBox(width: 14),
                Expanded(
                  child: i + j < children.length ? children[i + j] : const SizedBox(),
                ),
              ],
            ],
          ),
        );
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    },
  );
}
