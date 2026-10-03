import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../features/supplier/data/supplier_workspace.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

/// Inventory management for a supplier: list, filter, add, edit and remove
/// the wholesale products they supply.
///
/// `GET /suppliers/me/products` returns the whole catalogue unpaginated, so the
/// table paginates client-side.
class SupplierProductsScreen extends ConsumerWidget {
  const SupplierProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(supplierWorkspaceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPPLIER PORTAL',
          title: 'Wholesale products',
          subtitle: 'Manage products that vendors can buy in bulk.',
          actions: [
            GradientButton(
              label: 'Add wholesale product',
              icon: 'plus',
              onPressed: () => _openForm(context),
            ),
          ],
        ),
        const InfoBox('Products stay hidden from buyers until your business is verified.'),
        const SizedBox(height: 18),
        switch (workspace) {
          AsyncLoading() => const LoadingState(),
          AsyncError(:final error) => ErrorState(
              message: friendlyError(error),
              onRetry: () => ref.invalidate(supplierWorkspaceProvider),
            ),
          AsyncData(:final value) => _table(context, ref, value.products),
          _ => const LoadingState(),
        },
      ],
    );
  }

  Widget _table(BuildContext context, WidgetRef ref, List<SupplierProduct> products) {
    final rows = products
        .map(
          (p) => {
            '_product': p,
            'product': p.name,
            'category': p.category,
            'unit': p.unit,
            'price': money(p.price),
            'stock': '${p.stock}',
            'availability': StockPill(product: p),
            'status': StatusChip(p.status),
          },
        )
        .toList();

    return SmartTable(
      columns: const [
        MvColumn('product', 'Product', bold: true),
        MvColumn('category', 'Category'),
        MvColumn('price', 'Wholesale price', align: TextAlign.right),
        MvColumn('stock', 'Stock', align: TextAlign.right),
        MvColumn('availability', 'Availability'),
        MvColumn('status', 'Status'),
      ],
      rows: rows,
      actionsLabel: '',
      filterKey: 'status',
      filterOptions: const ['ACTIVE', 'OUT_OF_STOCK', 'ARCHIVED'],
      pageSize: 8,
      emptyMessage: 'No products yet — add your first one.',
      rowActions: (row) {
        final p = row['_product'] as SupplierProduct;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TableActionBtn(
              icon: 'eye',
              tooltip: 'View',
              onPressed: () => _showDetail(context, p),
            ),
            const SizedBox(width: 6),
            TableActionBtn(
              icon: 'edit',
              tooltip: 'Edit',
              onPressed: () => _openForm(context, product: p),
            ),
            const SizedBox(width: 6),
            TableActionBtn(
              icon: 'trash',
              danger: true,
              tooltip: 'Remove',
              onPressed: () => _confirmDelete(context, ref, p),
            ),
          ],
        );
      },
    );
  }

  void _showDetail(BuildContext context, SupplierProduct p) {
    showMvDetailModal(
      context,
      title: 'PRODUCT DETAILS',
      children: [
        Row(
          children: [
            _thumb(p),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    '${p.category} · per ${p.unit}',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),
            StockPill(product: p),
          ],
        ),
        const SizedBox(height: 18),
        KeyValueGrid(
          entries: [
            MapEntry('Wholesale price', money(p.price)),
            // The supplier form no longer collects a retail price and the
            // backend defaults it to 0, so only show it when a real value was
            // actually stored.
            if (p.retailPrice != null && p.retailPrice! > 0)
              MapEntry('Retail price', money(p.retailPrice!)),
            MapEntry('Effective unit price', money(p.effectivePrice)),
            if (p.bulkDiscount > 0)
              MapEntry('Bulk discount', '${numFmt(p.bulkDiscount)}%'),
            MapEntry('Stock', '${p.stock}'),
            MapEntry('Minimum order', '${p.minimumOrderQuantity}'),
            MapEntry('Status', titleCase(p.status)),
            if (p.shortDescription.isNotEmpty)
              MapEntry('Description', p.shortDescription),
            if (p.gallery.isNotEmpty)
              MapEntry('Gallery', '${p.gallery.length} image(s)'),
          ],
        ),
      ],
      footer: Row(
        children: [
          Expanded(
            child: GradientButton(
              label: 'Edit',
              icon: 'edit',
              expanded: true,
              onPressed: () {
                Navigator.pop(context);
                _openForm(context, product: p);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {SupplierProduct? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (_) => _ProductFormSheet(product: product),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, SupplierProduct p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text('Remove "${p.name}" from your catalogue? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || p.id.isEmpty) return;

    try {
      await ref.read(supplierWorkspaceProvider.notifier).deleteProduct(p.id);
      if (context.mounted) showMvSnack(context, 'Product removed', success: true);
    } catch (e) {
      if (context.mounted) showMvSnack(context, friendlyError(e));
    }
  }
}

Widget _thumb(SupplierProduct p) {
  final image = p.imageUrl;
  return Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: MvColors.metricIconBg,
      borderRadius: BorderRadius.circular(9),
      image: image.isEmpty ? null : DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
    ),
    child: image.isEmpty
        ? const Icon(Icons.inventory_2_outlined, size: 20, color: MvColors.primaryDeep)
        : null,
  );
}

/// Stock availability pill driven by [SupplierProduct.stockStatus].
class StockPill extends StatelessWidget {
  const StockPill({super.key, required this.product});

  final SupplierProduct product;

  Color get _color {
    if (product.isOutOfStock) return MvColors.errorText;
    if (product.isLowStock) return MvColors.warningText;
    return MvColors.successText;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        product.stockStatus,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: .3),
      ),
    );
  }
}

/// Add / edit sheet for a supplier product. The same widget covers both
/// modes: a null [product] creates, a non-null one updates.
class _ProductFormSheet extends ConsumerStatefulWidget {
  const _ProductFormSheet({this.product});

  final SupplierProduct? product;

  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  // Exactly the fields the web supplier form collects, in the same order:
  // name, category, wholesalePrice, moq, stock, bulkDiscount, description.
  late final TextEditingController _name =
      TextEditingController(text: widget.product?.name ?? '');
  late final TextEditingController _category =
      TextEditingController(text: widget.product?.category ?? '');
  late final TextEditingController _wholesalePrice =
      TextEditingController(text: widget.product == null ? '' : '${widget.product!.price}');
  late final TextEditingController _moq =
      TextEditingController(text: '${widget.product?.minimumOrderQuantity ?? 1}');
  late final TextEditingController _stock =
      TextEditingController(text: '${widget.product?.stock ?? 0}');
  late final TextEditingController _bulkDiscount =
      TextEditingController(text: '${widget.product?.bulkDiscount ?? 0}');
  late final TextEditingController _description =
      TextEditingController(text: widget.product?.description ?? '');

  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _category,
      _wholesalePrice,
      _moq,
      _stock,
      _bulkDiscount,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Mirrors the web form's `required` set — the six value fields are
  /// mandatory and `description` is the only optional one. The numeric bounds
  /// match the backend schema (`wholesalePrice >= 0`, `moq >= 1`,
  /// `stockQuantity >= 0`, `bulkDiscount` 0–100) so a bad value is caught here
  /// instead of coming back as an opaque API error.
  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Enter a product name';
    if (_category.text.trim().isEmpty) return 'Enter a category';
    final price = num.tryParse(_wholesalePrice.text.trim());
    if (_wholesalePrice.text.trim().isEmpty) return 'Enter a wholesale price';
    if (price == null || price < 0) return 'Enter a valid wholesale price';
    final moq = int.tryParse(_moq.text.trim());
    if (moq == null || moq < 1) return 'Minimum order must be 1 or more';
    final stock = int.tryParse(_stock.text.trim());
    if (stock == null || stock < 0) return 'Enter a valid stock quantity';
    final discount = num.tryParse(_bulkDiscount.text.trim());
    if (discount == null || discount < 0 || discount > 100) {
      return 'Bulk discount must be between 0 and 100';
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) {
      showMvSnack(context, problem);
      return;
    }
    setState(() => _busy = true);

    final isEdit = widget.product != null;
    final existing = widget.product;
    final stock = int.parse(_stock.text.trim());
    final product = SupplierProduct(
      // An empty id is what tells the workspace service to POST rather
      // than PUT, so a create keeps the sheet's product unset.
      id: existing?.id ?? '',
      name: _name.text.trim(),
      category: _category.text.trim(),
      description: _description.text.trim(),
      price: num.parse(_wholesalePrice.text.trim()).toDouble(),
      stock: stock,
      minimumOrderQuantity: int.parse(_moq.text.trim()),
      bulkDiscount: num.parse(_bulkDiscount.text.trim()).toDouble(),
      // Not collected by this form, so carry the stored values through. The
      // payload omits them, and the backend preserves them on update.
      unit: existing?.unit ?? 'piece',
      retailPrice: existing?.retailPrice,
      imageUrl: existing?.imageUrl ?? '',
      gallery: existing?.gallery ?? const <String>[],
      status: existing?.status ?? 'ACTIVE',
    );

    try {
      await ref.read(supplierWorkspaceProvider.notifier).saveProduct(product);
      if (mounted) {
        Navigator.pop(context);
        showMvSnack(context, isEdit ? 'Product updated' : 'Product added', success: true);
      }
    } catch (e) {
      if (mounted) showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit wholesale product' : 'Add wholesale product',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter the wholesale product details vendors will see when sourcing stock.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Product name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Category *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _wholesalePrice,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Wholesale price (RWF) *',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _moq,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum order quantity *',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stock,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bulkDiscount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Bulk discount (%) *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                helperText: 'Optional',
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: isEdit ? 'Save changes' : 'Add wholesale product',
              icon: 'check',
              expanded: true,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
