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

  // Dokument s počítadlem objednávek: poslední přidělené číslo ("last")
  // a den, ke kterému patří ("day").
  DocumentReference<Map<String, dynamic>> get _counter =>
      db.collection('counters').doc('orders');

  // Dnešní den jako číslo, např. 16. 10. 2026 → 20261016.
  // Počítá se v čase UTC – stejně jako v pravidlech databáze, která
  // kontrolují den podle hodin serveru (čísla se tak nulují v 1:00 / 2:00).
  static int dayKey(DateTime time) {
    final utc = time.toUtc();
    return utc.year * 10000 + utc.month * 100 + utc.day;
  }

  // Další číslo objednávky: stejný den = o jedno víc, nový den = znovu 1.
  static int nextNumber(Map<String, dynamic>? counter, int today) {
    final lastDay = counter?['day'] as int?;
    final last = counter?['last'] as int? ?? 0;
    return lastDay == today ? last + 1 : 1;
  }

  // Uloží novou objednávku do databáze a vrátí její ID.
  Future<String> createOrder({
    required List<CartItem> items,
    required double totalPrice,
    required int tableNumber,
    required String tableCode,
    required String userId,
    required String customerName,
  }) async {
    final newOrder = _orders.doc();

    // Transakce: přečtení počítadla, jeho zvýšení a uložení objednávky
    // proběhne jako jeden celek. Když objednají dva zákazníci ve stejnou
    // chvíli, nedostanou stejné číslo objednávky.
    await db.runTransaction((transaction) async {
      final counter = await transaction.get(_counter);
      final today = dayKey(DateTime.now());
      final number = nextNumber(counter.data(), today);

      transaction.set(_counter, {'last': number, 'day': today});
      transaction.set(newOrder, {
        'number': number,
        'items': items.map((item) => item.toMap()).toList(),
        'totalPrice': totalPrice,
        'tableNumber': tableNumber,
        // Tajný kód stolu – ověří ho bezpečnostní pravidla, uložený zůstane jen
        // jako důkaz, že zákazník u stolu opravdu byl.
        'tableCode': tableCode,
        'status': OrderStatus.prijata.name,
        'userId': userId,
        'customerName': customerName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return newOrder.id;
  }

  // Seřadí objednávky podle času vytvoření (nejstarší první).
  // Podle čísla řadit nejde – čísla se každý den opakují.
  static List<Order> _sortByTime(List<Order> orders) {
    orders.sort((a, b) => a.time.compareTo(b.time));
    return orders;
  }

  // Živý proud všech objednávek, seřazených podle času.
  Stream<List<Order>> watchAllOrders() {
    return _orders.snapshots().map((snapshot) {
      return _sortByTime(snapshot.docs
          .map((doc) => Order.fromMap(doc.id, doc.data()))
          .toList());
    });
  }

  // Živý proud objednávek jednoho zákazníka, seřazených podle času.
  Stream<List<Order>> watchMyOrders(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => Order.fromMap(doc.id, doc.data()))
          .toList();
      // Řadíme až v aplikaci: kombinace where + orderBy by ve Firestore
      // vyžadovala zvláštní index.
      return _sortByTime(orders);
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
