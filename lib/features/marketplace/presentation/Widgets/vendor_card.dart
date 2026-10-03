import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/app_theme.dart';
import '../../data/models/vendor_model.dart';

/// Trusted vendor/store card with logo, verified badge, rating, and
/// product count. Sized for horizontal rows on the home feed.
class VendorCard extends StatelessWidget {
  const VendorCard({
    super.key,
    required this.vendor,
    required this.onTap,
    this.width = 170,
  });

  final Vendor vendor;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Logo(vendor: vendor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  vendor.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.title(context)
                                      .copyWith(fontSize: 14),
                                ),
                              ),
                              if (vendor.isVerified) ...<Widget>[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified_rounded,
                                  color: context.mv.accentDeep,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.secondary, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                vendor.rating.toStringAsFixed(1),
                                style: AppTextStyles.caption(context)
                                    .copyWith(color: context.mv.text),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  vendor.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${vendor.productCount} products · ${vendor.reviewCount} reviews',
                  style: AppTextStyles.caption(context).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final mv = context.mv;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: mv.soft,
        shape: BoxShape.circle,
        border: Border.all(color: mv.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: vendor.logoUrl.isEmpty
          ? Icon(Icons.storefront_outlined, color: mv.accentDeep, size: 24)
          : CachedNetworkImage(
              imageUrl: vendor.logoUrl,
              fit: BoxFit.cover,
              placeholder: (context, _) => const SizedBox.shrink(),
              errorWidget:
                  (context, _, _) => Icon(
                    Icons.storefront_outlined,
                    color: mv.accentDeep,
                    size: 24,
                  ),
            ),
    );
  }
}
