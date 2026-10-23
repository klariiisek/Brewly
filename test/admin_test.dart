// Admin: správa menu, kategorie, nahrání z CSV, převod starých dat.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/data/menu_data.dart';
import 'package:brewly/theme/app_theme.dart';
import 'package:brewly/theme/palettes.dart';
import 'package:brewly/services/product_service.dart';
import 'package:brewly/utils/csv_import.dart';

import 'helpers.dart';

void main() {
  testWidgets('Admin přidá do menu nový produkt', (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    // Admin vidí oba vstupy.
    expect(find.text('Vstup pro obsluhu'), findsOneWidget);
    await tester.tap(find.text('Správa menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Přidat produkt'));
    await tester.pumpAndSettle();

    // Prázdný formulář neprojde kontrolou.
    await tester.ensureVisible(find.text('Uložit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uložit'));
    await tester.pumpAndSettle();
    expect(find.text('Zadejte název'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Název'), 'Flat white');
    await tester.enterText(find.widgetWithText(TextFormField, 'Cena'), '72,5');
    // Kategorie kliknutím na štítek.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Káva'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Uložit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uložit'));
    await tester.pumpAndSettle();

    final saved = await db
        .collection('products')
        .where('name', isEqualTo: 'Flat white')
        .get();
    expect(saved.docs.single.data()['price'], 72.5);
    // Produkt odkazuje na kategorii přes její ID (cizí klíč).
    expect(saved.docs.single.data()['categoryId'],
        await categoryIdOf(db, 'Káva'));
    expect(saved.docs.single.data()['available'], true);
  });

  test('Hromadné nahrání: stejný název aktualizuje, nový přidá', () async {
    final db = FakeFirebaseFirestore();
    final productService = ProductService(db);
    await productService.uploadSampleMenu();
    // Latte je vyprodané – po nahrání má vyprodané zůstat.
    final latte = (await db
            .collection('products')
            .where('name', isEqualTo: 'Latte')
            .get())
        .docs
        .single
        .reference;
    await latte.update({'available': false});

    final counts = await productService.importProducts(
      parseProductsCsv('latte;75;Káva;Nový popis\nFlat white;72;Káva;').products,
    );

    expect(counts.added, 1);
    expect(counts.updated, 1);
    final updatedLatte = (await latte.get()).data()!;
    expect(updatedLatte['price'], 75);
    expect(updatedLatte['available'], false);
    final all = await db.collection('products').get();
    expect(all.docs.length, sampleMenu.length + 1);
  });

  testWidgets('Admin vyhledá produkt ve správě menu',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Správa menu'));
    await tester.pumpAndSettle();

    // "tira" najde Tiramisu, nic jiného.
    await tester.enterText(find.byType(TextField), 'tira');
    await tester.pumpAndSettle();
    expect(find.text('Tiramisu'), findsOneWidget);
    expect(find.text('Espresso'), findsNothing);

    // "napoje" bez diakritiky najde kategorii Nápoje.
    await tester.enterText(find.byType(TextField), 'napoje');
    await tester.pumpAndSettle();
    expect(find.text('Domácí limonáda'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'pizza');
    await tester.pumpAndSettle();
    expect(find.text('Nic nenalezeno'), findsOneWidget);

    // Křížek hledání zruší.
    await tester.tap(find.byTooltip('Zrušit hledání'));
    await tester.pumpAndSettle();
    expect(find.text('Espresso'), findsOneWidget);
  });

  testWidgets('Admin změní název, typ a barvu podniku',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nastavení podniku'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Název podniku'), 'Bar U Lípy');
    await tester.pumpAndSettle();
    // Náhled ukazuje nový název ještě před uložením (+ text v poli).
    expect(find.text('Bar U Lípy'), findsNWidgets(2));

    // Posune obrazovku dolů, dokud není prvek vidět, a klikne na něj.
    Future<void> scrollAndTap(Finder finder) async {
      await tester.scrollUntilVisible(finder, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await scrollAndTap(find.widgetWithText(ChoiceChip, 'Bar'));
    await scrollAndTap(find.byTooltip('Bordó'));
    await scrollAndTap(find.text('Uložit nastavení'));
    await tester.pumpAndSettle();

    final saved = (await db.collection('settings').doc('venue').get()).data()!;
    expect(saved['name'], 'Bar U Lípy');
    expect(saved['type'], 'bar');
    expect(saved['color'], 'bordo');

    // Zpět na úvod: nový název, ikona baru a celá aplikace v barvě bordó.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Bar U Lípy'), findsOneWidget);
    expect(find.text('powered by Brewly'), findsOneWidget);
    expect(find.byIcon(Icons.local_bar), findsOneWidget);
    final context = tester.element(find.text('Bar U Lípy'));
    expect(context.colors.primary, paletteFor('bordo').colors.primary);
  });

  testWidgets('Admin spravuje kategorie: přidá, přejmenuje, smaže',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Správa menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kategorie'));
    await tester.pumpAndSettle();

    expect(find.text('3 produkty'), findsOneWidget); // Káva
    expect(find.text('2 produkty'), findsOneWidget); // Dezerty

    // Přidá prázdnou kategorii Snídaně. Stejný název podruhé nejde.
    await tester.tap(find.text('Přidat kategorii'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'káva');
    await tester.tap(find.text('Přidat'));
    await tester.pumpAndSettle();
    expect(find.text('Taková kategorie už je'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Snídaně');
    await tester.tap(find.text('Přidat'));
    await tester.pumpAndSettle();
    expect(find.text('0 produktů'), findsOneWidget);
    expect(await categoryNames(db), ['Káva', 'Dezerty', 'Nápoje', 'Snídaně']);

    // Přejmenuje Dezerty na Sladké. Změní se jen dokument kategorie –
    // produkty na ni dál odkazují stejným ID.
    final dessertsId = await categoryIdOf(db, 'Dezerty');
    await tester.tap(find.byTooltip('Přejmenovat').at(1));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Sladké');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Přejmenovat'));
    await tester.pumpAndSettle();
    expect(await categoryIdOf(db, 'Sladké'), dessertsId);
    final sweets = await db
        .collection('products')
        .where('categoryId', isEqualTo: dessertsId)
        .get();
    expect(sweets.docs.length, 2);
    expect(await categoryNames(db), ['Káva', 'Sladké', 'Nápoje', 'Snídaně']);

    // Smazat jde jen prázdnou kategorii (Snídaně je poslední).
    await tester.tap(find.byTooltip('Smazat').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Smazat'));
    await tester.pumpAndSettle();
    expect(find.text('Snídaně'), findsNothing);
    expect(await categoryNames(db), ['Káva', 'Sladké', 'Nápoje']);
  });

  test('Převod starých produktů: kategorie z textu do kolekce', () async {
    final db = FakeFirebaseFirestore();
    // Starý formát: kategorie jako text, pořadí v nastavení podniku.
    await db.collection('settings').doc('venue').set({
      'categoryOrder': ['Dezerty', 'Káva'],
    });
    await db.collection('products').add(
        {'name': 'Latte', 'price': 70, 'category': 'Káva', 'description': ''});
    await db.collection('products').add(
        {'name': 'Dort', 'price': 80, 'category': 'Dezerty', 'description': ''});

    final productService = ProductService(db);
    expect(await productService.migrateCategories(), 2);

    expect(await categoryNames(db), ['Dezerty', 'Káva']);
    final latte = (await db
            .collection('products')
            .where('name', isEqualTo: 'Latte')
            .get())
        .docs
        .single
        .data();
    expect(latte['categoryId'], await categoryIdOf(db, 'Káva'));
    expect(latte.containsKey('category'), false);
    // Podruhé už není co převádět.
    expect(await productService.migrateCategories(), 0);

    // Menu spojí produkty s kategoriemi (jako JOIN) a seřadí je.
    final menu = await productService.watchProducts().first;
    expect(menu.map((p) => '${p.category}: ${p.name}'),
        ['Dezerty: Dort', 'Káva: Latte']);
  });
}
