import 'cart_item.dart';

class Cart {
  final List<CartItem> items = [];

  void addItem(CartItem item) {
  for (final existingItem in items) {
    if (existingItem.product.name == item.product.name) {
      existingItem.quantity++;
      return;
    }
  }

  items.add(item);
}

double get totalPrice {
  double total = 0;

  for (final item in items) {
    total += item.product.price * item.quantity;
  }

  return total;
}
}