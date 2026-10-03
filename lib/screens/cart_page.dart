import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils/app_theme.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'product_detail_page.dart';

class CartPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(CartItem) onUpdateQuantity;
  final Function(CartItem) onRemoveItem;
  final VoidCallback onProceedToCheckout;
  final bool Function(Product)? isWishlisted;
  final ValueChanged<Product>? onToggleWishlist;
  final VoidCallback? onOpenWishlist;
  final ValueChanged<Product>? onAddToCart;
  final VoidCallback? onOpenCart;

  const CartPage({
    super.key,
    required this.cartItems,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    required this.onProceedToCheckout,
    this.isWishlisted,
    this.onToggleWishlist,
    this.onOpenWishlist,
    this.onAddToCart,
    this.onOpenCart,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // ========== Fees (you can change these later) ==========
  final double shippingFee = 5.00;
  final double serviceFee = 2.50;
  final double taxRate = 0.08; // 8%

  double get subtotal {
    return widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get tax {
    return subtotal * taxRate;
  }

  double get total {
    return subtotal + shippingFee + serviceFee + tax;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.mv.page,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: widget.cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.cartItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildCartItem(widget.cartItems[index]);
                    },
                  ),
                ),

                // Summary + Checkout
                _buildOrderSummary(),
              ],
            ),
    );
  }

  // ==================== EMPTY CART ====================
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: context.mv.accentDeep,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.mv.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products to your cart to continue shopping',
            style: TextStyle(color: context.mv.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== CART ITEM ====================
  Widget _buildCartItem(CartItem item) {
    final product = item.product;

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
          // Product Info
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(
                    product: product,
                    isWishlisted: widget.isWishlisted?.call(product) ?? false,
                    onToggleWishlist: widget.onToggleWishlist,
                    onOpenWishlist: widget.onOpenWishlist,
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
                  // Image
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

                  // Remove Button
                  IconButton(
                    tooltip: 'Remove from cart',
                    onPressed: () => _confirmRemoveItem(item),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Quantity Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Quantity',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: mv.text,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: mv.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: item.quantity > 1
                            ? () {
                                setState(() {
                                  item.quantity--;
                                });
                                widget.onUpdateQuantity(item);
                              }
                            : null,
                      ),
                      Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: mv.text,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: item.quantity < product.stock
                            ? () {
                                setState(() {
                                  item.quantity++;
                                });
                                widget.onUpdateQuantity(item);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveItem(CartItem item) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove product?'),
        content: Text(
          'Are you sure you want to delete ${item.product.name} from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldRemove != true || !mounted) {
      return;
    }

    widget.onRemoveItem(item);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item removed from cart'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ==================== ORDER SUMMARY ====================
  Widget _buildOrderSummary() {
    final mv = context.mv;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: mv.surface,
        border: Border(top: BorderSide(color: mv.border)),
        boxShadow: [
          BoxShadow(
            color: mv.shadow,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSummaryRow('Subtotal', subtotal),
            const SizedBox(height: 8),
            _buildSummaryRow('Shipping Fee', shippingFee),
            const SizedBox(height: 8),
            _buildSummaryRow('Service Fee', serviceFee),
            const SizedBox(height: 8),
            _buildSummaryRow('Tax (8%)', tax),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            _buildSummaryRow('Total', total, isTotal: true),
            const SizedBox(height: 16),

            // Proceed to Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.cartItems.isEmpty
                    ? null
                    : widget.onProceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 17 : 15,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? context.mv.text : context.mv.textMuted,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal ? AppColors.primary : context.mv.text,
          ),
        ),
      ],
    );
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
