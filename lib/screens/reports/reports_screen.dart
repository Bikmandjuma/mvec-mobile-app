import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const _ReportsView();
}

class _ReportsView extends ConsumerStatefulWidget {
  const _ReportsView();

  @override
  ConsumerState<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<_ReportsView> {
  int _days = 30;

  String get _range {
    if (_days == 90) return '3m';
    if (_days == 365) return '1y';
    return '30d';
  }

  String get _rangeLabel {
    if (_days == 90) return 'Last 3 months';
    if (_days == 365) return 'Last 1 year';
    return 'Last 30 days';
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(reportSummaryProvider(_range));
    final categoriesAsync = ref.watch(categoriesProvider);

    final s = summaryAsync.when(
      data: (v) => v,
      error: (_, __) => ReportSummary(grossSales: 0, orders: 0, activeVendors: 0, commission: 0, refunds: 0),
      loading: () => null,
    );

    final rows = <Map<String, dynamic>>[
      {'report': 'Marketplace revenue', 'range': _rangeLabel, 'summary': s == null ? '—' : money(s.grossSales)},
      {
        'report': 'Vendor sales',
        'range': _rangeLabel,
        'summary': s == null ? '—' : '${_pct((s.grossSales ?? 0) - (s.commission ?? 0), s.grossSales).toStringAsFixed(1)}%',
      },
      {'report': 'Transactions', 'range': _rangeLabel, 'summary': s == null ? '—' : numFmt(s.orders)},
      {
        'report': 'Refunds',
        'range': _rangeLabel,
        'summary': s == null ? '—' : '${_pct(s.refunds, s.grossSales).toStringAsFixed(1)}%',
      },
      {'report': 'Platform commission', 'range': _rangeLabel, 'summary': s == null ? '—' : money(s.commission)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          eyebrow: 'ADMIN CONTROL',
          title: 'Reports',
          actions: [
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _days,
                isDense: true,
                items: const [
                  DropdownMenuItem<int>(
                    value: 30,
                    child: Text('30 Days', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                  DropdownMenuItem<int>(
                    value: 90,
                    child: Text('3 Months', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                  DropdownMenuItem<int>(
                    value: 365,
                    child: Text('1 Year', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ],
                onChanged: (v) => setState(() => _days = v ?? 30),
              ),
            ),
          ],
        ),
        _metricRow(
          [
            MetricCard(label: 'Revenue', value: s == null ? '—' : money(s.grossSales), icon: 'wallet'),
            MetricCard(label: 'Orders', value: s == null ? '—' : numFmt(s.orders), icon: 'cart'),
            MetricCard(label: 'Vendors', value: s == null ? '—' : numFmt(s.activeVendors), icon: 'shop'),
            MetricCard(
              label: 'Commission',
              value: s == null ? '—' : '${_pct(s.commission, s.grossSales).toStringAsFixed(1)}% of sales',
              icon: 'chart',
            ),
          ],
        ),
        const SizedBox(height: 16),
        DataCard(
          title: 'Platform reports',
          child: SizedBox(
            width: double.infinity,
            child: SmartTable(
              pageSize: 6,
              csvFileName: 'platform_reports',
              columns: const [
                MvColumn('report', 'Report', bold: true),
                MvColumn('range', 'Range'),
                MvColumn('summary', 'Summary', align: TextAlign.right),
              ],
              rows: rows,
            ),
          ),
        ),
        const SizedBox(height: 16),
        DataCard(
          title: 'Top categories',
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
        ),
      ],
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
}

double _pct(num? part, num? total) {
  final t = total ?? 0;
  if (t == 0) return 0;
  return ((part ?? 0) / t) * 100;
}
