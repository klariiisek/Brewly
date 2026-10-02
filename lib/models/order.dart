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

// Vrátí stav, který následuje po zadaném stavu.
OrderStatus nextOrderStatus(OrderStatus status) {
  switch (status) {
    case OrderStatus.prijata:
      return OrderStatus.pripravujeSe;
    case OrderStatus.pripravujeSe:
      return OrderStatus.pripravena;
    case OrderStatus.pripravena:
      return OrderStatus.dokoncena;
    case OrderStatus.dokoncena:
      // Dokončená objednávka už dál nepokračuje.
      return OrderStatus.dokoncena;
  }
}

class Order {
  // ID dokumentu v databázi (Firestore).
  final String id;
  // Pořadové číslo objednávky (#1, #2, ...), přiděluje ho databáze.
  final int number;
  final List<CartItem> items;
  final double totalPrice;
  final int tableNumber;
  final OrderStatus status;
  // Kdo objednávku vytvořil: ID účtu a jméno (jméno uvidí obsluha).
  final String userId;
  final String customerName;

  const Order({
    required this.id,
    required this.number,
    required this.items,
    required this.totalPrice,
    required this.tableNumber,
    required this.status,
    required this.userId,
    required this.customerName,
  });

  // Vytvoří objednávku z dat načtených z databáze.
  factory Order.fromMap(String id, Map<String, dynamic> data) {
    final itemsData = data['items'] as List<dynamic>? ?? [];

    return Order(
      id: id,
      number: data['number'] as int? ?? 0,
      items: itemsData
          .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalPrice: (data['totalPrice'] as num? ?? 0).toDouble(),
      tableNumber: data['tableNumber'] as int? ?? 0,
      // V databázi je stav uložený jako text, např. "pripravujeSe".
      status: OrderStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => OrderStatus.prijata,
      ),
      userId: data['userId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
    );
  }
}
