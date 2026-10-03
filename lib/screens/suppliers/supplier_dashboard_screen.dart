import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/supplier.dart';
import '../../providers/supplier_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/mv_icon.dart';
import 'supplier_shell.dart';

/// Landing page for a signed-in supplier.
///
/// Mirrors the web `SupplierDashboard` overview: a `dash-page-head`, a
/// four-tile metric grid and the "protected settlement" explainer box.
///
/// The web fills those tiles with hardcoded demo figures (126 products,
/// 84 orders, RWF 8.4M sales). Only two of those — products and catalogue
/// value — have a real backing endpoint (`GET /suppliers/me/products`), so the
/// remaining two tiles show stock figures instead of inventing numbers. The
/// web's "Vendor orders", "Sales" and "Protected funds" tiles have no server
/// data behind them yet.
class SupplierDashboardScreen extends ConsumerStatefulWidget {
  const SupplierDashboardScreen({super.key});

  @override
  ConsumerState<SupplierDashboardScreen> createState() => _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState extends ConsumerState<SupplierDashboardScreen> {
  /// Guards the onboarding redirect so a rebuild cannot bounce the supplier
  /// away from the profile page while they are filling the form in.
  bool _redirected = false;

  /// A supplier account with no business profile has nothing to see on the
  /// dashboard, so it is forwarded to the profile page to onboard. The check
  /// needs a resolved provider — hence both the synchronous read and the
  /// listener, which covers the case where the profile resolves after mount.
  void _forwardIfUnOnboarded(AsyncValue<SupplierDetail?> profile) {
    if (_redirected) return;
    if (profile is! AsyncData || profile.value != null) return;
    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/supplier/profile');
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(supplierProfileProvider, (_, next) => _forwardIfUnOnboarded(next));

    final profileAsync = ref.watch(supplierProfileProvider);
    final metricsAsync = ref.watch(supplierMetricsProvider);
    _forwardIfUnOnboarded(profileAsync);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHead(
          eyebrow: 'SUPPLIER PLATFORM',
          title: 'Supplier dashboard',
          subtitle: 'Supply verified MVEC vendors with wholesale products.',
        ),
        _VerificationCard(
          profileAsync: profileAsync,
          onRetry: () => ref.invalidate(supplierProfileProvider),
        ),
        const SizedBox(height: 18),
        _metricGrid(metricsAsync, ref),
        const SizedBox(height: 18),
        const _ProtectedSettlementBox(),
        const SizedBox(height: 18),
        _profileCard(context, profileAsync, ref),
      ],
    );
  }

  /// Four tiles in the web's `metric-grid`: icon chip, label, large value and
  /// a small caption. Two per row on a phone, four across on a wide screen.
  Widget _metricGrid(AsyncValue<SupplierMetrics> metricsAsync, WidgetRef ref) {
    return switch (metricsAsync) {
      AsyncLoading() => const LoadingState(),
      AsyncError(:final error) => ErrorState(
          message: friendlyError(error),
          onRetry: () => ref.invalidate(supplierMetricsProvider),
        ),
      AsyncData(:final value) => LayoutBuilder(
          builder: (context, constraints) {
            final cards = <Widget>[
              MetricCard(
                label: 'Wholesale products',
                value: numFmt(value.totalProducts),
                delta: '${numFmt(value.activeProducts)} active',
                icon: 'box',
                onTap: () => context.go('/supplier/products'),
              ),
              MetricCard(
                label: 'Units in stock',
                value: numFmt(value.totalUnitsInStock),
                delta: 'Across ${numFmt(value.totalProducts)} products',
                icon: 'cart',
              ),
              MetricCard(
                label: 'Catalog value',
                value: money(value.totalCatalogValue),
                delta: 'Wholesale price × stock',
                icon: 'chart',
              ),
              MetricCard(
                label: 'Low stock',
                value: numFmt(value.lowStockProducts),
                delta: '${numFmt(value.outOfStockProducts)} out of stock',
                deltaColor: value.lowStockProducts > 0 ? MvColors.warningText : MvColors.successText,
                icon: 'bell',
                onTap: () => context.go('/supplier/products'),
              ),
            ];

            if (constraints.maxWidth >= 860) {
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var i = 0; i < cards.length; i += 2) ...[
                  if (i > 0) const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: cards[i]),
                      const SizedBox(width: 14),
                      Expanded(child: i + 1 < cards.length ? cards[i + 1] : const SizedBox()),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      _ => const LoadingState(),
    };
  }

  Widget _profileCard(BuildContext context, AsyncValue<SupplierDetail?> profileAsync, WidgetRef ref) {
    return DataCard(
      title: 'Business profile',
      subtitle: 'Keep your details current for faster verification',
      trailing: OutlineMvButton(
        label: 'Edit',
        icon: 'edit',
        onPressed: () => context.go('/supplier/profile'),
      ),
      child: switch (profileAsync) {
        // No profile yet — the verification card already prompts for onboarding.
        AsyncData(value: null) => const InfoBox(
            'No business profile yet. Set one up so buyers can find your catalogue.',
            icon: 'edit',
          ),
        AsyncData(:final value?) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyValueGrid(entries: profileEntries(value)),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Manage products',
                icon: 'box',
                expanded: true,
                onPressed: () => context.go('/supplier/products'),
              ),
            ],
          ),
        AsyncLoading() => const LoadingState(),
        AsyncError(:final error) => ErrorState(
            message: friendlyError(error),
            onRetry: () => ref.invalidate(supplierProfileProvider),
          ),
        _ => const LoadingState(),
      },
    );
  }
}

