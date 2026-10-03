import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/api_config.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/vendor.dart';
import '../../models/vendor_product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';
import '../../widgets/smart_table.dart';
import '../../features/vendor/vendor_dependencies.dart';
import '../../features/vendor/widgets/vendor_dashboard_widgets.dart';
import 'vendor_status_banner.dart';

/// Vendor dashboard home.
///
/// Three bands, in the admin console's visual order: the verification header,
/// the summary cards, and the unified activity history with its filters.
class VendorOverviewScreen extends ConsumerStatefulWidget {
  const VendorOverviewScreen({super.key});

  @override
  ConsumerState<VendorOverviewScreen> createState() =>
      _VendorOverviewScreenState();
}

class _VendorOverviewScreenState extends ConsumerState<VendorOverviewScreen> {
  VendorActivityQuery _query = const VendorActivityQuery();

  void _setQuery(VendorActivityQuery next) => setState(() => _query = next);

  @override
  Widget build(BuildContext context) {
    if (kDemoMode) return _demoOverview();

    final user = ref.watch(currentUserProvider);
    final storeAsync = ref.watch(myStoreProvider);
    final statsAsync = ref.watch(vendorStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'VENDOR PORTAL',
          title:
              '${greeting(DateTime.now())}, ${user?.companyName ?? user?.display ?? 'Vendor'}',
          subtitle:
              'Track today’s trading, keep your catalogue healthy and stay verified.',
          actions: [
            GradientButton(
              label: 'Add product',
              icon: 'plus',
              onPressed: () => context.go('/vendor/products'),
            ),
          ],
        ),
        switch (storeAsync) {
          AsyncLoading() => const SizedBox(height: 140, child: LoadingState()),
          AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry: () => ref.invalidate(myStoreProvider),
          ),
          AsyncData(:final value) => VendorStatusBanner(
            store: value,
            onEditProfile: () => context.go('/vendor/profile'),
          ),
          _ => const SizedBox(height: 140, child: LoadingState()),
        },
        const SizedBox(height: 16),
        _metrics(statsAsync),
        const SizedBox(height: 18),
        _historySection(),
      ],
    );
  }

  Widget _demoOverview() {
    final user = ref.watch(currentUserProvider);
    final financeAsync = ref.watch(vendorFinanceSummaryProvider);
    final ordersAsync = ref.watch(vendorOrdersPageProvider(null));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'VENDOR PORTAL',
          title:
              '${greeting(DateTime.now())}, ${user?.companyName ?? 'Vendor'}',
          subtitle: 'Demo dashboard · your local data is ready to explore.',
          actions: [
            FilledButton.icon(
              onPressed: () => context.go('/vendor/orders'),
              icon: const Icon(Icons.receipt_long, size: 17),
              label: const Text('Orders'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/vendor/sales'),
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 17),
              label: const Text('Sales'),
            ),
          ],
        ),
        switch (financeAsync) {
          AsyncLoading() => const SizedBox(height: 150, child: LoadingState()),
          AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry: () => ref.invalidate(vendorFinanceSummaryProvider),
          ),
          AsyncData(:final value) => LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 720 ? 4 : 2;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: width,
                    child: VendorFinanceMetric(
                      label: 'Revenue',
                      amount: value.grossRevenue,
                      icon: 'chart',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: VendorFinanceMetric(
                      label: 'Net earnings',
                      amount: value.netEarnings,
                      icon: 'wallet',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: VendorFinanceMetric(
                      label: 'Escrow',
                      amount: value.escrowHeld,
                      icon: 'shield',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: VendorFinanceMetric(
                      label: 'Available',
                      amount: value.availablePayout,
                      icon: 'arrow',
                      emphasis: true,
                    ),
                  ),
                ],
              );
            },
          ),
          _ => const SizedBox(height: 150, child: LoadingState()),
        },
        const SizedBox(height: 16),
        DataCard(
          title: 'Recent orders',
          subtitle: 'Orders and status updates from your local demo dataset.',
          trailing: TextButton(
            onPressed: () => context.go('/vendor/orders'),
            child: const Text('View all'),
          ),
          child: switch (ordersAsync) {
            AsyncLoading() => const SizedBox(
              height: 120,
              child: LoadingState(),
            ),
            AsyncError(:final error) => ErrorState(
              message: friendlyError(error),
              onRetry: () => ref.invalidate(vendorOrdersPageProvider(null)),
            ),
            AsyncData(:final value) => Column(
              children: [
                for (final order in value.orders.take(3))
                  VendorOrderCard(
                    order: order,
                    onTap: () => context.go('/vendor/orders'),
                  ),
              ],
            ),
            _ => const SizedBox(height: 120, child: LoadingState()),
          },
        ),
      ],
    );
  }

  // ─── SUMMARY CARDS ──────────────────────────────────────────────────────
  Widget _metrics(AsyncValue<VendorStats> statsAsync) {
    final stats = statsAsync.valueOrNull;
    final dailySales = stats?.dailySales;
    final delta = stats?.salesDelta;
    final rating = stats?.rating;
    final ratingCount = stats?.ratingCount ?? 0;

    final cards = <Widget>[
      MetricCard(
        label: 'Daily sales',
        value: dailySales == null ? '—' : money(dailySales),
        delta:
            (delta ?? 0) != 0
                ? '${(delta ?? 0) > 0 ? '▲' : '▼'} ${numFmt((delta ?? 0).abs())} today'
                : null,
        deltaColor: (delta ?? 0) < 0 ? MvColors.errorText : null,
        icon: 'wallet',
      ),
      MetricCard(
        label: 'Active orders',
        value: stats?.activeOrders == null ? '—' : numFmt(stats!.activeOrders),
        icon: 'cart',
      ),
      MetricCard(
        label: 'Low stock alerts',
        value: stats?.lowStock == null ? '—' : numFmt(stats!.lowStock),
        icon: 'bell',
        onTap: () => _openLowStock(context),
      ),
      MetricCard(
        label: 'Store rating',
        value: rating == null ? '—' : '★ ${rating.toStringAsFixed(1)}',
        delta:
            ratingCount > 0
                ? '$ratingCount review${ratingCount == 1 ? '' : 's'}'
                : null,
        icon: 'heart',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 860) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < cards.length; i += 2) {
          if (i > 0) rows.add(const SizedBox(height: 14));
          rows.add(
            Row(
              children: [
                Expanded(child: cards[i]),
                const SizedBox(width: 14),
                Expanded(
                  child: i + 1 < cards.length ? cards[i + 1] : const SizedBox(),
                ),
              ],
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }

  /// Low-stock listings, computed from the vendor's own catalogue.
  void _openLowStock(BuildContext context) {
    showMvDetailModal(
      context,
      title: 'LOW STOCK ALERTS',
      children: [
        Consumer(
          builder: (ctx, ref, _) {
            final async = ref.watch(
              vendorProductsProvider(
                const VendorProductQuery(lowStockOnly: true),
              ),
            );
            return switch (async) {
              AsyncLoading() => const SizedBox(
                height: 120,
                child: LoadingState(),
              ),
              AsyncError(:final error) => ErrorState(
                message: friendlyError(error),
                onRetry: () => ref.invalidate(vendorProductsProvider),
              ),
              AsyncData(:final value) =>
                value.items.isEmpty
                    ? const EmptyState(
                      message: 'Every product is comfortably stocked',
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final p in value.items) _lowStockRow(ctx, p),
                      ],
                    ),
              _ => const SizedBox(height: 120, child: LoadingState()),
            };
          },
        ),
      ],
    );
  }

  Widget _lowStockRow(BuildContext context, VendorProduct p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reorder at ${p.lowStockThreshold ?? 5} units',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusChip(
            p.isOutOfStock ? VendorProductStatus.outOfStock : 'LOW_STOCK',
          ),
        ],
      ),
    );
  }

  // ─── FILTERABLE HISTORY ─────────────────────────────────────────────────
  Widget _historySection() {
    final historyAsync = ref.watch(vendorActivityProvider(_query));
    return DataCard(
      title: 'Activity history',
      subtitle: 'Orders, payouts and inventory adjustments in one timeline.',
      trailing: TextButton(
        onPressed:
            _query.isFiltered
                ? () => _setQuery(const VendorActivityQuery())
                : null,
        child: Text(_query.isFiltered ? 'Clear filters' : 'No filters'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _historyFilters(),
          const SizedBox(height: 14),
          switch (historyAsync) {
            AsyncLoading() => const SizedBox(
              height: 160,
              child: LoadingState(),
            ),
            AsyncError(:final error) => ErrorState(
              message: friendlyError(error),
              onRetry: () => ref.invalidate(vendorActivityProvider(_query)),
            ),
            AsyncData(:final value) => _historyTable(value),
            _ => const SizedBox(height: 160, child: LoadingState()),
          },
        ],
      ),
    );
  }

  /// Date range (start / end) + activity type controls.
  Widget _historyFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DateFilter(
          label: 'Start date',
          value: _query.from,
          onPick: (d) => _setQuery(_query.copyWith(from: d, page: 1)),
          onClear:
              _query.from == null
                  ? null
                  : () => _setQuery(_query.copyWith(clearFrom: true, page: 1)),
          isDark: isDark,
        ),
        _DateFilter(
          label: 'End date',
          value: _query.to,
          onPick: (d) => _setQuery(_query.copyWith(to: d, page: 1)),
          onClear:
              _query.to == null
                  ? null
                  : () => _setQuery(_query.copyWith(clearTo: true, page: 1)),
          isDark: isDark,
        ),
        SizedBox(
          height: 40,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _query.type,
              hint: const Text(
                'All activity',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: VendorActivityQuery.allTypes,
                  child: Text('All activity', style: TextStyle(fontSize: 12.5)),
                ),
                for (final t in VendorActivity.buckets)
                  DropdownMenuItem(
                    value: t,
                    child: Text(
                      titleCase(t),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
              ],
              onChanged: (v) => _setQuery(_query.copyWith(type: v, page: 1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _historyTable(Paged<VendorActivity> paged) {
    final rows =
        paged.items
            .map(
              (a) => {
                'date': shortDateTime(a.date),
                'type': StatusChip(
                  a.bucket,
                  overrideColor: _bucketColor(a.bucket),
                ),
                'event': a.display,
                'reference': a.reference ?? a.product ?? '—',
                'amount': a.amount == null ? '—' : money(a.amount),
                'status': a.status == null ? null : StatusChip(a.status),
                '_record': a,
              },
            )
            .toList();

    return SmartTable(
      columns: const [
        MvColumn('date', 'Date'),
        MvColumn('type', 'Type'),
        MvColumn('event', 'Activity', bold: true),
        MvColumn('reference', 'Reference'),
        MvColumn('amount', 'Amount', align: TextAlign.right),
        MvColumn('status', 'Status'),
      ],
      rows: rows,
      actionsLabel: '',
      showSearch: false,
      pageSize: 8,
      serverPage: _query.page,
      serverTotalPages: paged.pages ?? 1,
      onServerPageChanged: (page) => _setQuery(_query.copyWith(page: page)),
      csvFileName: 'vendor-activity',
      emptyMessage:
          _query.isFiltered
              ? 'No activity matches these filters'
              : 'No activity recorded yet',
      rowActions:
          (row) => TableActionBtn(
            icon: 'eye',
            tooltip: 'Details',
            onPressed:
                () => _showActivity(context, row['_record'] as VendorActivity),
          ),
    );
  }

  void _showActivity(BuildContext context, VendorActivity a) {
    showMvDetailModal(
      context,
      title: 'ACTIVITY DETAIL',
      children: [
        KeyValueGrid(
          entries: [
            MapEntry('Type', titleCase(a.bucket)),
            MapEntry('Activity', a.display),
            MapEntry('Date', shortDateTime(a.date)),
            if (a.reference != null) MapEntry('Reference', a.reference!),
            if (a.product != null) MapEntry('Product', a.product!),
            if (a.amount != null) MapEntry('Amount', money(a.amount)),
            if (a.status != null) MapEntry('Status', titleCase(a.status!)),
            if (a.description != null && a.description!.trim().isNotEmpty)
              MapEntry('Details', a.description!),
          ],
        ),
      ],
    );
  }

  static Color _bucketColor(String bucket) => switch (bucket) {
    'PAYOUTS' => MvColors.successText,
    'INVENTORY' => MvColors.neutralText,
    _ => MvColors.primaryDeep,
  };
}

/// Start / end date control for the history filter bar.
class _DateFilter extends StatelessWidget {
  const _DateFilter({
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
    this.isDark = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final VoidCallback? onClear;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? MvColors.darkMuted : MvColors.ink;
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 3),
          lastDate: now,
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? MvColors.darkSurface2 : MvColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? MvColors.darkBorder : const Color(0xFFE0E5E8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MvIcon('chart', size: 14, color: MvColors.primaryDeep),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                Text(
                  value == null ? 'Any' : formatDate(value!),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 13, color: MvColors.muted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
