// Razítková karta: počítání razítek, odměna v košíku, kontrola u obsluhy.
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/models/cart.dart';
import 'package:brewly/models/cart_item.dart';
import 'package:brewly/models/loyalty.dart';
import 'package:brewly/models/order.dart';
import 'package:brewly/models/product.dart';

import 'helpers.dart';

// Objednávka v databázi: [kusů] z kategorie, ve stavu [status].
Map<String, dynamic> orderData({
  required String categoryId,
  required int quantity,
  String status = 'dokoncena',
  String productId = 'espresso',
  String rewardProductId = '',
  int rewardStamps = 0,
  int minutesAgo = 0,
}) {
  return {
    'number': 1,
    'items': [
      {
        'productId': productId,
        'name': 'Espresso',
        'price': 45,
        'categoryId': categoryId,
        'category': 'Káva',
        'description': '',
        'quantity': quantity,
      },
    ],
    'totalPrice': rewardProductId.isEmpty ? 45 * quantity : 45 * (quantity - 1),
    'tableNumber': 3,
    'tableCode': 'ABCDEF',
    'status': status,
    'userId': testUser.uid,
    'customerName': 'Klára',
    'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(minutes: minutesAgo))),
    if (rewardProductId.isNotEmpty) ...{
      'rewardProductId': rewardProductId,
      'rewardDiscount': 45,
      if (rewardStamps > 0) 'rewardStamps': rewardStamps,
    },
  };
}

// Zapne razítkovou kartu za kategorii Káva (10 razítek).
Future<String> enableLoyalty(FakeFirebaseFirestore db) async {
  final kavaId = await categoryIdOf(db, 'Káva');
  await db.collection('settings').doc('venue').set({
    'loyaltyEnabled': true,
    'loyaltyCategoryId': kavaId,
    'loyaltyGoal': 10,
  });
  return kavaId;
}

