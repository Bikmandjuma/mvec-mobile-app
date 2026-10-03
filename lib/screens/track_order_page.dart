import 'package:flutter/material.dart';
import '../models/order.dart';

class TrackOrderPage extends StatelessWidget {
  final Order order;

  const TrackOrderPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Track Order',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== Order Header ==========
            _buildOrderHeader(context),
            const SizedBox(height: 24),

            // ========== Order Progress ==========
            _buildSectionTitle('Order Progress'),
            const SizedBox(height: 12),
            _buildOrderProgress(context),
            const SizedBox(height: 24),

            // ========== Delivery Status ==========
            _buildSectionTitle('Delivery Status'),
            const SizedBox(height: 12),
            _buildDeliveryStatus(context),
            const SizedBox(height: 24),

            // ========== Order Items ==========
            _buildSectionTitle('Order Items'),
            const SizedBox(height: 12),
            _buildOrderItems(),
            const SizedBox(height: 24),

            // ========== Delivery Address ==========
            _buildSectionTitle('Delivery Address'),
            const SizedBox(height: 12),
            _buildAddressCard(),
            const SizedBox(height: 24),

            // ========== Payment & Summary ==========
            _buildSectionTitle('Payment & Summary'),
            const SizedBox(height: 12),
            _buildPaymentSummary(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==================== ORDER HEADER ====================
  Widget _buildOrderHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _buildStatusChip(order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Placed on ${_formatDate(order.orderDate)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          if (order.trackingNumber != null) ...[
            const SizedBox(height: 6),
            Text(
              'Tracking: ${order.trackingNumber}',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== ORDER PROGRESS ====================
  Widget _buildOrderProgress(BuildContext context) {
    final steps = [
      {'title': 'Pending', 'status': OrderStatus.pending},
      {'title': 'Confirmed', 'status': OrderStatus.confirmed},
      {'title': 'Processing', 'status': OrderStatus.processing},
      {'title': 'Shipped', 'status': OrderStatus.shipped},
      {'title': 'Out for Delivery', 'status': OrderStatus.outForDelivery},
      {'title': 'Delivered', 'status': OrderStatus.delivered},
    ];

    int currentStep = steps.indexWhere((step) => step['status'] == order.status);
    if (order.status == OrderStatus.cancelled) currentStep = -1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final isCompleted = currentStep >= index;
          final isCurrent = currentStep == index;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle + Line
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  if (index != steps.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: isCompleted
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    steps[index]['title'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCompleted || isCurrent
                          ? Colors.black
                          : Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ==================== DELIVERY STATUS ====================
  Widget _buildDeliveryStatus(BuildContext context) {
    String message;
    IconData icon;
    Color color;

    switch (order.status) {
      case OrderStatus.pending:
        message = 'Your order is waiting for confirmation.';
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case OrderStatus.confirmed:
        message = 'Order confirmed. We are preparing your items.';
        icon = Icons.check_circle_outline;
        color = Colors.blue;
        break;
      case OrderStatus.processing:
        message = 'Your order is being processed by the vendor.';
        icon = Icons.inventory_2_outlined;
        color = Colors.blue;
        break;
      case OrderStatus.shipped:
        message = 'Your order has been shipped.';
        icon = Icons.local_shipping_outlined;
        color = Colors.deepPurple;
        break;
      case OrderStatus.outForDelivery:
        message = 'Your order is out for delivery. It will arrive soon!';
        icon = Icons.delivery_dining;
        color = Colors.green;
        break;
      case OrderStatus.delivered:
        message = 'Your order has been delivered successfully.';
        icon = Icons.home_outlined;
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        message = 'This order has been cancelled.';
        icon = Icons.cancel_outlined;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ORDER ITEMS ====================
  Widget _buildOrderItems() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: order.items.map((item) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.product.images.isNotEmpty
                      ? Image.network(
                          item.product.images.first,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: ${item.quantity}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== ADDRESS ====================
  Widget _buildAddressCard() {
    final address = order.deliveryAddress;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            address.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(address.phone, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text(
            '${address.addressLine}, ${address.city}, ${address.region}',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  // ==================== PAYMENT & SUMMARY ====================
  Widget _buildPaymentSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            context,
            'Payment Method',
            order.paymentMethod,
            isText: true,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(context, 'Subtotal', order.subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow(context, 'Shipping Fee', order.shippingFee),
          const SizedBox(height: 8),
          _buildSummaryRow(context, 'Service Fee', order.serviceFee),
          const SizedBox(height: 8),
          _buildSummaryRow(context, 'Tax', order.tax),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(),
          ),
          _buildSummaryRow(context, 'Total', order.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, dynamic value,
      {bool isTotal = false, bool isText = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          isText ? value.toString() : '\$${(value as double).toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 17 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal ? Theme.of(context).primaryColor : Colors.black,
          ),
        ),
      ],
    );
  }

  // ==================== HELPERS ====================
  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String text;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        text = 'Confirmed';
        break;
      case OrderStatus.processing:
        color = Colors.blue;
        text = 'Processing';
        break;
      case OrderStatus.shipped:
        color = Colors.deepPurple;
        text = 'Shipped';
        break;
      case OrderStatus.outForDelivery:
        color = Colors.green;
        text = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        text = 'Delivered';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 55,
      height: 55,
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 24, color: Colors.grey),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}