// "hide Order": Firestore má vlastní třídu Order, my chceme používat tu naši.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/cart_item.dart';
import '../models/order.dart';

// Služba, která se stará o objednávky v databázi Firestore.
class OrderService {
  final FirebaseFirestore db;

  OrderService(this.db);

  // Kolekce "orders" v databázi.
  CollectionReference<Map<String, dynamic>> get _orders =>
      db.collection('orders');

  // Dokument s počítadlem objednávek (poslední přidělené číslo).
  DocumentReference<Map<String, dynamic>> get _counter =>
      db.collection('counters').doc('orders');

  // Uloží novou objednávku do databáze a vrátí její ID.
  Future<String> createOrder({
    required List<CartItem> items,
    required double totalPrice,
    required int tableNumber,
  }) async {
    final newOrder = _orders.doc();

    // Transakce: přečtení počítadla, jeho zvýšení a uložení objednávky
    // proběhne jako jeden celek. Když objednají dva zákazníci ve stejnou
    // chvíli, nedostanou stejné číslo objednávky.
    await db.runTransaction((transaction) async {
      final counter = await transaction.get(_counter);
      final number = (counter.data()?['last'] as int? ?? 0) + 1;

      transaction.set(_counter, {'last': number});
      transaction.set(newOrder, {
        'number': number,
        'items': items.map((item) => item.toMap()).toList(),
        'totalPrice': totalPrice,
        'tableNumber': tableNumber,
        'status': OrderStatus.prijata.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return newOrder.id;
  }

  // Živý proud všech objednávek, seřazených podle čísla (#1, #2, ...).
  Stream<List<Order>> watchAllOrders() {
    return _orders.orderBy('number').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Order.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Živý proud jedné objednávky (pro detail). Když neexistuje, pošle null.
  Stream<Order?> watchOrder(String id) {
    return _orders.doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return Order.fromMap(doc.id, data);
    });
  }

  // Posune objednávku na další stav (např. Přijata -> Připravuje se).
  Future<void> moveToNextStatus(Order order) {
    return _orders.doc(order.id).update({
      'status': nextOrderStatus(order.status).name,
    });
  }
}
