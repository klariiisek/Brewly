import 'cart_item.dart';

enum OrderStatus {
  prijata,
  pripravujeSe,
  pripravena,
  dokoncena,
}

String orderStatusText(OrderStatus status) {
  switch (status) {
    case OrderStatus.prijata:
      return 'Přijata';
    case OrderStatus.pripravujeSe:
      return 'Připravuje se';
    case OrderStatus.pripravena:
      return 'Připravena';
    case OrderStatus.dokoncena:
      return 'Dokončena';
  }
}

class Order {
  final List<CartItem> items;
  final double totalPrice;
  OrderStatus status;

  Order({
    required this.items,
    required this.totalPrice,
    required this.status,
  });
}