// Možnosti produktů: mléko, sirup… s příplatky.
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/models/cart.dart';
import 'package:brewly/models/cart_item.dart';
import 'package:brewly/models/product.dart';
import 'package:brewly/models/product_option.dart';

import 'helpers.dart';

const milk = OptionGroup(
  id: 'mleko',
  name: 'Mléko',
  choices: [
    OptionChoice(name: 'Kravské'),
    OptionChoice(name: 'Ovesné', price: 15),
  ],
);

const cappuccino = Product(
  id: 'cap',
  name: 'Cappuccino',
  price: 65,
  category: 'Káva',
  description: '',
);

// Do databáze přidá skupinu „Mléko“ a zapne ji u Cappuccina.
Future<void> addMilkToCappuccino(FakeFirebaseFirestore db) async {
  await db.collection('optionGroups').doc('mleko').set(milk.toMap());
  final products = await db
      .collection('products')
      .where('name', isEqualTo: 'Cappuccino')
      .get();
  await products.docs.single.reference.update({
    'optionGroupIds': ['mleko'],
  });
}

void main() {
  test('Výchozí volba zdarma se neukládá, ostatní ano i s příplatkem', () {
    expect(chosenOptions([milk], [0]), isEmpty);
    expect(chosenOptions([milk], [1]), [
      const ChosenOption(group: 'Mléko', choice: 'Ovesné', price: 15),
    ]);
  });

  test('Cena položky = produkt + příplatky; jiné mléko = jiná položka', () {
    const oat = ChosenOption(group: 'Mléko', choice: 'Ovesné', price: 15);
    final cart = Cart()
      ..addItem(CartItem(product: cappuccino, options: [oat]))
      ..addItem(CartItem(product: cappuccino, options: [oat]))
      ..addItem(CartItem(product: cappuccino));

    expect(cart.items.length, 2); // s ovesným (2 ks) a obyčejné (1 ks)
    expect(cart.items.first.quantity, 2);
    expect(cart.items.first.unitPrice, 80);
    expect(cart.items.first.optionsText, 'Mléko: Ovesné');
    expect(cart.subtotal, 80 * 2 + 65);

    // Uložení do objednávky a zpět: možnosti zůstanou.
    final saved = CartItem.fromMap(cart.items.first.toMap());
    expect(saved.options, [oat]);
    expect(saved.totalPrice, 160);
    // Bez možností se pole „options“ vůbec neukládá.
    expect(cart.items.last.toMap().containsKey('options'), false);
  });

  test('Odměna z karty: zdarma je základní cena, příplatek se platí', () {
    const oat = ChosenOption(group: 'Mléko', choice: 'Ovesné', price: 15);
    final cart = Cart()
      ..addItem(CartItem(
        product: cappuccino.copyWithCategory('kava'),
        options: [oat],
      ));
    cart.useReward('kava');
    expect(cart.rewardDiscount, 65);
    expect(cart.totalPrice, 15);
  });

  testWidgets('Zákazník si vybere ovesné mléko a objedná', (
    WidgetTester tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final cart = Cart()..setTable(2, 'ABCDEF');
    final app = await buildTestApp(db: db, cart: cart);
    await addMilkToCappuccino(db);
    await pumpApp(tester, app);

    // Detail Cappuccina: výběr mléka, cena se přepočítá.
    await tester.tap(find.text('Cappuccino'));
    await tester.pumpAndSettle();
    expect(find.text('Mléko'), findsOneWidget);
    expect(find.text('Přidat do košíku · 65 Kč'), findsOneWidget);
    await tester.tap(find.text('Ovesné +15 Kč'));
    await tester.pumpAndSettle();
    expect(find.text('Přidat do košíku · 80 Kč'), findsOneWidget);
    await tester.tap(find.text('Přidat do košíku · 80 Kč'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();
    expect(find.text('Mléko: Ovesné'), findsOneWidget);
    expect(find.text('80 Kč'), findsWidgets);

    await tester.tap(find.text('Objednat'));
    await tester.pumpAndSettle();

    final order = (await db.collection('orders').get()).docs.single.data();
    expect(order['totalPrice'], 80);
    final item = (order['items'] as List).single as Map;
    expect(item['price'], 65); // základní cena produktu
    expect(item['options'], [
      {'group': 'Mléko', 'choice': 'Ovesné', 'price': 15},
    ]);
    // Detail objednávky u zákazníka ukáže zvolené mléko.
    expect(find.text('Mléko: Ovesné'), findsOneWidget);
  });

  testWidgets('Obsluha vidí u objednávky zvolené mléko', (
    WidgetTester tester,
  ) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});
    await db.collection('orders').add({
      'number': 7,
      'status': 'prijata',
      'items': [
        {
          'productId': 'cap',
          'name': 'Cappuccino',
          'price': 65,
          'quantity': 2,
          'options': [
            {'group': 'Mléko', 'choice': 'Ovesné', 'price': 15},
          ],
        },
      ],
      'totalPrice': 160,
      'tableNumber': 3,
      'createdAt': Timestamp.now(),
    });

    await pumpApp(tester, await buildTestApp(db: db));
    await scrollAndTap(tester, find.text('Objednávky'));
    await tester.tap(find.textContaining('Aktivní'));
    await tester.pumpAndSettle();

    expect(find.text('2× Cappuccino'), findsOneWidget);
    expect(find.text('Mléko: Ovesné'), findsOneWidget);
    // Cena s příplatky sedí – žádné upozornění na nesedící cenu.
    expect(find.textContaining('Zkontrolujte cenu'), findsNothing);
  });

  testWidgets('Admin vytvoří skupinu „Mléko“ a zapne ji u produktu', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});
    await pumpApp(tester, await buildTestApp(db: db));

    await scrollAndTap(tester, find.text('Menu'));
    await tester.tap(find.byTooltip('Možnosti produktů'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Přidat skupinu'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Mléko');
    await tester.enterText(fields.at(1), 'Kravské');
    await tester.enterText(fields.at(3), 'Ovesné');
    await tester.enterText(fields.at(4), '15');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Uložit'));
    await tester.pumpAndSettle();

    final groups = (await db.collection('optionGroups').get()).docs;
    expect(groups.single.data(), milk.toMap());
    expect(find.text('Kravské · Ovesné +15 Kč'), findsOneWidget);

    // Zapnout u Cappuccina ve formuláři produktu.
    await goBack(tester);
    await tester.tap(find.text('Cappuccino'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.widgetWithText(FilterChip, 'Mléko'));
    await scrollAndTap(tester, find.widgetWithText(ElevatedButton, 'Uložit'));

    final products = await db
        .collection('products')
        .where('name', isEqualTo: 'Cappuccino')
        .get();
    expect(products.docs.single.data()['optionGroupIds'], [groups.single.id]);
  });
}

extension on Product {
  // Kopie produktu s kategorií (pro test razítkové karty).
  Product copyWithCategory(String categoryId) => Product(
        id: id,
        name: name,
        price: price,
        categoryId: categoryId,
        category: category,
        description: description,
      );
}
