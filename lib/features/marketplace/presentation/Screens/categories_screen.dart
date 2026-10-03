import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/app_theme.dart';
import '../../data/models/category_model.dart';
import '../providers/home_provider.dart';

/// All Categories tab: full grid of every marketplace category.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key, this.onCategoryTap});

  final ValueChanged<Category>? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final categories = provider.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('All Categories', style: AppTextStyles.headline(context)),
        ),
        Expanded(
          child: categories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryCard(
                      name: category.name,
                      count: category.productCount,
                      imageUrl: category.imageUrl,
                      onTap: () => onCategoryTap?.call(category),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.count,
    required this.imageUrl,
    required this.onTap,
  });

  final String name;
  final int count;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: imageUrl.isEmpty
                  ? Icon(
                    Icons.category_outlined,
                    color: context.mv.accentDeep,
                    size: 32,
                  )
                  : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, _) => const SizedBox.shrink(),
                    errorWidget:
                        (context, _, _) => Icon(
                          Icons.category_outlined,
                          color: context.mv.accentDeep,
                          size: 32,
                        ),
                  ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count products',
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
