import 'cart_item.dart';
import 'address.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
}

class Order {
  final String id;
  final String orderNumber;
  final DateTime orderDate;
  final OrderStatus status;
  final List<CartItem> items;
  final Address deliveryAddress;
  final String paymentMethod;
  final double subtotal;
  final double shippingFee;
  final double serviceFee;
  final double tax;
  final double total;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;

  Order({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.status,
    required this.items,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.subtotal,
    required this.shippingFee,
    required this.serviceFee,
    required this.tax,
    required this.total,
    this.trackingNumber,
    this.estimatedDelivery,
  });
}