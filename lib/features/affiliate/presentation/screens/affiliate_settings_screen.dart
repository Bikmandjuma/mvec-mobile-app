import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/mv_icon.dart';
import '../../data/models/affiliate_profile.dart';
import '../providers/affiliate_providers.dart';
import '../widgets/affiliate_widgets.dart';

/// Affiliate preferences: notification channels, default payout method and
/// language. Persisted per affiliate through `/affiliates/settings`.
class AffiliateSettingsScreen extends ConsumerStatefulWidget {
  const AffiliateSettingsScreen({super.key});

  @override
  ConsumerState<AffiliateSettingsScreen> createState() => _AffiliateSettingsScreenState();
}

class _AffiliateSettingsScreenState extends ConsumerState<AffiliateSettingsScreen> {
  AffiliateSettings _local = const AffiliateSettings();
  String? _language;
  bool _initialized = false;
  bool _saving = false;

  void _init(AffiliateSettings s) {
    if (_initialized) return;
    _initialized = true;
    _local = s;
    _language = s.language;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(affiliateServiceProvider).updateSettings(
            _local.copyWith(language: _language),
          );
      if (!mounted) return;
      showMvSnack(context, 'Settings saved', success: true);
      ref.invalidate(affiliateSettingsProvider);
    } catch (e) {
      if (!mounted) return;
      showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(affiliateSettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(eyebrow: 'Account', title: 'Settings', subtitle: 'Control your notifications, payouts and language.'),
        async.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(affiliateSettingsProvider)),
          data: (settings) {
            _init(settings);
            return LayoutBuilder(
              builder: (context, c) {
                final main = _preferencesCard();
                final aside = _payoutCard();
                if (c.maxWidth > 820) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: main),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: aside),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [main, const SizedBox(height: 16), aside],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _preferencesCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DataCard(
      title: 'Notifications',
      subtitle: 'Choose how we reach you about commissions and payouts.',
      child: Column(
        children: [
          _toggle('Commission updates', 'When a referral order earns you commission.', _local.emailNotifications, (v) => setState(() => _local = _local.copyWith(emailNotifications: v))),
          _toggle('Payout alerts', 'When a withdrawal is processed or rejected.', _local.payoutAlerts, (v) => setState(() => _local = _local.copyWith(payoutAlerts: v))),
          _toggle('Push notifications', 'In-app alerts for new stats and earnings.', _local.pushNotifications, (v) => setState(() => _local = _local.copyWith(pushNotifications: v))),
          _toggle('Marketing emails', 'Campaign announcements and promo opportunities.', _local.marketingEmails, (v) => setState(() => _local = _local.copyWith(marketingEmails: v))),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: const InputDecoration(labelText: 'Language'),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Kinyarwanda', child: Text('Kinyarwanda')),
                DropdownMenuItem(value: 'French', child: Text('French')),
                DropdownMenuItem(value: 'Swahili', child: Text('Swahili')),
              ],
              onChanged: (v) => setState(() => _language = v),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                icon: MvIcon(isDark ? 'sun' : 'moon', size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(isDark ? 'Using dark theme' : 'Using light theme', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 18),
          GradientButton(label: _saving ? 'Saving…' : 'Save settings', icon: 'check', expanded: true, onPressed: _saving ? null : _save),
        ],
      ),
    );
  }

  Widget _toggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
      value: value,
      onChanged: onChanged,
      activeTrackColor: MvColors.primary,
    );
  }

  Widget _payoutCard() {
    return DataCard(
      title: 'Default payout method',
      subtitle: 'Pre-filled when you request a withdrawal.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in kAffiliatePayoutMethods)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => setState(() => _local = _local.copyWith(defaultPayoutMethod: m.value)),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _local.defaultPayoutMethod == m.value ? MvColors.metricIconBg : Colors.transparent,
                    border: Border.all(
                      color: _local.defaultPayoutMethod == m.value
                          ? MvColors.primaryDeep
                          : (Theme.of(context).brightness == Brightness.dark ? MvColors.darkBorder : MvColors.border),
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      MvIcon('wallet', size: 16, color: _local.defaultPayoutMethod == m.value ? MvColors.primaryDeep : Theme.of(context).hintColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _local.defaultPayoutMethod == m.value ? MvColors.primaryDeep : null,
                          ),
                        ),
                      ),
                      if (_local.defaultPayoutMethod == m.value) const MvIcon('check', size: 15, color: MvColors.primaryDeep),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          InfoPill('MINIMUM WITHDRAWAL', money(kAffiliateMinimumPayout)),
        ],
      ),
    );
  }
}