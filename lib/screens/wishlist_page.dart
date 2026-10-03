import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils/app_theme.dart';
import '../models/product.dart';
import 'product_detail_page.dart';

class WishlistPage extends StatefulWidget {
  final List<Product> wishlistItems;
  final Function(Product) onRemoveFromWishlist;
  final Function(Product) onMoveToCart;
  final ValueChanged<Product>? onToggleWishlist;
  final VoidCallback? onOpenCart;
  final ValueChanged<Product>? onAddToCart;

  /// Live cart size for the app-bar badge. A getter rather than an int so the
  /// count is read at build time and stays correct after "Move to Cart" (and
  /// after a product added from the detail page) without the caller having to
  /// rebuild this page.
  final int Function() cartItemCount;

  const WishlistPage({
    super.key,
    required this.wishlistItems,
    required this.onRemoveFromWishlist,
    required this.onMoveToCart,
    this.onToggleWishlist,
    this.onOpenCart,
    this.onAddToCart,
    this.cartItemCount = _noCartItems,
  });

  static int _noCartItems() => 0;

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  /// Total units in the cart, matching the count the bottom nav and home top
  /// bar use so the badge agrees everywhere.
  int get cartCount => widget.cartItemCount();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.mv.page,
      appBar: AppBar(
        title: const Text(
          'My Wishlist',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (widget.onOpenCart != null)
            IconButton(
              tooltip: 'Open cart',
              onPressed: widget.onOpenCart,
              icon: Badge(
                key: const ValueKey<String>('wishlist-cart-count'),
                isLabelVisible: cartCount > 0,
                backgroundColor: AppColors.error,
                textColor: Colors.white,
                label: Text(cartCount > 99 ? '99+' : '$cartCount'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
        ],
      ),
      body: widget.wishlistItems.isEmpty
          ? _buildEmptyWishlist()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.wishlistItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = widget.wishlistItems[index];
                return _buildWishlistItem(product);
              },
            ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: context.mv.accentDeep,
          ),
          const SizedBox(height: 16),
          Text(
            'Your wishlist is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.mv.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save products you love by tapping the heart icon',
            style: TextStyle(color: context.mv.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== WISHLIST ITEM ====================
  Widget _buildWishlistItem(Product product) {
    final mv = context.mv;
    return Container(
      decoration: BoxDecoration(
        color: mv.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: mv.border),
        boxShadow: [
          BoxShadow(
            color: mv.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Product Info (tappable)
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(
                    product: product,
                    isWishlisted: true,
                    onToggleWishlist: _toggleWishlistFromDetail,
                    onAddToCart: widget.onAddToCart,
                    onOpenCart: widget.onOpenCart,
                  ),
                ),
              );
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: product.images.isNotEmpty
                        ? Image.network(
                            product.images.first,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                  const SizedBox(width: 12),

                  // Name + Price + Vendor
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            color: mv.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.vendor.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: mv.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Remove from Wishlist
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      widget.onRemoveFromWishlist(product);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Removed from wishlist'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    label: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),

                // Move to Cart
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      widget.onMoveToCart(product);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} moved to cart'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Move to Cart',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleWishlistFromDetail(Product product) {
    widget.onToggleWishlist?.call(product);
    setState(() {});
  }

  Widget _imagePlaceholder() {
    final mv = context.mv;
    return Container(
      width: 90,
      height: 90,
      color: mv.soft,
      child: Icon(Icons.image, color: mv.textMuted),
    );
  }
}