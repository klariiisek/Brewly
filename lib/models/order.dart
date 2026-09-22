import 'cart_item.dart';

class Order {
  final List<CartItem> items;
  final double totalPrice;

  Order({
    required this.items,
    required this.totalPrice,
  });
}