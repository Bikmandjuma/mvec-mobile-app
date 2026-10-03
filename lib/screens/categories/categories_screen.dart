import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Categories',
          subtitle: 'Manage product categories.',
          actions: [
            GradientButton(label: 'Add new', icon: 'plus', onPressed: () => _showCategoryModal(context, ref)),
          ],
        ),
        categoriesAsync.when(
          data: (categories) => SmartTable(
            columns: const [
              MvColumn('Category', 'Category', bold: true),
              MvColumn('Products', 'Products'),
              MvColumn('Status', 'Status'),
            ],
            rows: [
              for (final c in categories)
                {
                  'Category': c.name ?? '—',
                  'Products': '${c.products ?? 0}',
                  'Status': c.active == false ? 'Inactive' : 'Active',
                  '_category': c,
                },
            ],
            pageSize: 8,
            rowActions: (row) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TableActionBtn(
                  icon: 'edit',
                  tooltip: 'Rename',
                  onPressed: () => _showCategoryModal(context, ref, category: row['_category'] as CategoryRecord),
                ),
                const SizedBox(width: 6),
                TableActionBtn(
                  icon: 'trash',
                  danger: true,
                  tooltip: 'Delete',
                  onPressed: () => _deleteCategory(context, ref, row['_category'] as CategoryRecord),
                ),
              ],
            ),
          ),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(categoriesProvider)),
          loading: () => const LoadingState(),
        ),
      ],
    );
  }

  Future<void> _showCategoryModal(BuildContext context, WidgetRef ref, {CategoryRecord? category}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (_) => _CategoryFormSheet(category: category),
    );
  }

  Future<void> _deleteCategory(BuildContext context, WidgetRef ref, CategoryRecord category) async {
    final id = category.id;
    if (id == null) return;
    final ok = await _confirmDialog(context, 'Delete ${category.name ?? 'this category'}?');
    if (!ok) return;
    try {
      await ref.read(adminServiceProvider).deleteCategory(id);
      if (context.mounted) showMvSnack(context, 'Category deleted', success: true);
      ref.invalidate(categoriesProvider);
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

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({this.category});

  final CategoryRecord? category;

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.category?.name ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showMvSnack(context, 'Enter a category name');
      return;
    }
    setState(() => _busy = true);
    final id = widget.category?.id;
    try {
      final svc = ref.read(adminServiceProvider);
      if (id == null) {
        await svc.createCategory({'name': _name.text.trim()});
      } else {
        await svc.patchCategory(id, {'name': _name.text.trim()});
      }
      if (mounted) {
        Navigator.pop(context);
        showMvSnack(context, id == null ? 'Category added' : 'Category updated', success: true);
      }
      ref.invalidate(categoriesProvider);
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
            Text(widget.category == null ? 'Add category' : 'Rename category', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 18),
            GradientButton(
              label: widget.category == null ? 'Save category' : 'Update category',
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