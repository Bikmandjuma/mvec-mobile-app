import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils.dart';
import '../../../../widgets/common.dart';
import '../../../../widgets/mv_icon.dart';
import '../../data/models/affiliate_marketing.dart';
import '../../data/models/affiliate_profile.dart';
import '../providers/affiliate_providers.dart';
import '../widgets/affiliate_widgets.dart';

/// Product picker for generating referral links, mirroring the frontend
/// "promote products" experience: search, cards and a per-product link action
/// that copies the shareable deep link.
class AffiliateProductsScreen extends ConsumerStatefulWidget {
  const AffiliateProductsScreen({super.key});

  @override
  ConsumerState<AffiliateProductsScreen> createState() => _AffiliateProductsScreenState();
}

class _AffiliateProductsScreenState extends ConsumerState<AffiliateProductsScreen> {
  final _search = TextEditingController();
  String _q = '';
  String? _generatingId;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _q = _search.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _generate(PromotableProduct p) async {
    setState(() => _generatingId = p.id);
    try {
      final link = await ref.read(affiliateServiceProvider).generateLink(
            productId: p.id,
            label: 'Product: ${p.name}',
          );
      if (!mounted) return;
      ref.invalidate(affiliateLinksProvider);
      showMvSnack(context, 'Link created', success: true);
      await _showLink(link, p);
    } catch (e) {
      if (!mounted) return;
      showMvSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _generatingId = null);
    }
  }

  Future<void> _showLink(AffiliateLink link, PromotableProduct p) {
    return showMvDetailModal(
      context,
      title: p.name ?? 'Referral link created',
      children: [
        VerifiedBox('Your referral link', 'Anyone who opens this link and registers through it earns you commission.'),
        const SizedBox(height: 16),
        ReferralCodeCard(profile: AffiliateProfile(referralCode: link.code)),
        const SizedBox(height: 8),
        Text(
          'The link tracks clicks, registrations and purchases automatically.',
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(affiliateProductsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHead(eyebrow: 'Promotion', title: 'Promote Products', subtitle: 'Pick a product and get a trackable referral link to share.'),
        async.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(affiliateProductsProvider)),
          data: (products) {
            final list = products.where((p) => (p.name ?? '').toLowerCase().contains(_q)).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchBar(),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  const EmptyState(message: 'No matching products')
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (c, i) => _productCard(list[i]),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _searchBar() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: TextField(
        controller: _search,
        style: const TextStyle(fontSize: 13.5),
        decoration: const InputDecoration(
          labelText: 'Search products',
          hintText: 'Laptop, phone, shoes…',
          prefixIcon: MvIcon('search', size: 18),
        ),
      ),
    );
  }

  Widget _productCard(PromotableProduct p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final generating = _generatingId == p.id;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? MvColors.darkSurface2 : MvColors.surface2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: p.image == null
                ? Center(child: MvIcon('box', size: 28, color: isDark ? MvColors.darkMuted : MvColors.muted))
                : ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Image.network(p.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: MvIcon('box', size: 28, color: isDark ? MvColors.darkMuted : MvColors.muted))),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.name ?? 'Product', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      ),
                      if (p.rating != null && p.rating! > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const MvIcon('check', size: 12, color: MvColors.successText),
                            const SizedBox(width: 2),
                            Text(p.rating!.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: MvColors.successText)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(p.category ?? p.vendor ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                  const Spacer(),
                  Text(money(p.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'Manrope', color: MvColors.primaryDeep)),
                  const SizedBox(height: 10),
                  if (p.hasLink)
                    Row(
                      children: [
                        Expanded(
                          child: OutlineMvButton(label: 'Copy link', icon: 'copy', onPressed: () => _copyProduct(p)),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: GradientButton(
                            label: generating ? 'Creating…' : 'Generate link',
                            icon: 'plus',
                            expanded: true,
                            onPressed: generating ? null : () => _generate(p),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyProduct(PromotableProduct p) async {
    final code = p.referralCode;
    if (code == null || code.isEmpty) {
      await _generate(p);
      return;
    }
    copyToClipboard(context, affiliateLinkUrl(code));
  }
}