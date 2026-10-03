import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/app_theme.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/vendor_model.dart';
import '../providers/home_provider.dart';
import '../Widgets/category_grid.dart';
import '../Widgets/product_card.dart';
import '../Widgets/vendor_card.dart';
import 'product_navigation.dart';
import 'vendor_store_screen.dart';

/// Marketplace home feed.
///
/// Renders the marketplace hero, category grid, featured products,
/// recommended products, and featured vendors from [HomeProvider].
/// Search lives in the shell's top bar, so it is not repeated here.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onBrowseAll,
    this.onViewDeals,
    this.onCategoryTap,
  });

  /// Switches the top navigation to the Shop tab (All Categories).
  final VoidCallback? onBrowseAll;
  final VoidCallback? onViewDeals;
  final ValueChanged<Category>? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    if (provider.isLoading && provider.feed.banners.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final categories = provider.categories;
    final visibleCategories =
        categories.length > 8 ? categories.sublist(0, 8) : categories;
    final featuredIds =
        provider.featuredProducts.map((product) => product.id).toSet();
    final popularProducts = <Product>[
      ...provider.featuredProducts,
      ...provider.products.where(
        (product) => !featuredIds.contains(product.id),
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.loadHomeFeed,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (provider.isDemo) const _DemoNotice(),
                _MarketplaceHero(
                  products: popularProducts,
                  onShopNow: onBrowseAll,
                  onViewDeals: onViewDeals,
                ),
                const SizedBox(height: 20),
                if (visibleCategories.isNotEmpty) ...<Widget>[
                  _SectionHeader(
                    title: 'Find what you need',
                    actionLabel: 'See all',
                    onAction: onBrowseAll,
                  ),
                  const SizedBox(height: 12),
                  CategoryGrid(
                    categories: visibleCategories,
                    onCategoryTap: _onCategoryTap,
                  ),
                  const SizedBox(height: 20),
                ],
                if (popularProducts.isNotEmpty) ...<Widget>[
                  _SectionHeader(title: 'Popular Products'),
                  const SizedBox(height: 12),
                  _ProductRow(products: popularProducts),
                  const SizedBox(height: 20),
                ],
                for (final category in visibleCategories)
                  if (provider.products.any(
                    (product) =>
                        product.categoryId == category.id ||
                        product.categoryName == category.name,
                  )) ...<Widget>[
                    _SectionHeader(title: category.name),
                    const SizedBox(height: 12),
                    _ProductRow(
                      products:
                          provider.products
                              .where(
                                (product) =>
                                    product.categoryId == category.id ||
                                    product.categoryName == category.name,
                              )
                              .take(4)
                              .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                if (provider.recommendedProducts.isNotEmpty) ...<Widget>[
                  _SectionHeader(title: 'Recommended For You'),
                  const SizedBox(height: 12),
                  _ProductRow(products: provider.recommendedProducts),
                  const SizedBox(height: 20),
                ],
                if (onViewDeals != null) ...<Widget>[
                  _DealsBanner(onTap: onViewDeals!),
                  const SizedBox(height: 20),
                ],
                if (provider.vendors.isNotEmpty) ...<Widget>[
                  _SectionHeader(title: 'Trusted Vendors'),
                  const SizedBox(height: 12),
                  _VendorRow(vendors: provider.vendors),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onCategoryTap(Category category) => onCategoryTap?.call(category);
}

class _MarketplaceHero extends StatelessWidget {
  const _MarketplaceHero({
    required this.products,
    required this.onShopNow,
    required this.onViewDeals,
  });

  final List<Product> products;
  final VoidCallback? onShopNow;
  final VoidCallback? onViewDeals;

  @override
  Widget build(BuildContext context) {
    final product = products.isEmpty ? null : products.first;
    final mv = context.mv;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            context.isDarkMode
                ? const Color(0xFF1E293B)
                : const Color(0xFFE9F9FD),
            context.isDarkMode
                ? const Color(0xFF263B4A)
                : const Color(0xFFC6EDF8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MVEC MARKETPLACE',
                      style: AppTextStyles.caption(context).copyWith(
                        color: mv.accentDeep,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Shop. Sell.\nGrow together.',
                      style: AppTextStyles.headline(context).copyWith(
                        fontSize: 25,
                        height: 1.04,
                        fontWeight: FontWeight.w600,
                        color: mv.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Products from trusted sellers across Rwanda.',
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        fontSize: 12,
                        height: 1.3,
                        color: mv.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 88,
                height: 112,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      product != null && product.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, _) => ColoredBox(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: mv.accentDeep,
                                  ),
                                ),
                            errorWidget:
                                (context, _, _) => ColoredBox(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: mv.accentDeep,
                                  ),
                                ),
                          )
                          : ColoredBox(
                            color: Colors.white.withValues(alpha: 0.7),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: mv.accentDeep,
                              size: 36,
                            ),
                          ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              FilledButton(onPressed: onShopNow, child: const Text('Shop now')),
              TextButton(onPressed: onViewDeals, child: const Text('Deals')),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Verified sellers  ·  Secure checkout  ·  Local delivery',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _DealsBanner extends StatelessWidget {
  const _DealsBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFE9F9FD), Color(0xFFC6EDF8)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MVEC DEAL DAYS',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'More products.\nLess searching.',
                  style: AppTextStyles.sectionTitle(
                    context,
                  ).copyWith(fontSize: 20, height: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Explore deals from verified sellers.',
                  style: AppTextStyles.bodySecondary(context),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: onTap,
                  child: const Text('Shop deals'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.local_offer_outlined,
            size: 58,
            color: AppColors.primaryDeep.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

/// Small notice shown when the feed is served from the mock service.
class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    final warning = AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: warning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are previewing demo data. Live products will appear when '
              'the marketplace API is connected.',
              style: TextStyle(color: warning, fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title row with an optional trailing action.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionTitle(context),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                color: context.mv.accentDeep,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

/// Horizontal scrolling list of products.
class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HomeProvider>();
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () {
              provider.addRecentlyViewed(product);
              openProductDetails(context, product);
            },
          );
        },
      ),
    );
  }
}

/// Horizontal scrolling list of featured vendors.
class _VendorRow extends StatelessWidget {
  const _VendorRow({required this.vendors});

  final List<Vendor> vendors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vendors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final vendor = vendors[index];
          return VendorCard(
            vendor: vendor,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => VendorStoreScreen(storeName: vendor.name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