List<MapEntry<String, String>> profileEntries(SupplierDetail s) => [
      MapEntry('Business', s.businessName ?? '—'),
      MapEntry('Email', s.email ?? '—'),
      MapEntry('Phone', s.phone ?? '—'),
      MapEntry('Rating', s.ratingAvg == null ? '—' : '★ ${s.ratingAvg!.toStringAsFixed(1)}'),
      if (s.publicId != null) MapEntry('Supplier ID', s.publicId!),
    ];

/// The web's `verified-box` in its neutral variant, explaining how MVEC holds
/// vendor payments until a supply order is fulfilled. Uses a wallet chip
/// rather than the web's 🔒 because the icon set has no lock glyph.
class _ProtectedSettlementBox extends StatelessWidget {
  const _ProtectedSettlementBox();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? MvColors.darkSurface2 : MvColors.surface2;
    final border = isDark ? MvColors.darkBorder : MvColors.border;
    final ink = isDark ? MvColors.darkText : MvColors.ink;
    final muted = isDark ? MvColors.darkMuted : MvColors.muted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MvIcon('wallet', size: 18, color: MvColors.primaryDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'MVEC protected settlement',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'When a vendor pays a supplier through the MVEC workflow, the amount is '
            'recorded as HELD. Fulfill the supply, confirm receipt/delivery, and MVEC '
            'releases the protected amount according to the marketplace rules.',
            style: TextStyle(fontSize: 12.5, height: 1.5, color: muted),
          ),
        ],
      ),
    );
  }
}

/// First-run card for a supplier account with no business profile yet. Offers
/// the one action that resolves it.
class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MvColors.infoBoxBg,
        border: Border.all(color: MvColors.infoBoxBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MvIcon('shield', size: 22, color: MvColors.primaryDeep),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Finish setting up your business',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your supplier account is ready but has no business profile yet. '
                      'Add your business name and contact details so the MVEC team can '
                      'review you and your catalogue can go live.',
                      style: const TextStyle(fontSize: 12.5, color: MvColors.infoBoxText, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Set up business profile',
            icon: 'edit',
            expanded: true,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

/// Verification / status card. Shows where the supplier sits in the review
/// pipeline and what to do next.
class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.profileAsync, required this.onRetry});

  final AsyncValue<SupplierDetail?> profileAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (profileAsync) {
      // A null profile is the not-yet-onboarded state, not a failure. It needs
      // its own card with a button, because the plain InfoBox leaves the
      // supplier with no way forward from here.
      AsyncData(value: null) => _OnboardingCard(onPressed: () => context.go('/supplier/profile')),
      AsyncData(:final value?) => _card(context, value),
      AsyncLoading() => const InfoBox('Loading your verification status…', icon: 'shield'),
      AsyncError(:final error) => ErrorState(message: friendlyError(error), onRetry: onRetry),
      _ => const InfoBox('Loading your verification status…', icon: 'shield'),
    };
  }

  Widget _card(BuildContext context, SupplierDetail s) {
    final (label, message, action) = switch (s.verificationStatus?.toUpperCase()) {
      'VERIFIED' => (
          'Verified',
          'Your business is verified. You can list products and receive orders.',
          null,
        ),
      'PENDING' || 'UNDER_REVIEW' => (
          'In review',
          'Your documents are with the MVEC team. We will notify you once reviewed.',
          null,
        ),
      'REJECTED' => (
          'Rejected',
          'Your verification was rejected. Correct the details below and contact support to ask for a review.',
          'Update profile',
        ),
      _ => (
          'Action required',
          'Complete your business information and submit for verification to start selling.',
          'Set up profile',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MvColors.infoBoxBg,
        border: Border.all(color: MvColors.infoBoxBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MvIcon('shield', size: 22, color: MvColors.primaryDeep),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    StatusPill(status: s.verificationStatus, label: titleCase(s.effectiveStatus)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(fontSize: 12.5, color: MvColors.infoBoxText, height: 1.45)),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  GradientButton(
                    label: action,
                    icon: 'arrow',
                    onPressed: () => context.go('/supplier/profile'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
