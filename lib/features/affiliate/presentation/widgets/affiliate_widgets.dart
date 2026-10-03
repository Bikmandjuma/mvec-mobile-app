import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/mv_icon.dart';
import '../../data/models/affiliate_profile.dart';

/// `.verified-box` port — informational callout for the protected commission
/// workflow shown on the dashboard.
class VerifiedBox extends StatelessWidget {
  const VerifiedBox(this.title, this.text, {super.key, this.icon = 'shield'});
  final String title;
  final String text;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? MvColors.darkSurface2 : MvColors.infoBoxBg,
        border: Border.all(color: isDark ? MvColors.darkBorder : MvColors.infoBoxBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MvIcon(icon, size: 17, color: MvColors.primaryDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: isDark ? MvColors.darkMuted : MvColors.infoBoxText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The referral code block: the affiliate's code and shareable deep link with
/// copy actions. Mirrors the "my referral link" identity card on the web.
class ReferralCodeCard extends StatelessWidget {
  const ReferralCodeCard({super.key, required this.profile, this.onCopied});
  final AffiliateProfile profile;
  final VoidCallback? onCopied;

  @override
  Widget build(BuildContext context) {
    final code = profile.code;
    final url = profile.referralUrl ?? affiliateShareUrl(code == '—' ? '' : code);
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(gradient: MvColors.gradient),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR REFERRAL',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: Colors.white.withValues(alpha: .85)),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SelectableText(
                    code,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Manrope', color: Colors.white, letterSpacing: .5),
                  ),
                ),
                _copyChip(context, code),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      copyToClipboard(context, url);
                      onCopied?.call();
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MvIcon('copy', size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _copyChip(BuildContext context, String value) {
    return InkWell(
      onTap: () {
        copyToClipboard(context, value);
        onCopied?.call();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MvIcon('copy', size: 13, color: MvColors.primaryDeep),
            SizedBox(width: 5),
            Text('Copy code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: MvColors.primaryDeep)),
          ],
        ),
      ),
    );
  }
}

/// Horizontal-stepper port of `.timeline-item.done` used for the payout
/// process and the verification journey.
class ProcessTimeline extends StatelessWidget {
  const ProcessTimeline({super.key, required this.steps});
  final List<({String label, bool done})> steps;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: steps[i].done ? MvColors.primaryDark : Colors.transparent,
                      border: Border.all(color: steps[i].done ? MvColors.primaryDark : (isDark ? MvColors.darkBorder : MvColors.border), width: 2),
                    ),
                    child: steps[i].done
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : null,
                  ),
                  if (i != steps.length - 1)
                    Container(
                      width: 2,
                      height: 30,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: isDark ? MvColors.darkBorder : MvColors.border,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(
                    '${i + 1}. ${steps[i].label}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: steps[i].done ? FontWeight.w800 : FontWeight.w600,
                      color: steps[i].done ? (isDark ? MvColors.darkText : MvColors.ink) : (isDark ? MvColors.darkMuted : MvColors.muted),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Segmented period picker (7d / 30d / 90d) mirroring the dashboard period
/// select on the web console.
class PeriodTabs extends StatelessWidget {
  const PeriodTabs({super.key, required this.value, required this.onChanged, this.options = const ['7d', '30d', '90d']});
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? MvColors.darkSurface2 : MvColors.surface2,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            InkWell(
              onTap: () => onChanged(o),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: o == value ? (isDark ? MvColors.darkSurface : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  o.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: o == value ? MvColors.primaryDeep : (isDark ? MvColors.darkMuted : MvColors.muted),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact inline stat used inside cards (label + bold value).
class InlineStat extends StatelessWidget {
  const InlineStat({super.key, required this.label, required this.value, this.icon});
  final String label;
  final String value;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: MvColors.metricIconBg, borderRadius: BorderRadius.circular(8)),
            child: Center(child: MvIcon(icon!, size: 16, color: MvColors.primaryDeep)),
          ),
          const SizedBox(height: 8),
        ],
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .5, color: Theme.of(context).hintColor)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
      ],
    );
  }
}

/// Small labelled chip used for the payment method / payout metadata.
class InfoPill extends StatelessWidget {
  const InfoPill(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: MvColors.metricIconBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: .5, color: MvColors.primaryDeep)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Row of two big numbers used in the payout / wallet detail views.
class WalletSplit extends StatelessWidget {
  const WalletSplit({super.key, required this.first, required this.second});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }
}

/// Semi-transparent wrap of a DataCard used by affiliate screens.
Widget affiliateSection({required Widget child, String? title, String? subtitle, Widget? trailing}) {
  return DataCard(title: title, subtitle: subtitle, trailing: trailing, child: child);
}