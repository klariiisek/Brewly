// Košík a objednávky: objednání, čísla objednávek, hlídání změn v menu.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/models/cart.dart';
import 'package:brewly/models/cart_item.dart';
import 'package:brewly/models/product.dart';
import 'package:brewly/models/order.dart';
import 'package:brewly/services/order_service.dart';
import 'package:brewly/utils/format.dart';

import 'helpers.dart';

void main() {
  testWidgets('Prázdný košík ukáže tlačítko zpět do menu',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp());
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();
    expect(find.text('Košík je prázdný'), findsOneWidget);

    // Tlačítko vrátí zákazníka do menu.
    await tester.tap(find.text('Přejít do menu'));
    await tester.pumpAndSettle();
    expect(find.text('Co si dnes dáte?'), findsOneWidget);
  });

  testWidgets('Objednávka přes spodní lištu: menu → košík → objednávky',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp());

    // Otevře menu.
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Přidá první produkt (Cappuccino – káva je první, pak abecedně) tlačítkem +.
    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pumpAndSettle();

    // Číslo 1 u košíku ve spodní liště.
    expect(find.text('1'), findsWidgets);

    // Přepne na záložku Košík.
    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();
    expect(find.text('Cappuccino'), findsWidgets);

    // Stůl zatím nemá (neskenoval QR kód) → "Objednat" se zeptá na kód stolu.
    await tester.tap(find.text('Objednat'));
    await tester.pumpAndSettle();
    expect(find.text('U kterého stolu sedíte?'), findsOneWidget);
    await enterTableCode(tester, '3-abcdef');

    // Objednávka se odešle a aplikace rovnou otevře její sledování.
    expect(find.text('Objednávku jsme přijali'), findsOneWidget);
    expect(find.textContaining('Stůl 3 •'), findsOneWidget);

    // Zpět se zákazník dostane na seznam svých objednávek.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Moje objednávky'), findsOneWidget);
  });

  test('Objednávky dostanou pořadová čísla a jde měnit jejich stav', () async {
    final orderService = OrderService(FakeFirebaseFirestore());

    await createTestOrder(orderService, table: 1);
    await createTestOrder(orderService, table: 2);

    final orders = await orderService.watchStaffOrders().first;
    expect(orders.map((order) => order.number), [1, 2]);
    expect(orders.first.status, OrderStatus.prijata);
    expect(orders.first.items.first.quantity, 2);

    // Posune první objednávku na další stav.
    await orderService.moveToNextStatus(orders.first);
    final updated = await orderService.watchOrder(orders.first.id).first;
    expect(updated!.status, OrderStatus.pripravujeSe);

    // Objednávky se ukládají i s tím, kdo je vytvořil.
    final myOrders = await orderService.watchMyOrders(testUser.uid).first;
    expect(myOrders.length, 2);
    expect(myOrders.first.customerName, 'Klára');
    final otherOrders = await orderService.watchMyOrders('nekdo-jiny').first;
    expect(otherOrders, isEmpty);
  });

  testWidgets('Nepřihlášený zákazník musí se před objednáním přihlásit',
      (WidgetTester tester) async {
    // Zákazník přišel z QR kódu stolu 2 (stůl je v košíku už nastavený).
    final cart = Cart()..setTable(2, 'ABCDEF');
    // Z QR kódu se úvod přeskočí – aplikace otevře rovnou menu.
    await pumpApp(tester, await buildTestApp(signedIn: false, cart: cart));

    // Přidá produkt a přejde do košíku – stůl je tam z QR kódu.
    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();
    expect(find.text('Stůl 2'), findsOneWidget);

    // "Objednat" otevře přihlášení.
    await tester.tap(find.text('Objednat'));
    await tester.pumpAndSettle();
    expect(find.text('Přihlášení'), findsOneWidget);

    // Vyplní přihlášení a přihlásí se – objednávka se pak sama dokončí.
    await tester.enterText(find.byType(TextFormField).at(0), 'klara@test.cz');
    await tester.enterText(find.byType(TextFormField).at(1), 'tajneheslo');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Přihlásit se'));
    await tester.pumpAndSettle();

    expect(find.text('Objednávku jsme přijali'), findsOneWidget);
    expect(find.textContaining('Stůl 2 •'), findsOneWidget);
  });

  testWidgets('Košík hlídá změny v menu: cenu i vyprodání',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await pumpApp(tester, await buildTestApp(db: db));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Zákazník si dá do košíku Cappuccino (65 Kč) a otevře košík.
    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();

    // Admin mezitím zdraží Cappuccino na 80 Kč – košík se přepočítá.
    final cappuccino = (await db
            .collection('products')
            .where('name', isEqualTo: 'Cappuccino')
            .get())
        .docs
        .single
        .reference;
    await cappuccino.update({'price': 80});
    await tester.pumpAndSettle();
    expect(find.text(formatPrice(80)), findsWidgets);

    // Admin ho označí jako vyprodaný – objednat nejde, jen odebrat.
    await cappuccino.update({'available': false});
    await tester.pumpAndSettle();
    expect(find.text('Vyprodáno – odeberte z košíku'), findsOneWidget);
    final orderButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Objednat'));
    expect(orderButton.onPressed, isNull);

    await tester.tap(find.byTooltip('Odebrat'));
    await tester.pumpAndSettle();
    expect(find.text('Košík je prázdný'), findsOneWidget);
  });

  test('Čísla objednávek začínají každý den od 1', () async {
    expect(OrderService.dayKey(DateTime.utc(2026, 10, 16, 15)), 20261016);
    expect(OrderService.nextNumber(null, 20261016), 1);
    expect(OrderService.nextNumber({'last': 7, 'day': 20261016}, 20261016), 8);
    expect(OrderService.nextNumber({'last': 57, 'day': 20261015}, 20261016), 1);
    // Staré počítadlo bez dne (před touto změnou) = taky od 1.
    expect(OrderService.nextNumber({'last': 120}, 20261016), 1);

    // Včera skončili na #57 – dnešní první objednávka má #1, další #2.
    final db = FakeFirebaseFirestore();
    final yesterday = OrderService.dayKey(
        DateTime.now().subtract(const Duration(days: 1)));
    await db
        .collection('orderNumbers')
        .doc('today')
        .set({'last': 57, 'day': yesterday});
    final orderService = OrderService(db);
    final first = await createTestOrder(orderService);
    final second = await createTestOrder(orderService);
    expect((await db.collection('orders').doc(first).get()).data()!['number'], 1);
    expect((await db.collection('orders').doc(second).get()).data()!['number'], 2);
  });

  test('Košík slučuje stejné produkty podle ID, ne podle názvu', () {
    final cart = Cart();
    const latte1 = Product(
        id: 'a', name: 'Latte', price: 70, category: 'Káva', description: '');
    const latte2 = Product(
        id: 'b', name: 'Latte', price: 80, category: 'Káva', description: '');
    cart.addItem(CartItem(product: latte1));
    cart.addItem(CartItem(product: latte1));
    cart.addItem(CartItem(product: latte2));
    expect(cart.items.length, 2);
    expect(cart.items.first.quantity, 2);
  });

  testWidgets('Z QR kódu se otevře rovnou menu s číslem stolu',
      (WidgetTester tester) async {
    final cart = Cart()..setTable(4, 'K7P2X9');
    await pumpApp(tester, await buildTestApp(cart: cart));

    expect(find.text('Prohlédnout menu'), findsNothing);
    expect(find.text('Stůl 4 · Co si dnes dáte?'), findsOneWidget);
    // Menu je první obrazovka – šipka zpět není kam.
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('Plovoucí lišta v menu vede rovnou do košíku',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp());
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();
    expect(find.text('Do košíku'), findsNothing);

    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pumpAndSettle();
    expect(find.text('1 položka · 65 Kč'), findsOneWidget);

    await tester.tap(find.text('Do košíku'));
    await tester.pumpAndSettle();
    expect(find.text('Objednat'), findsOneWidget);
  });

  testWidgets('Když je objednávka připravená, zákazník dostane upozornění',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    final orderId = await createTestOrder(OrderService(db));
    await db.collection('orders').doc(orderId).update({'status': 'pripravujeSe'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Obsluha mezitím objednávku dodělá.
    await db.collection('orders').doc(orderId).update({'status': 'pripravena'});
    await tester.pumpAndSettle();
    expect(find.text('Vaše objednávka č. 1 je připravená!'), findsOneWidget);

    // "Zobrazit" otevře sledování objednávky.
    await tester.tap(find.text('Zobrazit'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hotovo!'), findsOneWidget);
  });
}