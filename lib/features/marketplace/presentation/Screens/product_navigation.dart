import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../screens/cart_page.dart';
import '../../../../screens/checkout_page.dart';
import '../../../../screens/product_detail_page.dart';
import '../../../../screens/track_order_page.dart';
import '../../../../screens/wishlist_page.dart';
import '../../../../models/product.dart' as legacy;
import '../providers/commerce_provider.dart';
import '../../data/models/product_model.dart' as marketplace;

legacy.Product toLegacyProduct(marketplace.Product product) => legacy.Product(
  id: product.id.toString(),
  name: product.name,
  description: product.description,
  price: product.price,
  oldPrice: product.originalPrice,
  stock: product.stockQuantity,
  images: product.imageUrl.isEmpty ? const <String>[] : [product.imageUrl],
  colors: const <String>[],
  sizes: const <String>[],
  vendor: legacy.Vendor(
    id: product.vendorId?.toString() ?? '',
    name: product.vendorName ?? product.brand ?? 'Marketplace seller',
    logo: '',
    rating: product.rating,
    totalProducts: 0,
  ),
);

void openProductDetails(BuildContext context, marketplace.Product product) {
  final commerce = context.read<CommerceProvider>();
  final detailProduct = toLegacyProduct(product);

  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ProductDetailPage(
        product: detailProduct,
        isWishlisted: commerce.isWishlisted(detailProduct),
        onToggleWishlist: commerce.toggleWishlist,
        onOpenWishlist: () => openWishlist(context, commerce),
        onAddToCart: commerce.addToCart,
        onOpenCart: () => openCart(context, commerce),
      ),
      settings: const RouteSettings(name: '/product-detail'),
    ),
  );
}

void openWishlist(BuildContext context, CommerceProvider commerce) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => WishlistPage(
        wishlistItems: commerce.wishlistItems,
        onRemoveFromWishlist: commerce.removeFromWishlist,
        onMoveToCart: commerce.moveToCart,
        onToggleWishlist: commerce.toggleWishlist,
        onOpenCart: () => openCart(context, commerce),
        onAddToCart: commerce.addToCart,
        cartItemCount: () => commerce.cartItems.fold<int>(
          0,
          (count, item) => count + item.quantity,
        ),
      ),
    ),
  );
}

void openCart(BuildContext context, CommerceProvider commerce) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => CartPage(
        cartItems: commerce.cartItems,
        onUpdateQuantity: commerce.updateCartQuantity,
        onRemoveItem: commerce.removeCartItem,
        onProceedToCheckout: () => openCheckout(context, commerce),
        isWishlisted: commerce.isWishlisted,
        onToggleWishlist: commerce.toggleWishlist,
        onOpenWishlist: () => openWishlist(context, commerce),
        onAddToCart: commerce.addToCart,
        onOpenCart: () => openCart(context, commerce),
      ),
    ),
  );
}

void openCheckout(BuildContext context, CommerceProvider commerce) {
  const shippingFee = 5.0;
  const serviceFee = 2.5;
  final subtotal = commerce.cartItems.fold<double>(
    0,
    (sum, item) => sum + item.totalPrice,
  );
  final tax = subtotal * 0.08;
  final navigator = Navigator.of(context);

  navigator.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => CheckoutPage(
        cartItems: commerce.cartItems,
        subtotal: subtotal,
        shippingFee: shippingFee,
        serviceFee: serviceFee,
        tax: tax,
        total: subtotal + shippingFee + serviceFee + tax,
        onOrderPlaced: (order) {
          commerce.clearCart();
          navigator.pop();
          navigator.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => TrackOrderPage(order: order),
            ),
          );
        },
      ),
    ),
  );
}
