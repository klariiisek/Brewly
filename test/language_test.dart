// Jazyky: zákaznická část česky i anglicky, přepínání tlačítkem.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/l10n/language.dart';

import 'helpers.dart';

void main() {
  test('Jazyk podle telefonu: čeština a slovenština česky, ostatní anglicky',
      () {
    expect(resolveLanguage(const Locale('cs', 'CZ')), const Locale('cs'));
    expect(resolveLanguage(const Locale('sk')), const Locale('cs'));
    expect(resolveLanguage(const Locale('de', 'DE')), const Locale('en'));
    expect(resolveLanguage(const Locale('en', 'US')), const Locale('en'));
    expect(resolveLanguage(null), const Locale('cs'));
  });

  testWidgets('Tlačítko English přepne zákaznickou část do angličtiny',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp());
    expect(find.text('Prohlédnout menu'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Browse the menu'), findsOneWidget);
    expect(find.text('Reserve a table'), findsOneWidget);

    // Menu: štítek „All“, tlačítko zpět na češtinu, produkty z databáze
    // zůstávají tak, jak je napsal admin.
    await tester.tap(find.text('Browse the menu'));
    await tester.pumpAndSettle();
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Espresso'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);

    // Množné číslo: „1 item“ v plovoucí liště košíku.
    await tester.tap(find.byTooltip('Add to cart').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 item'), findsOneWidget);

    // Zpět do češtiny.
    await tester.tap(find.text('Čeština'));
    await tester.pumpAndSettle();
    expect(find.text('Vše'), findsOneWidget);
    expect(find.textContaining('1 položka'), findsOneWidget);
  });

  testWidgets('České tvary podle čísla: 1 položka, 2 položky, 5 položek',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp());
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    final add = find.byTooltip('Přidat do košíku').first;
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 položka'), findsOneWidget);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.textContaining('2 položky'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(add);
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('5 položek'), findsOneWidget);
  });
}
