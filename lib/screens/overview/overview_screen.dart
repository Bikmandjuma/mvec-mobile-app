import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';

/// Rebuild of the overview to match the new frontend `AdminDashboard`:
/// KPI metric grid, a "MVEC revenue today" card (Commission earned +
/// Products listed), platform activity, recent orders and category health.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(reportSummaryProvider('7d'));
    final ordersAsync = ref.watch(ordersProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);

    final summary = summaryAsync.when(
      data: (s) => s,
      error: (_, __) => ReportSummary(grossSales: 0, orders: 0, customers: 0, activeVendors: 0),
      loading: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN DASHBOARD',
          title: 'Good morning, Administrator 👋',
          subtitle: 'Monitor the entire MVEC marketplace from one control center.',
          actions: [
            IconButton(
              onPressed: () => context.push('/admin/notifications'),
              tooltip: 'Notifications',
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const MvIcon('bell', color: MvColors.ink),
                  Positioned(
                    top: -3,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      height: 16,
                      constraints: const BoxConstraints(minWidth: 16),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: MvColors.badgeRed, borderRadius: BorderRadius.all(Radius.circular(9))),
                      child: const Text('5', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            GradientButton(
              label: 'Create record',
              icon: 'plus',
              onPressed: () => _openCreateSheet(context),
            ),
          ],
        ),
        _metricRow(
          [
            MetricCard(label: 'Gross sales', value: summary == null ? '—' : money(summary.grossSales), icon: 'wallet'),
            MetricCard(label: 'Orders', value: summary == null ? '—' : money(summary.orders), icon: 'cart'),
            MetricCard(label: 'Customers', value: summary == null ? '—' : numFmt(summary.customers), icon: 'users'),
            MetricCard(label: 'Vendors', value: summary == null ? '—' : numFmt(summary.activeVendors), icon: 'shop'),
          ],
        ),
        const SizedBox(height: 16),
        _pair(
          _RevenueTodayCard(summary: summary, productsAsync: productsAsync),
          const DataCard(
            title: 'Platform activity',
            child: Column(
              children: [
                ActivityRow(label: 'Vendor approvals', value: '6 pending', status: 'WARNING'),
                ActivityRow(label: 'Product moderation', value: '14 pending', status: 'WARNING'),
                ActivityRow(label: 'Payment success', value: '96.8%', status: 'ACTIVE'),
                ActivityRow(label: 'Disputes', value: '3 open', status: 'WARNING'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _pair(
          _recentOrdersCard(context, ordersAsync),
          _categoryHealthCard(context, categoriesAsync),
        ),
      ],
    );
  }

  void _openCreateSheet(BuildContext context) {
    showMvDetailModal(
      context,
      title: 'Create record',
      children: [
        _quickTile(
          context,
          icon: 'box',
          label: 'Product',
          subtitle: 'Add a new product to the catalog',
          path: '/admin/products',
        ),
        const SizedBox(height: 10),
        _quickTile(
          context,
          icon: 'tag',
          label: 'Category',
          subtitle: 'Organise products into a category',
          path: '/admin/categories',
        ),
        const SizedBox(height: 10),
        _quickTile(
          context,
          icon: 'cart',
          label: 'Order',
          subtitle: 'Review and manage marketplace orders',
          path: '/admin/orders',
        ),
      ],
    );
  }

  Widget _quickTile(
    BuildContext context, {
    required String icon,
    required String label,
    required String subtitle,
    required String path,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.pop(context);
          context.push(path);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: MvColors.metricIconBg,
                  borderRadius: BorderRadius.all(Radius.circular(9)),
                ),
                child: Center(child: MvIcon(icon, size: 18, color: MvColors.primaryDeep)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
              const MvIcon('arrow', size: 16, color: MvColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 860) {
          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: children[i]),
              ],
            ],
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += 2) {
          if (i > 0) rows.add(const SizedBox(height: 14));
          rows.add(
            Row(
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: 14),
                Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
              ],
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }

  Widget _pair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 980) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 16),
              Expanded(child: second),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 16), second],
        );
      },
    );
  }

  Widget _recentOrdersCard(BuildContext context, AsyncValue<List<OrderRecord>> ordersAsync) {
    return DataCard(
      title: 'Recent orders',
      trailing: TextButton(
        onPressed: () => context.push('/admin/orders'),
        child: const Text('View all'),
      ),
      child: ordersAsync.when(
        loading: () => const LoadingState(),
        error: (_, __) => const EmptyState(message: 'Orders could not be loaded'),
        data: (orders) {
          if (orders.isEmpty) return const EmptyState(message: 'No orders yet');
          final top = orders.take(6).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < top.length; i++) ...[
                _orderRow(context, top[i]),
                if (i < top.length - 1) const Divider(height: 1),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/admin/orders'),
                  child: const Text('View all'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orderRow(BuildContext context, OrderRecord order) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.display, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${order.buyer ?? '—'} · ${order.vendor ?? '—'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              money(order.total),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          StatusChip(order.paymentStatus),
        ],
      ),
    );
  }

  Widget _categoryHealthCard(BuildContext context, AsyncValue<List<CategoryRecord>> categoriesAsync) {
    return DataCard(
      title: 'Category health',
      trailing: TextButton(
        onPressed: () => context.push('/admin/categories'),
        child: const Text('Manage'),
      ),
      child: categoriesAsync.when(
        loading: () => const LoadingState(),
        error: (_, __) => const EmptyState(message: 'Categories could not be loaded'),
        data: (categories) {
          if (categories.isEmpty) return const EmptyState(message: 'No categories yet');
          final maxProducts = categories.fold<int>(0, (m, c) {
            final p = c.products ?? 0;
            return p > m ? p : m;
          });
          final cap = maxProducts == 0 ? 1 : maxProducts;
          return Column(
            children: [
              for (final c in categories)
                ProgressRow(
                  label: c.name ?? 'Untitled',
                  percent: 100 * (c.products ?? 0) / cap,
                  count: '${c.products ?? 0}',
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Mirrors the new frontend "MVEC revenue today" card: commission earned +
/// products listed headline metrics. No fake bar chart.
class _RevenueTodayCard extends StatelessWidget {
  const _RevenueTodayCard({this.summary, this.productsAsync});

  final ReportSummary? summary;
  final AsyncValue<List<ProductRecord>>? productsAsync;

  @override
  Widget build(BuildContext context) {
    final count = productsAsync?.when(
          data: (p) => '${p.length}',
          error: (_, __) => '—',
          loading: () => '…',
        ) ??
        '—';
    final commission = summary == null ? '—' : money(summary!.commission);
    return DataCard(
      title: 'MVEC revenue today',
      child: Row(
        children: [
          Expanded(
            child: _innerMetric(context, label: 'Commission earned', value: commission, icon: 'wallet'),
          ),
          Expanded(
            child: _innerMetric(context, label: 'Products listed', value: count, icon: 'box'),
          ),
        ],
      ),
    );
  }

  Widget _innerMetric(BuildContext context, {required String label, required String value, required String icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            gradient: MvColors.gradient,
            borderRadius: BorderRadius.all(Radius.circular(9)),
          ),
          alignment: Alignment.center,
          child: MvIcon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(value, style: GoogleFontsManrope.metricValue),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
      ],
    );
  }
}