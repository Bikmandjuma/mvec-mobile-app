import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  static final List<Map<String, dynamic>> _vendorRows = [
    {'vendor': 'TechHub Kigali', 'orders': 312, 'sales': money(14580000), 'rating': '★ 4.8', 'status': 'Active'},
    {'vendor': 'Garment R Us', 'orders': 248, 'sales': money(9420000), 'rating': '★ 4.6', 'status': 'Active'},
    {'vendor': 'Farm Fresh Ltd', 'orders': 195, 'sales': money(5310000), 'rating': '★ 4.9', 'status': 'Active'},
    {'vendor': 'Miko Electronics', 'orders': 176, 'sales': money(12760000), 'rating': '★ 4.5', 'status': 'Active'},
    {'vendor': 'Kivu Coffee Co', 'orders': 142, 'sales': money(3980000), 'rating': '★ 4.7', 'status': 'Active'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(reportSummaryProvider('30d'));
    final revenueAsync = ref.watch(reportRevenueProvider('30d'));

    final s = summaryAsync.when(
      data: (v) => v,
      error: (_, __) => ReportSummary(grossSales: 0, orders: 0, customers: 0, paymentVolume: 0, refunds: 0),
      loading: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(eyebrow: 'SUPER ADMIN · ANALYTICS', title: 'Marketplace analytics'),
        _metricGrid(
          [
            MetricCard(label: 'GMV', value: s == null ? '—' : money(s.grossSales), icon: 'wallet'),
            MetricCard(label: 'Orders', value: s == null ? '—' : numFmt(s.orders), icon: 'cart'),
            MetricCard(label: 'Completed', value: s == null ? '—' : money(s.paymentVolume), icon: 'check'),
            MetricCard(
              label: 'Refund rate',
              value: s == null ? '—' : '${_pct(s.refunds, s.grossSales).toStringAsFixed(1)}%',
              delta: s == null ? null : '% of sales',
              icon: 'bell',
            ),
            MetricCard(label: 'Active users', value: s == null ? '—' : numFmt(s.customers), icon: 'users'),
            MetricCard(label: 'Average order', value: s == null ? '—' : money(_avg(s.grossSales, s.orders)), icon: 'chart'),
          ],
        ),
        const SizedBox(height: 16),
        DataCard(
          title: 'Vendor performance',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              revenueAsync.when(
                loading: () => const LoadingState(),
                error: (_, __) => const EmptyState(message: 'Revenue data unavailable'),
                data: (series) => FakeBarChart(values: series.series, labels: series.labels),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SmartTable(
                  pageSize: 5,
                  csvFileName: 'vendor_performance',
                  columns: const [
                    MvColumn('vendor', 'Vendor', bold: true),
                    MvColumn('orders', 'Orders', align: TextAlign.right),
                    MvColumn('sales', 'Sales', align: TextAlign.right),
                    MvColumn('rating', 'Rating', align: TextAlign.right),
                    MvColumn('status', 'Status'),
                  ],
                  rows: _vendorRows,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 1100 ? 3 : 2;
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          if (i > 0) rows.add(const SizedBox(height: 14));
          rows.add(
            Row(
              children: [
                for (var j = 0; j < cols; j++) ...[
                  if (j > 0) const SizedBox(width: 14),
                  Expanded(child: i + j < children.length ? children[i + j] : const SizedBox()),
                ],
              ],
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}

double _pct(num? part, num? total) {
  final t = total ?? 0;
  if (t == 0) return 0;
  return ((part ?? 0) / t) * 100;
}

num _avg(num? total, num? count) {
  final c = count ?? 0;
  if (c == 0) return 0;
  return (total ?? 0) / c;
}
