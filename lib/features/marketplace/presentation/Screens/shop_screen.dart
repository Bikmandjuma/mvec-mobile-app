import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/app_theme.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../providers/home_provider.dart';
import '../Widgets/product_card.dart';
import 'product_navigation.dart';

/// How the shop results are ordered.
enum SortOption {
  popular('Popular', Icons.trending_up),
  priceLowToHigh('Price: Low to High', Icons.arrow_upward),
  priceHighToLow('Price: High to Low', Icons.arrow_downward),
  rating('Top Rated', Icons.star_outline),
  newest('Newest', Icons.fiber_new_outlined);

  const SortOption(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Shop tab: browse, filter by category, and sort the product catalog.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.initialCategory});

  final Category? initialCategory;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _query = '';
  Category? _category;
  SortOption _sort = SortOption.popular;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  List<Product> _applyFilters(List<Product> products) {
    final term = _query.trim().toLowerCase();
    return products.where((product) {
      final matchesCategory =
          _category == null || product.categoryId == _category!.id;
      final matchesQuery =
          term.isEmpty ||
          [
            product.name,
            product.brand ?? '',
            product.vendorName ?? '',
          ].join(' ').toLowerCase().contains(term);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<Product> _sortProducts(List<Product> products) {
    final sorted = List<Product>.of(products);
    switch (_sort) {
      case SortOption.priceLowToHigh:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceHighToLow:
        sorted.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case SortOption.newest:
      case SortOption.popular:
        sorted.sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final categories = provider.categories;
    final results = _sortProducts(_applyFilters(provider.products));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('Shop', style: AppTextStyles.headline(context)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search in shop...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = index == 0 ? null : categories[index - 1];
              final selected = _category == category;
              return FilterChip(
                label: Text(category?.name ?? 'All'),
                selected: selected,
                onSelected: (_) => setState(() => _category = category),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${results.length} products',
                style: AppTextStyles.caption(context),
              ),
              DropdownButton<SortOption>(
                value: _sort,
                underline: const SizedBox.shrink(),
                onChanged: (value) =>
                    setState(() => _sort = value ?? SortOption.popular),
                items: SortOption.values
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Text(
                    'No products match your filters.',
                    style: AppTextStyles.bodySecondary(context),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) {
                    final product = results[index];
                    return ProductCard(
                      width: double.infinity,
                      product: product,
                      onTap: () {
                        context.read<HomeProvider>().addRecentlyViewed(product);
                        openProductDetails(context, product);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
