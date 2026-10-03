import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/user.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

const _userStatuses = ['ACTIVE', 'SUSPEND', 'BLOCK', 'INVESTIGATE'];

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Users',
          subtitle: 'Manage marketplace records and platform operations.',
        ),
        const InfoBox(
          'Account data is protected — names and email addresses are not editable. Use the View action to inspect records.',
        ),
        const SizedBox(height: 18),
        DataCard(
          title: 'Users & buyers',
          child: switch (usersAsync) {
            AsyncLoading() => const LoadingState(),
            AsyncError(:final error) => ErrorState(
                message: friendlyError(error),
                onRetry: () => ref.invalidate(usersProvider),
              ),
            AsyncData(:final value) => _table(context, ref, value),
            _ => const LoadingState(),
          },
        ),
      ],
    );
  }

  Widget _table(BuildContext context, WidgetRef ref, List<UserRecord> users) {
    final rows = users.map((u) => {
          '_record': u,
          'user': u.display,
          'email': u.email ?? '—',
          'role': titleCase(u.role ?? ''),
          'status': StatusChip(u.status),
        }).toList();

    return SmartTable(
      columns: const [
        MvColumn('user', 'User', bold: true),
        MvColumn('email', 'Email'),
        MvColumn('role', 'Role'),
        MvColumn('status', 'Status'),
      ],
      rows: rows,
      actionsLabel: '',
      filterKey: 'role',
      filterOptions: const ['Buyer', 'Vendor', 'Affiliate', 'Supplier', 'Super Admin'],
      pageSize: 8,
      csvFileName: 'users',
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
      title: 'USER PROFILE',
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
            StatusChip(u.role),
            const SizedBox(width: 6),
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
            MapEntry('Company', u.companyName ?? '—'),
          ],
        ),
      ],
    );
  }

  void _showStatusModal(BuildContext context, WidgetRef ref, UserRecord u) {
    var selected = (u.status ?? 'ACTIVE').toUpperCase();
    if (!_userStatuses.contains(selected)) selected = 'ACTIVE';
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
                          for (final s in _userStatuses) DropdownMenuItem(value: s, child: Text(titleCase(s), style: const TextStyle(fontSize: 13))),
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
              ref.invalidate(usersProvider);
              final sc = sheetContext;
              if (sc != null && sc.mounted) Navigator.pop(sc);
              if (ctx.mounted) showMvSnack(ctx, 'User status updated', success: true);
            } catch (e) {
              if (ctx.mounted) showMvSnack(ctx, friendlyError(e));
            }
          },
        ),
      ),
    );
  }
}