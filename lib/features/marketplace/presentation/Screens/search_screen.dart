import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/product_model.dart';
import '../providers/home_provider.dart';
import '../Widgets/product_card.dart';
import 'product_navigation.dart';

/// Search tab: free-text search across the full product catalog.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
    _query = widget.initialQuery;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Product> _filtered(List<Product> products) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products.where((product) {
      final haystack =
          [
            product.name,
            product.brand ?? '',
            product.categoryName ?? '',
            product.vendorName ?? '',
          ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final results = _filtered(provider.products);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _controller,
            autofocus: false,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search products, brands, vendors...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            _query.trim().isEmpty
                ? 'Browse the catalog'
                : '${results.length} result(s) for "$_query"',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child:
              results.isEmpty
                  ? const _EmptySearch()
                  : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                          context.read<HomeProvider>().addRecentlyViewed(
                            product,
                          );
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

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different keyword or browse the catalog.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