void main() {
  test('Razítka: jen dokončené objednávky a jen vybraná kategorie', () {
    Order order(Map<String, dynamic> data) => Order.fromMap('id', data);
    final orders = [
      order(orderData(categoryId: 'kava', quantity: 4)),
      order(orderData(categoryId: 'kava', quantity: 3, status: 'prijata')),
      order(orderData(categoryId: 'dezerty', quantity: 5)),
    ];
    final status = loyaltyStatus(orders, categoryId: 'kava', goal: 10);
    expect(status.stamps, 4);
    // Každá 10. káva zdarma = 9 razítek → chybí 5.
    expect(status.missing, 5);
    expect(status.hasReward, false);

    // 12 kusů → plná karta. Po odměně (2 kusy, jeden zdarma) zbude
    // 12 + 1 placený kus − 10 = 3 razítka.
    final full = [
      order(orderData(categoryId: 'kava', quantity: 12, minutesAgo: 10)),
    ];
    expect(loyaltyStatus(full, categoryId: 'kava', goal: 10).hasReward, true);
    final afterReward = [
      ...full,
      order(orderData(
        categoryId: 'kava',
        quantity: 2,
        rewardProductId: 'espresso',
        rewardStamps: 10,
      )),
    ];
    expect(loyaltyStatus(afterReward, categoryId: 'kava', goal: 10).stamps, 3);
  });

  test('Změna počtu razítek nepřepočítá staré odměny', () {
    Order order(Map<String, dynamic> data) => Order.fromMap('id', data);
    // Karta na 3 razítka: 4 kávy, pak odměna (stála 3 razítka),
    // pak další 2 kávy → 4 − 3 + 2 = 3 razítka.
    final orders = [
      order(orderData(categoryId: 'kava', quantity: 4, minutesAgo: 30)),
      order(orderData(
        categoryId: 'kava',
        quantity: 1,
        rewardProductId: 'espresso',
        rewardStamps: 3,
        minutesAgo: 20,
      )),
      order(orderData(categoryId: 'kava', quantity: 2, minutesAgo: 10)),
    ];
    // Admin pak změní kartu na 10 razítek – zákazník má pořád 3 (ne −4).
    final status = loyaltyStatus(orders, categoryId: 'kava', goal: 10);
    expect(status.stamps, 3);
    expect(status.filled, 3);
    expect(status.missing, 6);

    // Odměna bez uloženého počtu (starší data) kartu jen vynuluje.
    final old = [
      order(orderData(categoryId: 'kava', quantity: 5, minutesAgo: 30)),
      order(orderData(
        categoryId: 'kava',
        quantity: 1,
        rewardProductId: 'espresso',
        minutesAgo: 20,
      )),
      order(orderData(categoryId: 'kava', quantity: 2, minutesAgo: 10)),
    ];
    expect(loyaltyStatus(old, categoryId: 'kava', goal: 10).stamps, 2);
  });

  test('Obsluha: odměnu „neomluví“ nákupy až po ní', () {
    final reward = Order.fromMap(
        'odmena',
        orderData(
          categoryId: 'kava',
          quantity: 1,
          status: 'prijata',
          rewardProductId: 'espresso',
          rewardStamps: 10,
          minutesAgo: 20,
        ));
    final later = Order.fromMap(
        'pozdeji', orderData(categoryId: 'kava', quantity: 12, minutesAgo: 5));
    final earlier = Order.fromMap(
        'drive', orderData(categoryId: 'kava', quantity: 10, minutesAgo: 60));

    expect(
      isRewardValid([reward, later], reward, categoryId: 'kava', goal: 10),
      false,
    );
    expect(
      isRewardValid([earlier, reward], reward, categoryId: 'kava', goal: 10),
      true,
    );
  });

  test('Košík: odměna na nejdražší kus z kategorie a sleva v ceně', () {
    const espresso = Product(
        id: 'e', name: 'Espresso', price: 45, categoryId: 'kava',
        category: 'Káva', description: '');
    const latte = Product(
        id: 'l', name: 'Latte', price: 70, categoryId: 'kava',
        category: 'Káva', description: '');
    const cake = Product(
        id: 'c', name: 'Dort', price: 90, categoryId: 'dezerty',
        category: 'Dezerty', description: '');
    final cart = Cart()
      ..addItem(CartItem(product: espresso))
      ..addItem(CartItem(product: latte, quantity: 2))
      ..addItem(CartItem(product: cake));

    cart.useReward('kava');
    expect(cart.rewardItem?.product.name, 'Latte');
    expect(cart.subtotal, 275);
    expect(cart.totalPrice, 205);

    // Latte z košíku zmizí z menu → odměna se zruší.
    cart.syncWithMenu([espresso, cake]);
    expect(cart.rewardProductId, isNull);
  });

  testWidgets('Plná karta: zákazník uplatní odměnu a objedná zdarma',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    final app = await buildTestApp(db: db, cart: Cart()..setTable(3, 'ABCDEF'));
    final kavaId = await enableLoyalty(db);
    await db
        .collection('orders')
        .add(orderData(categoryId: kavaId, quantity: 10, minutesAgo: 60));

    // Stůl je nastavený (jako z QR kódu) → aplikace začne rovnou v menu.
    await pumpApp(tester, app);

    // Profil ukáže plnou kartu.
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('Razítková karta'), findsOneWidget);
    expect(find.text('9/9'), findsOneWidget);
    expect(find.textContaining('10. kus máte zdarma!'), findsOneWidget);

    // Do košíku přidá Cappuccino (první káva v menu).
    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Uplatnit odměnu: Cappuccino zdarma'));
    await tester.pumpAndSettle();
    expect(find.text('Cappuccino zdarma  −65 Kč'), findsOneWidget);
    expect(find.text('0 Kč'), findsOneWidget);

    await tester.tap(find.text('Objednat'));
    await tester.pumpAndSettle();
    expect(find.text('Odměna z razítkové karty'), findsOneWidget);

    final saved = await db
        .collection('orders')
        .where('status', isEqualTo: 'prijata')
        .get();
    final order = saved.docs.single.data();
    expect(order['totalPrice'], 0);
    expect(order['rewardDiscount'], 65);
    // Každá 10. káva zdarma → odměna stojí 9 razítek.
    expect(order['rewardStamps'], 9);
    expect(order['rewardProductId'], isNotEmpty);
  });

  testWidgets('Obsluha pozná odměnu bez plné karty',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    final app = await buildTestApp(db: db);
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});
    final kavaId = await enableLoyalty(db);
    // Zákazník poslal odměnu, ale žádná razítka nemá.
    await db.collection('orders').add(orderData(
          categoryId: kavaId,
          quantity: 1,
          status: 'prijata',
          rewardProductId: 'espresso',
        ));

    await pumpApp(tester, app);
    await scrollAndTap(tester, find.text('Objednávky'));
    await tester.tap(find.text('Aktivní (1)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('NEMÁ plnou kartu'), findsOneWidget);
  });
}
