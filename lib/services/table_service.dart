import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart.dart';

// Adresa zveřejněné aplikace – na ni vedou QR kódy na stolech.
const String appUrl = 'https://brewly-9e944.web.app';

// Odkaz, který je v QR kódu stolu, např. https://…/?stul=4&kod=K7P2X9
String tableLink(int tableNumber, String code) {
  return '$appUrl/?stul=$tableNumber&kod=$code';
}

// Krátký kód stolu pro ruční opsání, např. "4-K7P2X9".
String shortTableCode(int tableNumber, String code) => '$tableNumber-$code';

// Přečte ručně opsaný kód ve tvaru "4-K7P2X9". Vrátí číslo stolu a kód,
// nebo null, když text nemá správný tvar.
({int number, String code})? parseShortTableCode(String text) {
  final parts = text.trim().toUpperCase().split('-');
  if (parts.length != 2) return null;
  final number = int.tryParse(parts[0]);
  final code = parts[1];
  if (number == null || number < 1 || number > Cart.tableCount) return null;
  if (code.length != TableService.codeLength) return null;
  return (number: number, code: code);
}

// Služba pro tajné kódy stolů (kolekce "tables", dokumenty "1" až "10").
// Kódy může číst a měnit jen obsluha (hlídají to bezpečnostní pravidla).
class TableService {
  static const int codeLength = 6;
  // Bez snadno zaměnitelných znaků (0/O, 1/I/L), aby se kód dobře opisoval.
  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  final FirebaseFirestore db;

  TableService(this.db);

  CollectionReference<Map<String, dynamic>> get _tables =>
      db.collection('tables');

  // Živě: kódy všech stolů jako mapa {číslo stolu: kód}.
  Stream<Map<int, String>> watchCodes() {
    return _tables.snapshots().map((snapshot) {
      final codes = <int, String>{};
      for (final doc in snapshot.docs) {
        final number = int.tryParse(doc.id);
        final code = doc.data()['code'] as String?;
        if (number != null && code != null) codes[number] = code;
      }
      return codes;
    });
  }

  // Vygeneruje všem stolům nové náhodné kódy. Staré kódy přestanou platit.
  Future<void> regenerateCodes() {
    // Random.secure() = náhoda vhodná pro bezpečnostní účely (nedá se uhodnout).
    final random = Random.secure();
    final batch = db.batch();
    for (var number = 1; number <= Cart.tableCount; number++) {
      final code = List.generate(
        codeLength,
        (_) => _alphabet[random.nextInt(_alphabet.length)],
      ).join();
      batch.set(_tables.doc('$number'), {'code': code});
    }
    return batch.commit();
  }
}
