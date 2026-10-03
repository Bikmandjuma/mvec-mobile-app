import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/party.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  PartyQuery _query = const PartyQuery();

  void _setPage(int page) {
    setState(() {
      _query = PartyQuery(page: page, status: _query.status, verification: _query.verification, search: _query.search);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorsProvider(_query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Vendors',
          subtitle: 'Review vendor records, verification and account status.',
        ),
        const InfoBox('Vendor account data is protected — business details are view-only through the profile.'),
        const SizedBox(height: 18),
        switch (vendorsAsync) {
          AsyncLoading() => const LoadingState(),
          AsyncError(:final error) => ErrorState(
              message: friendlyError(error),
              onRetry: () => ref.invalidate(vendorsProvider(_query)),
            ),
          AsyncData(:final value) => _table(value),
          _ => const LoadingState(),
        },
      ],
    );
  }

  Widget _table(Paged<PartyRecord> paged) {
    final rows = paged.items.map((p) => {
          '_record': p,
          'store': p.display,
          'category': p.category ?? '—',
          'products': '${p.productCount ?? p.products ?? 0}',
          'rating': p.rating == null ? '—' : '★ ${p.rating!.toStringAsFixed(1)}',
          'status': StatusChip(p.effectiveStatus),
        }).toList();

    return SmartTable(
      columns: const [
        MvColumn('store', 'Store', bold: true),
        MvColumn('category', 'Category'),
        MvColumn('products', 'Products', align: TextAlign.right),
        MvColumn('rating', 'Rating', align: TextAlign.right),
        MvColumn('status', 'Status'),
      ],
      rows: rows,
      actionsLabel: '',
      filterKey: 'status',
      filterOptions: const ['ACTIVE', 'SUSPENDED', 'BLOCKED', 'UNDER_REVIEW', 'VERIFIED', 'PENDING'],
      pageSize: 8,
      serverPage: _query.page,
      serverTotalPages: paged.pages ?? 1,
      onServerPageChanged: _setPage,
      rowActions: (row) {
        final p = row['_record'] as PartyRecord;
        return TableActionBtn(icon: 'eye', tooltip: 'View', onPressed: () => _showProfile(p));
      },
    );
  }

  void _showProfile(PartyRecord p) {
    showMvDetailModal(
      context,
      title: 'VENDOR PROFILE',
      children: [
        Row(
          children: [
            _avatar(p.display),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.display, style: const TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(p.category ?? p.location ?? '—', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
            StatusChip(p.effectiveStatus),
          ],
        ),
        const SizedBox(height: 18),
        KeyValueGrid(
          entries: [
            MapEntry('Store', p.display),
            MapEntry('Category', p.category ?? '—'),
            MapEntry('Products', '${p.productCount ?? p.products ?? 0}'),
            MapEntry('Rating', p.rating == null ? '—' : '★ ${p.rating!.toStringAsFixed(1)}'),
            MapEntry('ID', p.id ?? '—'),
            if (p.location != null && p.location!.isNotEmpty) MapEntry('Location', p.location!),
          ],
        ),
      ],
      footer: Row(
        children: [
          Expanded(child: GradientButton(label: 'Verify', expanded: true, onPressed: () => _verify(p))),
          const SizedBox(width: 10),
          Expanded(child: OutlineMvButton(label: 'Approve status', onPressed: () => _approve(p))),
        ],
      ),
    );
  }

  Future<void> _verify(PartyRecord p) async {
    final ctx = context;
    try {
      await ref.read(adminServiceProvider).vendorVerify(p.id ?? '', 'VERIFIED');
      if (ctx.mounted) {
        Navigator.pop(ctx);
        showMvSnack(ctx, 'Vendor verified', success: true);
      }
      ref.invalidate(vendorsProvider(_query));
    } catch (e) {
      if (ctx.mounted) showMvSnack(ctx, friendlyError(e));
    }
  }

  Future<void> _approve(PartyRecord p) async {
    final ctx = context;
    try {
      await ref.read(adminServiceProvider).vendorStatus(p.id ?? '', 'ACTIVE');
      if (ctx.mounted) {
        Navigator.pop(ctx);
        showMvSnack(ctx, 'Vendor status approved', success: true);
      }
      ref.invalidate(vendorsProvider(_query));
    } catch (e) {
      if (ctx.mounted) showMvSnack(ctx, friendlyError(e));
    }
  }
}

Widget _avatar(String name) => Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(gradient: MvColors.gradient, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials(name), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
    );