import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../features/supplier/data/supplier_workspace.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';

/// Stock levels across the wholesale catalogue, mirroring the web app's
/// `SupplierInventory`: the "INVENTORY" page head, a metric grid and the
/// product table.
///
/// The web's "Reserved" column is a hard-coded array (`[12,8,16,…]`) that no
/// endpoint returns, so this page reports real stock and restock signals
/// instead of inventing reservations.
class SupplierInventoryScreen extends ConsumerWidget {
  const SupplierInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(supplierWorkspaceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'INVENTORY',
          title: 'Inventory',
          subtitle: 'Monitor wholesale stock levels and restocking needs.',
        ),
        switch (workspace) {
          AsyncLoading() => const LoadingState(),
          AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry: () => ref.invalidate(supplierWorkspaceProvider),
          ),
          AsyncData(:final value) => _Inventory(data: value),
          _ => const LoadingState(),
        },
      ],
    );
  }
}

class _Inventory extends StatelessWidget {
  const _Inventory({required this.data});

  final SupplierWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final metrics = data.metrics;
    final products =
        data.products.where((p) => !p.isArchived).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _grid([
          MetricCard(
            label: 'Total stock units',
            value: numFmt(metrics.totalUnitsInStock),
            delta: 'Across ${metrics.totalProducts} products',
            icon: 'box',
          ),
          MetricCard(
            label: 'Low stock',
            value: numFmt(metrics.lowStockProducts),
            delta: 'Needs attention',
            icon: 'grid',
          ),
          MetricCard(
            label: 'Out of stock',
            value: numFmt(metrics.outOfStockProducts),
            delta: 'Restock required',
            icon: 'cart',
          ),
        ]),
        const SizedBox(height: 16),
        DataCard(
          title: 'Stock levels',
          subtitle: 'Availability and minimum order quantity per product.',
          child:
              products.isEmpty
                  ? const EmptyState(message: 'No products in your catalogue yet')
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final product in products)
                        _StockRow(product: product),
                    ],
                  ),
        ),
      ],
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.product});

  final SupplierProduct product;

  @override
  Widget build(BuildContext context) {
    final muted = context.mv.textMuted;
    final low = product.isLowStock || product.isOutOfStock;

    return InkWell(
      onTap: () => context.go('/supplier/products'),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _Thumb(url: product.imageUrl),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.category.isEmpty
                        ? 'MOQ ${product.minimumOrderQuantity}'
                        : '${product.category} · MOQ ${product.minimumOrderQuantity}',
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
                  '${numFmt(product.stock)} avail.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: low ? MvColors.warningText : context.mv.text,
                  ),
                ),
                const SizedBox(height: 3),
                StatusChip(product.stockStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Product thumbnail with the brand-tinted placeholder the web shows for
/// image-less products.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.mv.surfaceMuted,
        borderRadius: BorderRadius.circular(9),
        image:
            url.isEmpty
                ? null
                : DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child:
          url.isEmpty
              ? MvIcon('box', size: 18, color: context.mv.accentDeep)
              : null,
    );
  }
}

/// Metric grid: three across on a wide viewport, otherwise two.
Widget _grid(List<Widget> children) {
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
