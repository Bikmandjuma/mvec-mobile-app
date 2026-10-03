import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../widgets/common.dart';
import '../models/vendor_finance.dart';
import '../services/vendor_finance_service.dart';
import '../vendor_dependencies.dart';
import '../widgets/vendor_dashboard_widgets.dart';

/// Earnings, escrow, payout history and vendor withdrawal requests.
class VendorSalesScreen extends ConsumerWidget {
  const VendorSalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(vendorFinanceSummaryProvider);
    final ledgerAsync = ref.watch(vendorLedgerProvider);
    final payoutsAsync = ref.watch(vendorPayoutsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'MONEY & SETTLEMENTS',
          title: 'Sales & earnings',
          subtitle:
              'Follow revenue from escrow through to your payout balance.',
          actions: [
            FilledButton.icon(
              onPressed:
                  summaryAsync.valueOrNull == null
                      ? null
                      : () => _requestPayout(
                        context,
                        ref,
                        summaryAsync.valueOrNull!,
                      ),
              icon: const Icon(Icons.south_west, size: 17),
              label: const Text('Request payout'),
            ),
          ],
        ),
        switch (summaryAsync) {
          AsyncLoading() => const SizedBox(height: 170, child: LoadingState()),
          AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry: () => ref.invalidate(vendorFinanceSummaryProvider),
          ),
          AsyncData(:final value) => _summary(context, ref, value),
          _ => const SizedBox(height: 170, child: LoadingState()),
        },
        const SizedBox(height: 14),
        switch (ledgerAsync) {
          AsyncLoading() => const SizedBox(height: 170, child: LoadingState()),
          AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry: () => ref.invalidate(vendorLedgerProvider),
          ),
          AsyncData(:final value) => DataCard(
            title: 'Recent money movements',
            subtitle:
                'Sales, commission deductions, escrow releases and withdrawals.',
            child:
                value.isEmpty
                    ? const EmptyState(message: 'No transactions to show yet.')
                    : Column(
                      children: [
                        for (var i = 0; i < value.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, color: context.mv.border),
                          VendorLedgerTile(entry: value[i]),
                        ],
                      ],
                    ),
          ),
          _ => const SizedBox(height: 170, child: LoadingState()),
        },
        const SizedBox(height: 14),
        switch (payoutsAsync) {
          AsyncLoading() => const SizedBox(height: 100, child: LoadingState()),
          AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry: () => ref.invalidate(vendorPayoutsProvider),
          ),
          AsyncData(:final value) => DataCard(
            title: 'Payout requests',
            subtitle:
                'Pending requests are reserved from your available balance.',
            child:
                value.isEmpty
                    ? const EmptyState(message: 'No payout requests yet.')
                    : Column(
                      children: [
                        for (final payout in value) _payoutRow(context, payout),
                      ],
                    ),
          ),
          _ => const SizedBox(height: 100, child: LoadingState()),
        },
      ],
    );
  }

  Widget _summary(
    BuildContext context,
    WidgetRef ref,
    VendorFinanceSummary value,
  ) {
    final metrics = [
      VendorFinanceMetric(
        label: 'Total revenue',
        amount: value.grossRevenue,
        icon: 'chart',
      ),
      VendorFinanceMetric(
        label: 'Net earnings',
        amount: value.netEarnings,
        icon: 'wallet',
      ),
      VendorFinanceMetric(
        label: 'Pending escrow',
        amount: value.escrowHeld,
        icon: 'shield',
      ),
      VendorFinanceMetric(
        label: 'Available payout',
        amount: value.availablePayout,
        icon: 'arrow',
        emphasis: true,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 720 ? 4 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final metric in metrics)
                  SizedBox(width: width, child: metric),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        DataCard(
          title: 'Earnings · last 14 days',
          subtitle:
              'Commission deducted: ${money(value.commission)} · ${(value.commissionRate * 100).toStringAsFixed(0)}% platform rate',
          trailing: Text(
            '${value.revenueDelta >= 0 ? '+' : ''}${(value.revenueDelta * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color:
                  value.revenueDelta >= 0
                      ? MvColors.successText
                      : MvColors.errorText,
            ),
          ),
          child: _earningsChart(context, value.series),
        ),
      ],
    );
  }

  Widget _earningsChart(BuildContext context, List<EarningsPoint> points) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 130,
        child: Center(child: Text('No earnings activity in this period.')),
      );
    }
    final maximum = points
        .map((point) => point.net.toDouble())
        .fold<double>(1, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 144,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Tooltip(
                  message: '${shortDate(point.at)} · ${money(point.net)}',
                  child: Container(
                    height: 16 + 105 * point.net.toDouble() / maximum,
                    decoration: BoxDecoration(
                      color: MvColors.primary.withValues(alpha: .72),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _payoutRow(BuildContext context, PayoutRequest payout) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        const Icon(
          Icons.account_balance_wallet_outlined,
          size: 18,
          color: MvColors.primaryDeep,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payout.method.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${shortDateTime(payout.requestedAt)} · ${payout.destination ?? 'Destination not recorded'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: context.mv.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              money(payout.amount),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            StatusChip(payout.status),
          ],
        ),
      ],
    ),
  );

  Future<void> _requestPayout(
    BuildContext context,
    WidgetRef ref,
    VendorFinanceSummary summary,
  ) async {
    final formKey = GlobalKey<FormState>();
    final amount = TextEditingController();
    final destination = TextEditingController();
    final note = TextEditingController();
    var method = PayoutMethod.mtnMomo;
    final submitted = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  title: const Text('Request a payout'),
                  content: SizedBox(
                    width: 420,
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Available: ${money(summary.availablePayout)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: amount,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Amount (RWF)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final parsed = num.tryParse(
                                value?.replaceAll(',', '').trim() ?? '',
                              );
                              if (parsed == null || parsed < kMinPayoutAmount) {
                                return 'Minimum payout is ${money(kMinPayoutAmount)}';
                              }
                              if (parsed > summary.availablePayout) {
                                return 'Amount exceeds your available balance';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<PayoutMethod>(
                            initialValue: method,
                            decoration: const InputDecoration(
                              labelText: 'Payout method',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (final option in PayoutMethod.values)
                                DropdownMenuItem(
                                  value: option,
                                  child: Text(option.label),
                                ),
                            ],
                            onChanged:
                                (value) => setDialogState(
                                  () => method = value ?? method,
                                ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: destination,
                            decoration: InputDecoration(
                              labelText:
                                  method == PayoutMethod.bankTransfer
                                      ? 'Bank account / IBAN'
                                      : 'Mobile Money phone number',
                              border: const OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Enter a payout destination'
                                        : null,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: note,
                            decoration: const InputDecoration(
                              labelText: 'Note (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Not now'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() == true) {
                          Navigator.pop(dialogContext, true);
                        }
                      },
                      child: const Text('Submit request'),
                    ),
                  ],
                ),
          ),
    );
    if (submitted == true && context.mounted) {
      try {
        await ref
            .read(vendorFinanceModuleProvider)
            .requestPayout(
              amount: num.parse(amount.text.replaceAll(',', '').trim()),
              method: method,
              destination: destination.text,
              note: note.text,
            );
        ref.invalidate(vendorFinanceSummaryProvider);
        ref.invalidate(vendorLedgerProvider);
        ref.invalidate(vendorPayoutsProvider);
        if (context.mounted) {
          showMvSnack(context, 'Payout request submitted', success: true);
        }
      } catch (error) {
        if (context.mounted) showMvSnack(context, friendlyError(error));
      }
    }
    amount.dispose();
    destination.dispose();
    note.dispose();
  }
}
