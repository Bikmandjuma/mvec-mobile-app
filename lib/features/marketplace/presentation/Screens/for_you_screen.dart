import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/app_theme.dart';
import '../../data/models/product_model.dart';
import '../providers/home_provider.dart';
import '../Widgets/product_card.dart';
import 'product_navigation.dart';

/// For You tab: personalized recommendations plus products the user
/// recently viewed.
class ForYouScreen extends StatelessWidget {
  const ForYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final recommended = provider.recommendedProducts;
    final recent = provider.recentlyViewed;

    if (recommended.isEmpty && recent.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: context.mv.accentDeep,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                'Nothing personalized for you yet',
                style: AppTextStyles.title(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Open a few products to build your feed.',
                style: AppTextStyles.bodySecondary(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('For You', style: AppTextStyles.headline(context)),
        const SizedBox(height: 16),
        if (recent.isNotEmpty) ...<Widget>[
          _Header('Recently Viewed'),
          const SizedBox(height: 10),
          _Grid(products: recent),
          const SizedBox(height: 20),
        ],
        if (recommended.isNotEmpty) ...<Widget>[
          _Header('Recommended for You'),
          const SizedBox(height: 10),
          _Grid(products: recommended),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.sectionTitle(context));
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          width: double.infinity,
          product: product,
          onTap: () {
            context.read<HomeProvider>().addRecentlyViewed(product);
            openProductDetails(context, product);
          },
        );
      },
    );
  }
}
