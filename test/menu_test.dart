// Menu pro zákazníky: úvod, kategorie, detail produktu, vyprodané produkty.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/services/product_service.dart';
import 'package:brewly/utils/format.dart';
import 'package:brewly/widgets/product_card.dart';

import 'helpers.dart';

void main() {
  testWidgets('Úvodní obrazovka zobrazuje název a tlačítko menu',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp());

    // Ověří, že je vidět název kavárny a tlačítko pro menu.
    expect(find.text('Brewly'), findsOneWidget);
    expect(find.text('Prohlédnout menu'), findsOneWidget);
  });

  testWidgets('Prázdná databáze ukáže prázdné menu',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp(withMenu: false));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    expect(find.text('Menu je zatím prázdné'), findsOneWidget);
  });

  testWidgets('Hlavička menu se po přidání do košíku zmenší',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp());
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();
    expect(find.text('Co si dnes dáte?'), findsOneWidget);

    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pumpAndSettle();

    expect(find.text('Co si dnes dáte?'), findsNothing);
    expect(find.text('Menu ☕'), findsOneWidget);
  });

  testWidgets('Kategorie v menu filtrují produkty', (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp());
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
    await pumpApp(tester, await buildTestApp());
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
    // Plovoucí lišta košíku ukazuje počet a cenu.
    expect(find.text('3 položky · 210 Kč'), findsOneWidget);

    // V liště je u košíku číslo 3.
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('Vyprodaný produkt zákazník vidí, ale nemůže ho přidat',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Správa menu'));
    await tester.pumpAndSettle();

    // Admin přepne první produkt (Cappuccino) na vyprodaný.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    final cappuccino = await db
        .collection('products')
        .where('name', isEqualTo: 'Cappuccino')
        .get();
    expect(cappuccino.docs.single.data()['available'], false);

    // V menu pro zákazníky je označený a tlačítko + nejde zmáčknout.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Vyprodané Cappuccino je až na konci, první je teď Espresso.
    List<ProductCard> cards() =>
        tester.widgetList<ProductCard>(find.byType(ProductCard)).toList();
    String firstProductName() => cards().first.product.name;
    expect(firstProductName(), 'Espresso');

    // V kategorii Káva (vejde se celá na obrazovku) je Cappuccino poslední,
    // označené jako vyprodané a jeho tlačítko + nejde zmáčknout.
    await tester.tap(find.text('Káva'));
    await tester.pumpAndSettle();
    expect(cards().last.product.name, 'Cappuccino');
    expect(find.text('${formatPrice(65)} • Vyprodáno'), findsOneWidget);
    final addButton = tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add).last);
    expect(addButton.onPressed, isNull);

    // Když se Cappuccino zase prodává, vrátí se nahoru.
    await cappuccino.docs.single.reference.update({'available': true});
    await tester.pumpAndSettle();
    expect(firstProductName(), 'Cappuccino');
  });

  testWidgets('Menu řadí kategorie podle jejich pořadí',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await ProductService(db).uploadSampleMenu();
    // Nápoje dáme na první místo.
    await db
        .collection('categories')
        .doc(await categoryIdOf(db, 'Nápoje'))
        .update({'order': -1});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    final first =
        tester.widgetList<ProductCard>(find.byType(ProductCard)).first;
    expect(first.product.name, 'Domácí limonáda');
  });
}
