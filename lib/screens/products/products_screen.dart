import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Products',
          subtitle: 'Manage the marketplace catalog.',
          actions: [
            GradientButton(label: 'Add new', icon: 'plus', onPressed: () => _showProductModal(context, ref)),
          ],
        ),
        productsAsync.when(
          data: (products) => SmartTable(
            columns: const [
              MvColumn('Product', 'Product', bold: true),
              MvColumn('Vendor', 'Vendor'),
              MvColumn('Price', 'Price'),
              MvColumn('Stock', 'Stock'),
              MvColumn('Status', 'Status'),
            ],
            rows: [
              for (final p in products)
                {
                  'Product': p.display,
                  'Vendor': p.vendor ?? '—',
                  'Price': money(p.price),
                  'Stock': '${p.stock ?? 0}',
                  'Status': p.status ?? 'ACTIVE',
                  '_product': p,
                },
            ],
            pageSize: 8,
            rowActions: (row) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TableActionBtn(
                  icon: 'edit',
                  tooltip: 'Edit',
                  onPressed: () => _showProductModal(context, ref, product: row['_product'] as ProductRecord),
                ),
                const SizedBox(width: 6),
                TableActionBtn(
                  icon: 'trash',
                  danger: true,
                  tooltip: 'Delete',
                  onPressed: () => _deleteProduct(context, ref, row['_product'] as ProductRecord),
                ),
              ],
            ),
          ),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(productsProvider)),
          loading: () => const LoadingState(),
        ),
      ],
    );
  }

  Future<void> _showProductModal(BuildContext context, WidgetRef ref, {ProductRecord? product}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (_) => _ProductFormSheet(product: product),
    );
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref, ProductRecord product) async {
    final id = product.id;
    if (id == null) return;
    final ok = await _confirmDialog(context, 'Delete ${product.display}? This cannot be undone.');
    if (!ok) return;
    try {
      await ref.read(adminServiceProvider).deleteProduct(id);
      if (context.mounted) showMvSnack(context, 'Product deleted', success: true);
      ref.invalidate(productsProvider);
    } catch (e) {
      if (context.mounted) showMvSnack(context, friendlyError(e));
    }
  }
}

Future<bool> _confirmDialog(BuildContext context, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm'),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
          ],
        ),
      ) ??
      false;
}

class _ProductFormSheet extends ConsumerStatefulWidget {
  const _ProductFormSheet({this.product});

  final ProductRecord? product;

  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.product?.name ?? '');
  late final TextEditingController _price = TextEditingController(text: widget.product?.price?.toString() ?? '');
  late final TextEditingController _stock = TextEditingController(text: widget.product?.stock?.toString() ?? '');
  late final TextEditingController _category = TextEditingController(text: widget.product?.category ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showMvSnack(context, 'Enter a product name');
      return;
    }
    setState(() => _busy = true);
    final id = widget.product?.id;
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      if (_price.text.trim().isNotEmpty) 'price': num.tryParse(_price.text.trim()),
      if (_stock.text.trim().isNotEmpty) 'stockQuantity': int.tryParse(_stock.text.trim()),
      if (_category.text.trim().isNotEmpty) 'category': _category.text.trim(),
    };
    try {
      final svc = ref.read(adminServiceProvider);
      if (id == null) {
        await svc.createProduct(body);
      } else {
        await svc.patchProduct(id, body);
      }
      if (mounted) {
        Navigator.pop(context);
        showMvSnack(context, id == null ? 'Product added' : 'Product updated', success: true);
      }
      ref.invalidate(productsProvider);
    } catch (e) {
      if (mounted) showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text(widget.product == null ? 'Add product' : 'Edit product', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _price, decoration: const InputDecoration(labelText: 'Price'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _stock, decoration: const InputDecoration(labelText: 'Stock'))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _category, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 18),
            GradientButton(
              label: widget.product == null ? 'Save product' : 'Update product',
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