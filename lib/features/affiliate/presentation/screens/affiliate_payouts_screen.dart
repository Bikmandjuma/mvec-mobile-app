import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/mv_icon.dart';
import '../../data/models/affiliate_earnings.dart';
import '../../data/models/affiliate_profile.dart';
import '../providers/affiliate_providers.dart';
import '../widgets/affiliate_widgets.dart';

/// Withdrawal center: wallet availability, request form (with the backend
/// minimum / available-balance guards) and the payout history plus process
/// timeline. Ports the web console withdrawals experience.
class AffiliatePayoutsScreen extends ConsumerStatefulWidget {
  const AffiliatePayoutsScreen({super.key});

  @override
  ConsumerState<AffiliatePayoutsScreen> createState() => _AffiliatePayoutsScreenState();
}

class _AffiliatePayoutsScreenState extends ConsumerState<AffiliatePayoutsScreen> {
  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(affiliateWalletProvider);
    final payoutsAsync = ref.watch(affiliatePayoutsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHead(
          eyebrow: 'Earnings',
          title: 'Withdrawals',
          subtitle: 'Request a transfer of your available commission to your account.',
          actions: [
            GradientButton(label: 'Request withdrawal', icon: 'plus', onPressed: () => _requestPayout()),
          ],
        ),
        walletAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(affiliateWalletProvider)),
          data: (w) => WalletSplit(
            first: DataCard(
              title: 'Available now',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(money(w.availableBalance), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Manrope', color: MvColors.primaryDeep)),
                  const SizedBox(height: 6),
                  Text(
                    w.canWithdraw ? 'Ready to withdraw' : 'Needs ${money(w.shortfall)} more to reach the minimum',
                    style: TextStyle(fontSize: 11.5, color: w.canWithdraw ? MvColors.successText : Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),
            second: DataCard(
              title: 'Lifetime',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(money(w.totalWithdrawn), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
                  const SizedBox(height: 6),
                  Text('Withdrawn · min ${money(w.minimumPayout)}' , style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        DataCard(
          title: 'How withdrawals work',
          subtitle: 'Each request is reviewed before the transfer is sent.',
          child: ProcessTimeline(
            steps: const [
              (label: 'You submit a request with the amount', done: true),
              (label: 'MVEC validates your balance and destination', done: false),
              (label: 'Payment is sent through the channel', done: false),
              (label: 'Transfer is confirmed by the bank / mobile money provider', done: false),
            ],
          ),
        ),
        const SizedBox(height: 16),
        payoutsAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(affiliatePayoutsProvider)),
          data: (payouts) => DataCard(
            title: 'Withdrawal history',
            child: payouts.isEmpty
                ? const EmptyState(message: 'No withdrawals yet')
                : Column(
                    children: [
                      for (final p in payouts)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Row(
                            children: [
                              Container(width: 34, height: 34, decoration: BoxDecoration(color: MvColors.metricIconBg, borderRadius: BorderRadius.circular(8)),
                                child: Center(child: MvIcon('wallet', size: 15, color: MvColors.primaryDeep))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(child: Text(p.payoutNumber ?? 'Withdrawal', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
                                        const SizedBox(width: 8),
                                        StatusChip(p.status ?? 'PENDING'),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${payoutMethodLabel(p.paymentMethod)} · ${shortDateTime(p.createdAt)}',
                                      style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(money(p.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'Manrope', color: MvColors.primaryDeep)),
                              IconButton(
                                onPressed: () => _detail(p),
                                icon: MvIcon('arrow', size: 16, color: Theme.of(context).hintColor).rotate(90),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _requestPayout() async {
    final wallet = ref.read(affiliateWalletProvider).valueOrNull;
    if (wallet == null) return;
    if (!wallet.canWithdraw) {
      showMvSnack(context, 'Available balance must reach ${money(wallet.minimumPayout)} before withdrawing');
      return;
    }
    await _requestPayoutModal(wallet);
  }

  Future<void> _requestPayoutModal(AffiliateWallet wallet) async {
    final amount = TextEditingController(text: wallet.availableBalance.truncateToDouble().toStringAsFixed(0));
    final accountName = TextEditingController();
    final phone = TextEditingController();
    String? method = wallet.minimumPayout == 0 ? 'MTN_MOMO' : defaultPayout();
    var result = _PayoutResult(amount: wallet.availableBalance.toInt(), method: method ?? 'MTN_MOMO');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .88),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + MediaQuery.of(ctx).viewInsets.bottom + 8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 16),
                const Text('Request withdrawal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Available: ${money(wallet.availableBalance)} · minimum ${money(wallet.minimumPayout)}', style: TextStyle(fontSize: 11.5, color: Theme.of(ctx).hintColor)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: const InputDecoration(labelText: 'Amount (RWF)'),
                  onChanged: (v) => setLocal(() => result = result.copyWith(amount: int.tryParse(v.trim()) ?? 0)),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Payment method'),
                  items: [for (final m in kAffiliatePayoutMethods) DropdownMenuItem(value: m.value, child: Text(m.label))],
                  onChanged: (v) => setLocal(() {
                    method = v;
                    result = result.copyWith(method: v ?? 'MTN_MOMO');
                  }),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: accountName,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: const InputDecoration(labelText: 'Account name'),
                  onChanged: (v) => setLocal(() => result = result.copyWith(accountName: v.trim())),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(labelText: method == 'BANK_TRANSFER' ? 'Phone number' : 'Phone number (MoMo)'),
                  onChanged: (v) => setLocal(() => result = result.copyWith(phone: v.trim())),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'Submit request',
                    icon: 'check',
                    expanded: true,
                    onPressed: () async {
                      final ok = result.amount >= wallet.minimumPayout && result.amount <= wallet.availableBalance && result.phone.isNotEmpty;
                      if (!ok) {
                        showMvSnack(ctx, 'Enter an amount within range and your account phone number');
                        return;
                      }
                      Navigator.pop(ctx);
                      await _submit(result);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    amount.dispose();
    accountName.dispose();
    phone.dispose();
  }

  String? defaultPayout() {
    final s = ref.read(affiliateSettingsProvider).valueOrNull;
    return s?.defaultPayoutMethod ?? 'MTN_MOMO';
  }

  Future<void> _submit(_PayoutResult r) async {
    try {
      await ref.read(affiliateServiceProvider).requestPayout(
            amount: r.amount,
            paymentMethod: r.method,
            accountName: r.accountName,
            phoneNumber: r.phone,
          );
      if (!mounted) return;
      showMvSnack(context, 'Withdrawal requested', success: true);
      ref.invalidate(affiliatePayoutsProvider);
      ref.invalidate(affiliateWalletProvider);
      ref.invalidate(affiliateOverviewProvider);
    } catch (e) {
      if (!mounted) return;
      showMvSnack(context, friendlyError(e));
    }
  }

  Future<void> _detail(AffiliatePayout p) {
    return showMvDetailModal(
      context,
      title: p.payoutNumber ?? 'Withdrawal',
      children: [
        Row(
          children: [
            StatusChip(p.status ?? 'PENDING'),
            const Spacer(),
            Text(money(p.amount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Manrope', color: MvColors.primaryDeep)),
          ],
        ),
        const SizedBox(height: 16),
        ProcessTimeline(steps: p.steps),
        const SizedBox(height: 6),
        InfoPill('DESTINATION', p.destination),
        if (p.rejectionReason != null && p.rejectionReason!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: VerifiedBox('Rejected', p.rejectionReason!, icon: 'shield'),
          ),
        if (p.note != null && p.note!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(p.note!, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          ),
      ],
    );
  }
}

class _PayoutResult {
  const _PayoutResult({this.amount = 0, this.method = 'MTN_MOMO', this.accountName = '', this.phone = ''});
  final int amount;
  final String method;
  final String accountName;
  final String phone;

  _PayoutResult copyWith({int? amount, String? method, String? accountName, String? phone}) => _PayoutResult(
        amount: amount ?? this.amount,
        method: method ?? this.method,
        accountName: accountName ?? this.accountName,
        phone: phone ?? this.phone,
      );
}

extension _RotateWidget on Widget {
  Widget rotate(double deg) => Transform.rotate(angle: deg * 3.141592653589793 / 180, child: this);
}