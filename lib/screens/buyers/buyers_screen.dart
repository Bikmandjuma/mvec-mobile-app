import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/user.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

const _buyerStatuses = ['ACTIVE', 'SUSPEND', 'BLOCK', 'INVESTIGATE'];

/// Buyer management — people & stores group. Lists marketplace buyers
/// (role = buyer) with search/filter, profile inspection and status updates.
class BuyersScreen extends ConsumerWidget {
  const BuyersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buyersAsync = ref.watch(buyersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Buyers',
          subtitle: 'Review every buyer that shops on the MVEC marketplace.',
        ),
        const InfoBox('Buyers are end-customers of the marketplace. Suspend or block accounts to protect the platform.'),
        const SizedBox(height: 18),
        DataCard(
          title: 'Buyer accounts',
          child: switch (buyersAsync) {
            AsyncLoading() => const LoadingState(),
            AsyncError(:final error) => ErrorState(
                message: friendlyError(error),
                onRetry: () => ref.invalidate(buyersProvider),
              ),
            AsyncData(:final value) => _table(context, ref, value),
            _ => const LoadingState(),
          },
        ),
      ],
    );
  }

  Widget _table(BuildContext context, WidgetRef ref, List<UserRecord> buyers) {
    final rows = buyers.map((u) => {
          '_record': u,
          'buyer': u.display,
          'email': u.email ?? '—',
          'phone': u.phone ?? '—',
          'joined': u.createdAt == null ? '—' : formatDate(u.createdAt!),
          'status': StatusChip(u.status),
        }).toList();

    return SmartTable(
      columns: const [
        MvColumn('buyer', 'Buyer', bold: true),
        MvColumn('email', 'Email'),
        MvColumn('phone', 'Phone'),
        MvColumn('joined', 'Joined'),
        MvColumn('status', 'Status'),
      ],
      rows: rows,
      actionsLabel: '',
      filterKey: 'status',
      pageSize: 8,
      csvFileName: 'buyers',
      rowActions: (row) {
        final u = row['_record'] as UserRecord;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TableActionBtn(icon: 'eye', tooltip: 'View', onPressed: () => _showProfile(context, u)),
            const SizedBox(width: 6),
            TableActionBtn(icon: 'edit', tooltip: 'Status', onPressed: () => _showStatusModal(context, ref, u)),
          ],
        );
      },
    );
  }

  void _showProfile(BuildContext context, UserRecord u) {
    showMvDetailModal(
      context,
      title: 'BUYER PROFILE',
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(gradient: MvColors.gradient, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                initials(u.display),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.display, style: const TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(u.email ?? '—', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
            StatusChip(u.status),
          ],
        ),
        const SizedBox(height: 18),
        KeyValueGrid(
          entries: [
            MapEntry('Full name', u.fullname ?? '—'),
            MapEntry('Email', u.email ?? '—'),
            MapEntry('Phone', u.phone ?? '—'),
            MapEntry('Role', titleCase(u.role ?? '')),
            MapEntry('Status', titleCase(u.status ?? '')),
            MapEntry('Gender', titleCase(u.gender ?? '')),
            MapEntry('Joined', u.createdAt == null ? '—' : formatDate(u.createdAt!)),
          ],
        ),
      ],
    );
  }

  void _showStatusModal(BuildContext context, WidgetRef ref, UserRecord u) {
    var selected = (u.status ?? 'ACTIVE').toUpperCase();
    if (!_buyerStatuses.contains(selected)) selected = 'ACTIVE';
    BuildContext? sheetContext;
    showMvDetailModal(
      context,
      title: 'UPDATE STATUS',
      children: [
        StatefulBuilder(
          builder: (ctx, setModal) {
            sheetContext = ctx;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Account status', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(ctx).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selected,
                        isExpanded: true,
                        items: [
                          for (final s in _buyerStatuses) DropdownMenuItem(value: s, child: Text(titleCase(s), style: const TextStyle(fontSize: 13))),
                        ],
                        onChanged: (v) => setModal(() => selected = v ?? selected),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
      footer: SizedBox(
        width: double.infinity,
        child: GradientButton(
          label: 'Save',
          expanded: true,
          onPressed: () async {
            final ctx = context;
            try {
              await ref.read(adminServiceProvider).patchUser(u.id ?? '', {'status': selected});
              ref.invalidate(buyersProvider);
              final sc = sheetContext;
              if (sc != null && sc.mounted) Navigator.pop(sc);
              if (ctx.mounted) showMvSnack(ctx, 'Buyer status updated', success: true);
            } catch (e) {
              if (ctx.mounted) showMvSnack(ctx, friendlyError(e));
            }
          },
        ),
      ),
    );
  }
}