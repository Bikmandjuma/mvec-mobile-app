import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/app_theme.dart';
import '../providers/home_provider.dart';
import '../Widgets/product_card.dart';
import 'product_navigation.dart';

/// Deals tab: every discounted/promoted product in the catalog.
class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final deals = provider.deals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('Deals', style: AppTextStyles.headline(context)),
        ),
        Expanded(
          child: deals.isEmpty
              ? Center(
                  child: Text(
                    'No active deals right now.',
                    style: AppTextStyles.bodySecondary(context),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: deals.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) {
                    final product = deals[index];
                    return ProductCard(
                      width: double.infinity,
                      priceTag: true,
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
