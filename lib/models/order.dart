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

  void nextStatus() {
    switch (status) {
      case OrderStatus.prijata:
        status = OrderStatus.pripravujeSe;
        break;
      case OrderStatus.pripravujeSe:
        status = OrderStatus.pripravena;
        break;
      case OrderStatus.pripravena:
        status = OrderStatus.dokoncena;
        break;
      case OrderStatus.dokoncena:
        // Dokončená objednávka už dál nepokračuje.
        break;
    }
  }
}