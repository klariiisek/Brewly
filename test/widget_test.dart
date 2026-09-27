import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewly/main.dart';
import 'package:brewly/models/cart.dart';
import 'package:brewly/utils/format.dart';

void main() {
  testWidgets('Úvodní obrazovka zobrazuje název a tlačítko menu',
      (WidgetTester tester) async {
    // Spustí aplikaci s novým (prázdným) košíkem.
    await tester.pumpWidget(MyApp(cart: Cart()));

    // Ověří, že je vidět název kavárny a tlačítko pro menu.
    expect(find.text('BREWLY'), findsOneWidget);
    expect(find.text('Prohlédnout menu'), findsOneWidget);
  });

  test('Správné skloňování počtu položek', () {
    expect(formatItemCount(1), '1 položka');
    expect(formatItemCount(3), '3 položky');
    expect(formatItemCount(5), '5 položek');
  });

  testWidgets('Prázdný košík ukáže tlačítko zpět do menu',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(cart: Cart()));
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
    await tester.pumpWidget(MyApp(cart: Cart()));
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
    await tester.pumpWidget(MyApp(cart: Cart()));
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
    await tester.pumpWidget(MyApp(cart: Cart()));

    // Otevře menu.
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Přidá první produkt (Espresso) tlačítkem +.
    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pump();
    // Počká, až zmizí hlášení "Přidáno: Espresso".
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Číslo 1 u košíku ve spodní liště.
    expect(find.text('1'), findsWidgets);

    // Přepne na záložku Košík.
    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();
    expect(find.text('Espresso'), findsWidgets);

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
}
