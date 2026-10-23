// Obsluha: objednávky, požadavky zákazníků, kódy stolů, kontrola cen.
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/models/cart_item.dart';
import 'package:brewly/models/product.dart';
import 'package:brewly/models/order.dart';
import 'package:brewly/models/service_request.dart';
import 'package:brewly/services/order_service.dart';
import 'package:brewly/services/request_service.dart';
import 'package:brewly/services/table_service.dart';
import 'package:brewly/screens/staff_screen.dart';

import 'helpers.dart';

void main() {
  testWidgets('Obsluha posune objednávku až do Dokončených',
      (WidgetTester tester) async {
    // Připraví databázi s jednou objednávkou ke stolu 5.
    final db = FakeFirebaseFirestore();
    await createTestOrder(OrderService(db), table: 5);
    // Testovací uživatelka má v profilu roli obsluha.
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    // Obsluha nevidí správu menu – ta je jen pro admina.
    expect(find.text('Správa menu'), findsNothing);
    await scrollAndTap(tester, find.text('Vstup pro obsluhu'));

    // První je záložka Požadavky – přepne na Aktivní.
    await tester.tap(find.text('Aktivní (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Stůl 5'), findsOneWidget);

    // Projde všechny stavy pomocí tlačítka na kartě.
    await tester.tap(find.text('Začít připravovat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Označit jako připravenou'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Předáno zákazníkovi'));
    await tester.pumpAndSettle();

    // Objednávka se přesunula do Dokončených.
    expect(find.text('Aktivní (0)'), findsOneWidget);
    expect(find.text('Dokončené (1)'), findsOneWidget);
    expect(find.text('Žádné aktivní objednávky'), findsOneWidget);
  });

  testWidgets('Zákazník přivolá obsluhu – nejdřív zadá kód stolu',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await pumpApp(tester, await buildTestApp(db: db));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objednávky').last);
    await tester.pumpAndSettle();

    // Stůl ještě není → aplikace se zeptá na kód stolu.
    await tester.tap(find.text('Přivolat obsluhu'));
    await tester.pumpAndSettle();
    expect(find.text('U kterého stolu sedíte?'), findsOneWidget);

    // Špatný tvar kódu → chyba u pole.
    await enterTableCode(tester, '7');
    expect(find.text('Kód má tvar číslo stolu, pomlčka a 6 znaků'),
        findsOneWidget);

    // Správný tvar → požadavek se odešle.
    await enterTableCode(tester, '7-K7P2X9');

    // Požadavek je v databázi i s kódem a tlačítko ukazuje, že se čeká.
    expect(find.text('Obsluha o vás ví…'), findsOneWidget);
    expect(find.text('Stůl 7'), findsOneWidget);
    final saved = await db.collection('requests').get();
    expect(saved.docs.single.data()['type'], 'obsluha');
    expect(saved.docs.single.data()['tableNumber'], 7);
    expect(saved.docs.single.data()['tableCode'], 'K7P2X9');
  });

  test('Kód stolu: čtení ručně opsaného kódu a odkaz v QR kódu', () {
    final parsed = parseShortTableCode(' 4-k7p2x9 ');
    expect(parsed?.number, 4);
    expect(parsed?.code, 'K7P2X9');
    expect(parseShortTableCode('11-K7P2X9'), isNull); // stůl 11 neexistuje
    expect(parseShortTableCode('4-K7P'), isNull); // krátký kód
    expect(tableLink(4, 'K7P2X9'),
        'https://brewly-9e944.web.app/?stul=4&kod=K7P2X9');
  });

  testWidgets('Obsluha vygeneruje kódy a uvidí QR kódy stolů',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Vstup pro obsluhu'));
    await tester.tap(find.byTooltip('Stoly a QR kódy'));
    await tester.pumpAndSettle();

    expect(find.text('Stoly zatím nemají kódy'), findsOneWidget);
    await tester.tap(find.text('Vygenerovat kódy'));
    await tester.pumpAndSettle();

    // V databázi je 10 stolů, každý s jiným šestiznakovým kódem.
    final tables = await db.collection('tables').get();
    expect(tables.docs.length, 10);
    final codes = tables.docs.map((doc) => doc.data()['code'] as String);
    expect(codes.toSet().length, 10);
    expect(codes.every((code) => code.length == 6), true);
    expect(find.text('Stůl 1'), findsOneWidget);
  });

  testWidgets('Obsluha vidí požadavek a vyřídí ho', (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});
    await RequestService(db).createRequest(
      type: RequestType.platba,
      tableNumber: 3,
      tableCode: 'ABCDEF',
      userId: 'host-1',
      customerName: 'Pavel',
    );

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Vstup pro obsluhu'));

    expect(find.text('Požadavky (1)'), findsOneWidget);
    expect(find.text('Stůl 3 • Chce zaplatit'), findsOneWidget);

    await tester.tap(find.text('Vyřízeno'));
    await tester.pumpAndSettle();

    expect(find.text('Požadavky (0)'), findsOneWidget);
    expect(find.text('Žádné požadavky'), findsOneWidget);
  });

  testWidgets('Obsluha přepne podnik na Zavřeno', (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Vstup pro obsluhu'));

    expect(find.text('Otevřeno'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Zavřeno'), findsOneWidget);
    final saved = (await db.collection('settings').doc('venue').get()).data()!;
    expect(saved, {'isOpen': false});
  });

  testWidgets('Zavřeno: obsluhu přivolat nejde, zaplatit ano',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('settings').doc('venue').set({'isOpen': false});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objednávky').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('obsluhu nejde přivolat'), findsOneWidget);
    ButtonStyleButton button(String label) => tester.widget<ButtonStyleButton>(
        find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)));
    expect(button('Přivolat obsluhu').onPressed, isNull);
    expect(button('Chci zaplatit').onPressed, isNotNull);
  });

  testWidgets('Obsluha vidí v Dokončených jen dnešní objednávky',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});
    final base = {
      'items': [],
      'totalPrice': 90,
      'tableNumber': 2,
      'status': 'dokoncena',
      'userId': 'host',
      'customerName': 'Pavel',
    };
    await db.collection('orders').add({
      ...base,
      'number': 5,
      'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1))),
    });
    await db.collection('orders').add({
      ...base,
      'number': 1,
      'createdAt': Timestamp.now(),
    });

    await pumpApp(tester, await buildTestApp(db: db));
    await scrollAndTap(tester, find.text('Vstup pro obsluhu'));

    expect(find.text('Dokončené (1)'), findsOneWidget);
  });

  test('Kontrola ceny objednávky najde nesedící cenu', () {
    const latte = Product(
        id: 'latte', name: 'Latte', price: 70, category: 'Káva', description: '');
    final order = Order(
      id: 'x',
      number: 1,
      items: [
        CartItem(
          product: const Product(
              id: 'latte',
              name: 'Latte',
              price: 1,
              category: 'Káva',
              description: ''),
          quantity: 2,
        ),
      ],
      totalPrice: 1,
      tableNumber: 1,
      status: OrderStatus.prijata,
      userId: 'host',
      customerName: 'Host',
    );

    final warnings = orderPriceWarnings(order, [latte]);
    expect(warnings.length, 2);
    expect(warnings.first, contains('položky dávají 2 Kč'));
    expect(warnings.last, contains('v menu 70 Kč'));

    // Správná objednávka je bez upozornění.
    final okOrder = Order(
      id: 'y',
      number: 2,
      items: [CartItem(product: latte, quantity: 2)],
      totalPrice: 140,
      tableNumber: 1,
      status: OrderStatus.prijata,
      userId: 'host',
      customerName: 'Host',
    );
    expect(orderPriceWarnings(okOrder, [latte]), isEmpty);
  });

  testWidgets('Obsluha uvidí upozornění u objednávky s podezřelou cenou',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});
    await db.collection('orders').add({
      'number': 1,
      'items': [
        {'name': 'Latte', 'price': 70, 'category': 'Káva', 'quantity': 2},
      ],
      'totalPrice': 1,
      'tableNumber': 3,
      'status': 'prijata',
      'userId': 'podvodnik',
      'customerName': 'Pavel',
      'createdAt': Timestamp.now(),
    });

    await pumpApp(tester, await buildTestApp(db: db));
    await scrollAndTap(tester, find.text('Vstup pro obsluhu'));
    await tester.tap(find.text('Aktivní (1)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('položky dávají 140 Kč'), findsOneWidget);
  });

  test('Obsluha načítá jen nedokončené a dnešní objednávky', () async {
    final db = FakeFirebaseFirestore();
    final yesterday = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 1)));
    final base = {
      'items': [],
      'totalPrice': 90,
      'tableNumber': 2,
      'userId': 'host',
      'customerName': 'Pavel',
    };
    // Včerejší dokončená – obsluha ji už nepotřebuje.
    await db.collection('orders').add(
        {...base, 'number': 4, 'status': 'dokoncena', 'createdAt': yesterday});
    // Včerejší nedokončená – tu obsluha vidět musí.
    await db.collection('orders').add(
        {...base, 'number': 9, 'status': 'pripravena', 'createdAt': yesterday});
    // Dnešní dokončená.
    await db.collection('orders').add({
      ...base,
      'number': 1,
      'status': 'dokoncena',
      'createdAt': Timestamp.now(),
    });

    final orders = await OrderService(db).watchStaffOrders().first;
    expect(orders.map((order) => order.number), [9, 1]);
  });
}
