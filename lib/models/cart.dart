import 'cart_item.dart';
import 'order_history.dart';

class Cart {
  final List<CartItem> items = [];
  final OrderHistory orderHistory = OrderHistory();

  void addItem(CartItem item) {
  for (final existingItem in items) {
    if (existingItem.product.name == item.product.name) {
      existingItem.quantity += item.quantity;
      return;
    }
  }

  items.add(item);
}

// Celkový počet kusů v košíku (např. 2× Espresso + 1× Latte = 3).
int get itemCount {
  int count = 0;

  for (final item in items) {
    count += item.quantity;
  }

  return count;
}

double get totalPrice {
  double total = 0;

  for (final item in items) {
    total += item.product.price * item.quantity;
  }

  return total;
}
}