import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/catalog.dart';
import '../../models/party.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/smart_table.dart';

const _payoutStatuses = ['COMPLETED', 'REJECTED'];

class AffiliatesScreen extends ConsumerWidget {
  const AffiliatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final affiliatesAsync = ref.watch(affiliatesProvider);
    final payoutsAsync = ref.watch(affiliatePayoutsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'SUPER ADMIN',
          title: 'Affiliates',
          subtitle: 'Manage affiliate partners, their conversions and payouts.',
        ),
        DataCard(
          title: 'Affiliates',
          child: switch (affiliatesAsync) {
            AsyncLoading() => const LoadingState(),
            AsyncError(:final error) => ErrorState(
                message: friendlyError(error),
                onRetry: () => ref.invalidate(affiliatesProvider),
              ),
            AsyncData(:final value) => _affiliatesTable(context, value),
            _ => const LoadingState(),
          },
        ),
        const SizedBox(height: 18),
        DataCard(
          title: 'Affiliate payouts',
          child: switch (payoutsAsync) {
            AsyncLoading() => const LoadingState(),
            AsyncError(:final error) => ErrorState(
                message: friendlyError(error),
                onRetry: () => ref.invalidate(affiliatePayoutsProvider),
              ),
            AsyncData(:final value) => _payoutsTable(context, ref, value),
            _ => const LoadingState(),
          },
        ),
      ],
    );
  }

  Widget _affiliatesTable(BuildContext context, List<PartyRecord> affiliates) {
    final rows = affiliates.map((a) => {
          '_record': a,
          'affiliate': a.display,
          'orders': '${a.orders ?? 0}',
          'clicks': '${a.clicks ?? 0}',
          'earnings': money(a.earnings),
          'status': StatusChip(a.status ?? 'Active'),
        }).toList();

    return SmartTable(
      columns: const [
        MvColumn('affiliate', 'Affiliate', bold: true),
        MvColumn('orders', 'Orders', align: TextAlign.right),
        MvColumn('clicks', 'Clicks', align: TextAlign.right),
        MvColumn('earnings', 'Earnings', align: TextAlign.right),
        MvColumn('status', 'Status'),
      ],
      rows: rows,
      actionsLabel: '',
      rowActions: (row) {
        final a = row['_record'] as PartyRecord;
        return TableActionBtn(icon: 'eye', tooltip: 'View', onPressed: () => _viewAffiliate(context, a));
      },
    );
  }

  void _viewAffiliate(BuildContext context, PartyRecord a) {
    showMvDetailModal(
      context,
      title: 'AFFILIATE PROFILE',
      children: [
        Row(
          children: [
            _avatar(a.display),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.display, style: const TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(a.email ?? '—', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
            StatusChip(a.status ?? 'Active'),
          ],
        ),
        const SizedBox(height: 18),
        KeyValueGrid(
          entries: [
            MapEntry('Name', a.display),
            MapEntry('Email', a.email ?? '—'),
            MapEntry('Phone', a.phone ?? '—'),
            MapEntry('Orders', '${a.orders ?? 0}'),
            MapEntry('Clicks', '${a.clicks ?? 0}'),
            MapEntry('Earnings', money(a.earnings)),
            MapEntry('ID', a.id ?? '—'),
          ],
        ),
      ],
    );
  }

  Widget _payoutsTable(BuildContext context, WidgetRef ref, List<PayoutRecord> payouts) {
    final rows = payouts.map((p) => {
          '_record': p,
          'payout': p.reference ?? p.id ?? '—',
          'affiliate': p.account ?? '—',
          'amount': money(p.amount),
          'status': StatusChip(p.status),
        }).toList();

    return SmartTable(
      columns: const [
        MvColumn('payout', 'Payout'),
        MvColumn('affiliate', 'Affiliate'),
        MvColumn('amount', 'Amount', align: TextAlign.right),
        MvColumn('status', 'Status'),
      ],
      rows: rows,
      actionsLabel: '',
      rowActions: (row) {
        final p = row['_record'] as PayoutRecord;
        return TableActionBtn(icon: 'check', tooltip: 'Process', onPressed: () => _processPayout(context, ref, p));
      },
    );
  }

  void _processPayout(BuildContext context, WidgetRef ref, PayoutRecord p) {
    var selected = 'COMPLETED';
    BuildContext? sheetContext;
    showMvDetailModal(
      context,
      title: 'PROCESS PAYOUT',
      children: [
        StatefulBuilder(
          builder: (ctx, setModal) {
            sheetContext = ctx;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.account ?? 'Payout', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            '${money(p.amount)} · ${p.reference ?? p.id ?? '—'}',
                            style: TextStyle(fontSize: 12, color: Theme.of(ctx).hintColor),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(p.status),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Decision', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w800)),
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
                          for (final s in _payoutStatuses) DropdownMenuItem(value: s, child: Text(titleCase(s), style: const TextStyle(fontSize: 13))),
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
              await ref.read(adminServiceProvider).processAffiliatePayout(p.id ?? '', selected);
              ref.invalidate(affiliatePayoutsProvider);
              final sc = sheetContext;
              if (sc != null && sc.mounted) Navigator.pop(sc);
              if (ctx.mounted) showMvSnack(ctx, 'Payout processed', success: true);
            } catch (e) {
              if (ctx.mounted) showMvSnack(ctx, friendlyError(e));
            }
          },
        ),
      ),
    );
  }
}

Widget _avatar(String name) => Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(gradient: MvColors.gradient, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials(name), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
    );