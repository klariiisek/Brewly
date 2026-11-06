import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

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
  // Pořadové číslo objednávky (#1, #2, ...). Každý den začíná od 1,
  // slouží jen lidem ("dvanáctka je hotová"). Aplikace pozná objednávku podle id.
  final int number;
  final List<CartItem> items;
  final double totalPrice;
  final int tableNumber;
  final OrderStatus status;
  // Kdo objednávku vytvořil: ID účtu a jméno (jméno uvidí obsluha).
  final String userId;
  final String customerName;

  // Kdy byla objednávka vytvořena (čas serveru). Těsně po odeslání ho
  // databáze ještě nedoplnila – pak je null.
  final DateTime? createdAt;

  // Odměna z razítkové karty: který produkt byl zdarma a kolik se odečetlo.
  // Prázdné ID = objednávka bez odměny.
  final String rewardProductId;
  final double rewardDiscount;
  // Kolik razítek odměna stála (počet platný v době objednání).
  final int rewardStamps;

  const Order({
    required this.id,
    required this.number,
    required this.items,
    required this.totalPrice,
    required this.tableNumber,
    required this.status,
    required this.userId,
    required this.customerName,
    this.createdAt,
    this.rewardProductId = '',
    this.rewardDiscount = 0,
    this.rewardStamps = 0,
  });

  // Uplatnil zákazník v objednávce odměnu z razítkové karty?
  bool get hasReward => rewardProductId.isNotEmpty;

  // Položka, ze které byl jeden kus zdarma (null = žádná).
  CartItem? get rewardItem {
    if (!hasReward) return null;
    for (final item in items) {
      if (item.product.id == rewardProductId) return item;
    }
    return null;
  }

  // Cena všech položek před odečtením odměny.
  double get itemsTotal {
    var total = 0.0;
    for (final item in items) {
      total += item.product.price * item.quantity;
    }
    return total;
  }

  // Čas pro řazení a zobrazení. Bez času (právě odeslaná) = teď.
  DateTime get time => createdAt ?? DateTime.now();

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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      rewardProductId: data['rewardProductId'] as String? ?? '',
      rewardDiscount: (data['rewardDiscount'] as num? ?? 0).toDouble(),
      rewardStamps: data['rewardStamps'] as int? ?? 0,
    );
  }
}
