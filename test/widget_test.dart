import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewly/main.dart';
import 'package:brewly/data/menu_data.dart';
import 'package:brewly/models/cart.dart';
import 'package:brewly/models/cart_item.dart';
import 'package:brewly/models/order.dart';
import 'package:brewly/services/order_service.dart';
import 'package:brewly/services/product_service.dart';
import 'package:brewly/utils/format.dart';

// Připraví aplikaci pro test s falešnou databází v paměti (místo skutečného Firebase).
// Když withMenu = true, nahraje do ní ukázkové menu.
// Když je zadaná db, použije se (aby test mohl předem vytvořit objednávky).
Future<Widget> buildTestApp({
  bool withMenu = true,
  FakeFirebaseFirestore? db,
}) async {
  final database = db ?? FakeFirebaseFirestore();
  final productService = ProductService(database);
  if (withMenu) {
    await productService.uploadSampleMenu();
  }
  return MyApp(
    cart: Cart(),
    productService: productService,
    orderService: OrderService(database),
  );
}

void main() {
  testWidgets('Úvodní obrazovka zobrazuje název a tlačítko menu',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp());

    // Ověří, že je vidět název kavárny a tlačítko pro menu.
    expect(find.text('Brewly'), findsOneWidget);
    expect(find.text('Prohlédnout menu'), findsOneWidget);
  });

  test('Správné skloňování počtu položek', () {
    expect(formatItemCount(1), '1 položka');
    expect(formatItemCount(3), '3 položky');
    expect(formatItemCount(5), '5 položek');
  });

  test('Ukázkové menu se nahraje do databáze jen jednou', () async {
    final db = FakeFirebaseFirestore();
    final productService = ProductService(db);

    expect(await productService.uploadSampleMenu(), true);
    // Podruhé už se nic nenahraje, protože menu v databázi je.
    expect(await productService.uploadSampleMenu(), false);

    final saved = await db.collection('products').get();
    expect(saved.docs.length, sampleMenu.length);
  });

  testWidgets('Prázdná databáze ukáže prázdné menu',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp(withMenu: false));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    expect(find.text('Menu je zatím prázdné'), findsOneWidget);
  });

  testWidgets('Prázdný košík ukáže tlačítko zpět do menu',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp());
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

  testWidgets('Kategorie v menu filtrují produkty', (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Klikne na štítek "Dezerty".
    await tester.tap(find.text('Dezerty'));
    await tester.pumpAndSettle();

    expect(find.text('Tiramisu'), findsOneWidget);
    expect(find.text('Espresso'), findsNothing);
  });

  testWidgets('Detail zespodu přidá vybrané množství do košíku',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Otevře detail Latte kliknutím na kartu.
    await tester.tap(find.text('Latte'));
    await tester.pumpAndSettle();

    // Zvýší množství na 3.
    await tester.tap(find.byTooltip('Zvýšit množství'));
    await tester.tap(find.byTooltip('Zvýšit množství'));
    await tester.pump();
    expect(find.text('Přidat do košíku · 210 Kč'), findsOneWidget);

    // Přidá do košíku, okno se zavře.
    await tester.tap(find.text('Přidat do košíku · 210 Kč'));
    await tester.pumpAndSettle();
    expect(find.text('Přidáno: 3× Latte'), findsOneWidget);

    // V liště je u košíku číslo 3.
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('Objednávka přes spodní lištu: menu → košík → objednávky',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp());

    // Otevře menu.
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Přidá první produkt (Cappuccino – káva je první, pak abecedně) tlačítkem +.
    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pump();
    // Počká, až zmizí hlášení "Přidáno: 1× Cappuccino".
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Číslo 1 u košíku ve spodní liště.
    expect(find.text('1'), findsWidgets);

    // Přepne na záložku Košík.
    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();
    expect(find.text('Cappuccino'), findsWidgets);

    // Vybere stůl 3.
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stůl 3').last);
    await tester.pumpAndSettle();

    // Objedná a aplikace sama přepne na objednávky.
    await tester.tap(find.text('Objednat'));
    await tester.pumpAndSettle();
    expect(find.text('Moje objednávky'), findsOneWidget);
    expect(find.textContaining('Stůl 3'), findsOneWidget);
  });

  test('Objednávky dostanou pořadová čísla a jde měnit jejich stav', () async {
    final orderService = OrderService(FakeFirebaseFirestore());
    final items = [CartItem(product: sampleMenu.first, quantity: 2)];

    await orderService.createOrder(
        items: items, totalPrice: 90, tableNumber: 1);
    await orderService.createOrder(
        items: items, totalPrice: 90, tableNumber: 2);

    final orders = await orderService.watchAllOrders().first;
    expect(orders.map((order) => order.number), [1, 2]);
    expect(orders.first.status, OrderStatus.prijata);
    expect(orders.first.items.first.quantity, 2);

    // Posune první objednávku na další stav.
    await orderService.moveToNextStatus(orders.first);
    final updated = await orderService.watchOrder(orders.first.id).first;
    expect(updated!.status, OrderStatus.pripravujeSe);
  });

  testWidgets('Obsluha posune objednávku až do Dokončených',
      (WidgetTester tester) async {
    // Připraví databázi s jednou objednávkou ke stolu 5.
    final db = FakeFirebaseFirestore();
    await OrderService(db).createOrder(
      items: [CartItem(product: sampleMenu.first, quantity: 2)],
      totalPrice: 90,
      tableNumber: 5,
    );

    await tester.pumpWidget(await buildTestApp(db: db));
    await tester.tap(find.text('Vstup pro obsluhu'));
    await tester.pumpAndSettle();

    expect(find.text('Aktivní (1)'), findsOneWidget);
    expect(find.text('Stůl 5'), findsOneWidget);

    // Projde všechny stavy pomocí tlačítka na kartě.
    await tester.tap(find.text('Začít připravovat'));
    await tester.pump();
    await tester.tap(find.text('Označit jako připravenou'));
    await tester.pump();
    await tester.tap(find.text('Předáno zákazníkovi'));
    await tester.pumpAndSettle();

    // Objednávka se přesunula do Dokončených.
    expect(find.text('Aktivní (0)'), findsOneWidget);
    expect(find.text('Dokončené (1)'), findsOneWidget);
    expect(find.text('Žádné aktivní objednávky'), findsOneWidget);
  });
}
