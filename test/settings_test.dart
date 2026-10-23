// Nastavení a provoz podniku: vzhled, otevřeno/zavřeno, informace.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/models/venue_settings.dart';
import 'package:brewly/config/palettes.dart';

import 'helpers.dart';

void main() {
  test('Nastavení podniku: výchozí hodnoty', () {
    final settings = VenueSettings.fromMap({
      'name': 'Bar U Lípy',
      'type': 'bar',
    });
    expect(settings.name, 'Bar U Lípy');
    expect(settings.type, VenueType.bar);
    // Co v databázi chybí, doplní se z výchozího nastavení.
    expect(settings.colorKey, 'kava');
    // Neznámá paleta = kávová.
    expect(paletteFor('neexistuje').key, 'kava');
  });

  testWidgets('Zavřeno: menu to ukáže a objednat nejde',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('settings').doc('venue').set({
      'isOpen': false,
      'announcement': 'Dnes −20 % na dezerty',
    });

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Teď máme zavřeno'), findsOneWidget);
    expect(find.text('Dnes −20 % na dezerty'), findsOneWidget);

    // Do košíku přidat jde, ale tlačítko Objednat je neaktivní.
    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();
    expect(find.text('Teď máme zavřeno, objednat zatím nejde.'), findsOneWidget);
    final orderButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Objednat'));
    expect(orderButton.onPressed, isNull);
  });

  testWidgets('Zákazník uvidí informace o podniku a heslo k Wi-Fi',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('settings').doc('venue').set({
      'address': 'Lipová 12, Praha',
      'wifiName': 'Brewly-host',
      'wifiPassword': 'kafe1234',
    });

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Informace o podniku'));
    await tester.pumpAndSettle();

    expect(find.text('Lipová 12, Praha'), findsOneWidget);
    expect(find.text('Heslo: kafe1234'), findsOneWidget);
    expect(find.text('● Teď máme otevřeno'), findsOneWidget);
  });

  test('Uložení nastavení nesmaže otevřeno ani informace', () {
    const settings = VenueSettings(
      name: 'Bistro',
      slogan: '',
      colorKey: 'kava',
      type: VenueType.restaurace,
      isOpen: false,
      wifiName: 'Bistro',
    );
    final changed = settings.copyWith(name: 'Bistro Na Rohu');
    expect(changed.isOpen, false);
    expect(changed.wifiName, 'Bistro');
    expect(VenueSettings.fromMap(changed.toMap()).name, 'Bistro Na Rohu');
  });
}
