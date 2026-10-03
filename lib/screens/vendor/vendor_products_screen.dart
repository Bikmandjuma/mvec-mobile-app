import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/vendor_product.dart';
import '../../providers/vendor_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';
import '../../widgets/smart_table.dart';
import 'vendor_product_form.dart';

/// Vendor catalogue management: searchable, paginated product list with stock
/// health indicators and the full CRUD + availability action set.
class VendorProductsScreen extends ConsumerStatefulWidget {
  const VendorProductsScreen({super.key});

  @override
  ConsumerState<VendorProductsScreen> createState() => _VendorProductsScreenState();
}

class _VendorProductsScreenState extends ConsumerState<VendorProductsScreen> {
  VendorProductQuery _query = const VendorProductQuery();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The shell's top-bar search may have left a term for us before this
    // screen mounted.
    final incoming = ref.read(vendorSearchSeedProvider);
    if (incoming.isNotEmpty) {
      _search.text = incoming;
      _query = _query.copyWith(search: incoming);
    }
  }

  /// Picks up a term handed over by the shell while the page is already open.
  void _adoptSeed(String term) {
    if (term.isEmpty) return;
    _search.text = term;
    setState(() => _query = _query.copyWith(search: term, page: 1));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setQuery(VendorProductQuery next) => setState(() => _query = next);

  /// Server-side search: applied on submit so typing does not fire a request
  /// per keystroke.
  void _applySearch(String term) {
    _setQuery(_query.copyWith(search: term, page: 1));
  }

  void _clearFilters() {
    _search.clear();
    ref.read(vendorSearchSeedProvider.notifier).clear();
    setState(() => _query = const VendorProductQuery());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(vendorSearchSeedProvider, (_, next) => _adoptSeed(next));

    final productsAsync = ref.watch(vendorProductsProvider(_query));
    final mutation = ref.watch(vendorProductControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'VENDOR PORTAL',
          title: 'Products',
          subtitle: 'Manage your listings, pricing, stock and availability.',
          actions: [
            GradientButton(
              label: 'Add product',
              icon: 'plus',
              onPressed: mutation.busy ? null : () => _openForm(context),
            ),
          ],
        ),
        const InfoBox('Products you mark ACTIVE appear in the marketplace. Use DRAFT while you finish a listing and INACTIVE to hide a finished one.'),
        const SizedBox(height: 16),
        _toolbar(),
        const SizedBox(height: 14),
        switch (productsAsync) {
          AsyncLoading() => const SizedBox(height: 200, child: LoadingState()),
          AsyncError(:final error) => ErrorState(
              message: friendlyError(error),
              onRetry: () => ref.invalidate(vendorProductsProvider(_query)),
            ),
          AsyncData(:final value) => _table(value),
          _ => const SizedBox(height: 200, child: LoadingState()),
        },
      ],
    );
  }

  // ─── FILTERS ────────────────────────────────────────────────────────────
  Widget _toolbar() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 250,
          height: 40,
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: _applySearch,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by name or SKU…',
              prefixIcon: const Padding(padding: EdgeInsets.all(11), child: MvIcon('search', size: 16)),
              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: _query.search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _search.clear();
                        ref.read(vendorSearchSeedProvider.notifier).clear();
                        _applySearch('');
                      },
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _query.status,
              hint: const Text('All statuses', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              items: [
                const DropdownMenuItem<String>(value: VendorProductQuery.allStatuses, child: Text('All statuses', style: TextStyle(fontSize: 12.5))),
                for (final s in VendorProductStatus.all)
                  DropdownMenuItem(value: s, child: Text(titleCase(s), style: const TextStyle(fontSize: 12.5))),
              ],
              onChanged: (v) => _setQuery(_query.copyWith(status: v, page: 1)),
            ),
          ),
        ),
        FilterChip(
          label: const Text('Low stock only'),
          selected: _query.lowStockOnly,
          showCheckmark: false,
          onSelected: (v) => _setQuery(_query.copyWith(lowStockOnly: v, page: 1)),
        ),
        if (_query.isFiltered)
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.close, size: 15),
            label: const Text('Clear'),
          ),
      ],
    );
  }

  // ─── TABLE ──────────────────────────────────────────────────────────────
  Widget _table(Paged<VendorProduct> paged) {
    final rows = paged.items
        .map(
          (p) => {
            'product': p.display,
            'sku': p.sku ?? '—',
            'category': p.category ?? '—',
            'price': p.hasDiscount
                ? '${money(p.effectivePrice)}  (${p.discountPercent}% off)'
                : money(p.effectivePrice),
            'stock': p.stockLabel,
            'status': StatusChip(p.availability),
            '_product': p,
          },
        )
        .toList();

    return SmartTable(
      columns: const [
        MvColumn('product', 'Product', bold: true),
        MvColumn('sku', 'SKU'),
        MvColumn('category', 'Category'),
        MvColumn('price', 'Price', align: TextAlign.right),
        MvColumn('stock', 'Stock', align: TextAlign.right),
        MvColumn('status', 'Status'),
      ],
      rows: rows,
      showSearch: false,
      pageSize: 10,
      serverPage: _query.page,
      serverTotalPages: paged.pages ?? 1,
      onServerPageChanged: (page) => _setQuery(_query.copyWith(page: page)),
      csvFileName: 'vendor-products',
      emptyMessage: _query.isFiltered ? 'No products match these filters' : 'No products yet — add your first listing',
      rowActions: (row) {
        final p = row['_product'] as VendorProduct;
        final live = p.availability == VendorProductStatus.active;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TableActionBtn(
              icon: 'eye',
              tooltip: 'View',
              onPressed: () => _showProduct(context, p),
            ),
            const SizedBox(width: 6),
            TableActionBtn(
              icon: 'edit',
              tooltip: 'Edit',
              onPressed: () => _openForm(context, product: p),
            ),
            const SizedBox(width: 6),
            TableActionBtn(
              icon: live ? 'logout' : 'check',
              tooltip: live ? 'Take offline' : 'Publish',
              onPressed: () => _toggleAvailability(p, live),
            ),
            const SizedBox(width: 6),
            TableActionBtn(
              icon: 'trash',
              danger: true,
              tooltip: 'Remove',
              onPressed: () => _remove(p),
            ),
          ],
        );
      },
    );
  }

  // ─── ACTIONS ────────────────────────────────────────────────────────────
  void _openForm(BuildContext context, {VendorProduct? product}) {
    showVendorProductForm(context, product: product);
  }

  void _showProduct(BuildContext context, VendorProduct p) {
    showMvDetailModal(
      context,
      title: 'PRODUCT DETAIL',
      children: [
        Row(
          children: [
            _Thumb(product: p),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.display, style: const TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  StatusChip(p.availability),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        KeyValueGrid(
          entries: [
            MapEntry('SKU', p.sku ?? '—'),
            MapEntry('Brand', p.brand ?? '—'),
            MapEntry('Category', p.category ?? '—'),
            MapEntry('Regular price', money(p.price)),
            if (p.discountPrice != null) MapEntry('Discount price', money(p.discountPrice)),
            MapEntry('Stock', p.stockLabel),
            MapEntry('Reorder at', '${p.lowStockThreshold ?? 5}'),
            if (p.variantList.isNotEmpty) MapEntry('Variants', p.variantList.map((v) => v.label).join(', ')),
            MapEntry('Created', shortDate(p.createdAt)),
          ],
        ),
        if (p.description != null && p.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('DESCRIPTION', style: context.mvEyebrow),
          const SizedBox(height: 6),
          Text(p.description!, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
        if (p.gallery.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('MEDIA', style: context.mvEyebrow),
          const SizedBox(height: 8),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: p.gallery.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _Thumb(product: p, url: p.gallery[i], size: 74),
            ),
          ),
        ],
      ],
      footer: GradientButton(label: 'Edit product', icon: 'edit', expanded: true, onPressed: () {
        Navigator.pop(context);
        _openForm(context, product: p);
      }),
    );
  }

  /// Publish / take a listing offline without opening the edit form.
  Future<void> _toggleAvailability(VendorProduct p, bool isLive) async {
    final next = isLive ? VendorProductStatus.inactive : VendorProductStatus.active;
    final ok = await ref
        .read(vendorProductControllerProvider.notifier)
        .setAvailability(p.id ?? '', next);
    if (!mounted) return;
    final state = ref.read(vendorProductControllerProvider);
    showMvSnack(
      context,
      ok ? (state.success ?? 'Availability updated') : (state.error ?? 'Could not update availability'),
      success: ok,
    );
  }

  /// Soft-delete: the listing is flagged removed, keeping its order history.
  Future<void> _remove(VendorProduct p) async {
    final confirmed = await _confirmRemove(context, p);
    if (confirmed != true || !mounted) return;
    final ok = await ref.read(vendorProductControllerProvider.notifier).removeProduct(p.id ?? '');
    if (!mounted) return;
    final state = ref.read(vendorProductControllerProvider);
    showMvSnack(
      context,
      ok ? (state.success ?? 'Product removed') : (state.error ?? 'Could not remove the product'),
      success: ok,
    );
  }

  Future<bool?> _confirmRemove(BuildContext context, VendorProduct p) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove product'),
        content: Text(
          'Remove "${p.display}" from your catalogue? Past orders keep the product, but the listing stops being visible to buyers.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: MvColors.dangerIcon),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.product, this.url, this.size = 56});
  final VendorProduct product;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final src = url ?? product.thumbnail;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: MvColors.metricIconBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: src == null || src.trim().isEmpty
          ? const Center(child: MvIcon('box', size: 18, color: MvColors.primaryDeep))
          : Image.network(
              src,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(child: MvIcon('box', size: 18, color: MvColors.primaryDeep)),
            ),
    );
  }
}
