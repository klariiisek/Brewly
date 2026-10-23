// Pomocné funkce: formátování, hledání, čtení CSV.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/data/menu_data.dart';
import 'package:brewly/services/product_service.dart';
import 'package:brewly/utils/csv_import.dart';
import 'package:brewly/utils/format.dart';
import 'package:brewly/utils/text.dart';


void main() {
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

  test('Hledání nezávisí na diakritice a velkých písmenech', () {
    expect(normalizeText('Káva'), 'kava');
    expect(normalizeText('  ŽLUŤOUČKÝ Kůň '), 'zlutoucky kun');
  });

  test('CSV: přečte produkty a najde chybné řádky', () {
    final result = parseProductsCsv(
      '﻿název;cena;kategorie;popis\r\n'
      'Flat white;72;Káva;Espresso s mlékem\r\n'
      'Brownies;65,50 Kč;Dezerty;"Čokoládový; s ořechy"\r\n'
      '\r\n'
      'Čaj;;Nápoje;Bez ceny\r\n'
      'Voda;20;;Bez kategorie\r\n'
      'flat WHITE;80;Káva;Podruhé\r\n'
      'Džus;35;Nápoje\r\n',
    );

    expect(result.products.map((p) => p.name),
        ['Flat white', 'Brownies', 'Džus']);
    expect(result.products[1].price, 65.5);
    // Středník v uvozovkách je součást popisu, ne oddělovač.
    expect(result.products[1].description, 'Čokoládový; s ořechy');
    // Popis není povinný.
    expect(result.products[2].description, '');
    expect(result.errors, [
      'Řádek 5 (Čaj): cena "" není číslo',
      'Řádek 6 (Voda): chybí kategorie',
      'Řádek 7: flat WHITE je v souboru dvakrát',
    ]);
  });

  test('CSV oddělené čárkou a bez záhlaví', () {
    final result = parseProductsCsv('Latte,70,Káva,"Jemná, mléčná"');
    expect(result.errors, isEmpty);
    expect(result.products.single.description, 'Jemná, mléčná');
  });
}
