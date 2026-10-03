import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/app_theme.dart';
import '../../data/models/product_model.dart';
import '../providers/commerce_provider.dart';
import '../Screens/product_navigation.dart';

/// Reusable product card showing thumbnail, discount badge, rating,
/// name, brand, and the current/discounted price.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width = 160,
    this.priceTag = false,
  });

  final Product product;
  final VoidCallback onTap;

  /// Fixed card width; used inside horizontal scrolling rows.
  final double width;

  /// When true shows a prominent green price tag instead of plain text.
  final bool priceTag;

  @override
  Widget build(BuildContext context) {
    final detailProduct = toLegacyProduct(product);
    final isWishlisted = context.select<CommerceProvider, bool>(
      (commerce) => commerce.isWishlisted(detailProduct),
    );

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(product: product),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand != null && product.brand!.isNotEmpty)
                      Text(
                        product.brand!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context)
                            .copyWith(fontSize: 10, letterSpacing: 0.4),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title(context)
                          .copyWith(fontSize: 13, height: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.secondary,
                                size: 16,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  product.rating.toStringAsFixed(1),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption(context)
                                      .copyWith(color: context.mv.text),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '(${product.ratingCount})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: isWishlisted
                              ? 'Remove from wishlist'
                              : 'Add to wishlist',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 28,
                            height: 28,
                          ),
                          onPressed: () => context
                              .read<CommerceProvider>()
                              .toggleWishlist(detailProduct),
                          icon: Icon(
                            isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isWishlisted ? Colors.red : null,
                            size: 18,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Add to cart',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 28,
                            height: 28,
                          ),
                          onPressed: product.inStock
                              ? () => context
                                    .read<CommerceProvider>()
                                    .addToCart(detailProduct)
                              : null,
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            _formatPrice(product.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: priceTag
                                ? AppTextStyles.price(context).copyWith(
                                    color: AppColors.success,
                                    fontSize: 14,
                                  )
                                : AppTextStyles.price(context)
                                      .copyWith(fontSize: 14),
                          ),
                        ),
                        if (product.originalPrice != null) ...<Widget>[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _formatPrice(product.originalPrice!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.oldPrice(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatPrice(double value) => '\$${value.toStringAsFixed(2)}';
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final mv = context.mv;
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (product.imageUrl.isEmpty)
            Container(
              color: mv.soft,
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 28,
                color: mv.accentDeep,
              ),
            )
          else
            CachedNetworkImage(
              imageUrl: product.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, _) => ColoredBox(color: context.mv.soft),
              errorWidget:
                  (context, _, _) => Container(
                    color: mv.soft,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 28,
                      color: mv.accentDeep,
                    ),
                  ),
            ),
          if (product.discountPercent > 0)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-${product.discountPercent}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          if (!product.inStock)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                alignment: Alignment.center,
                child: const Text(
                  'Out of stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
