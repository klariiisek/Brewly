import 'dart:convert';
import 'dart:typed_data';

import '../config/app_config.dart';
import '../models/product.dart';
import 'text.dart';

// Čtení menu ze souboru CSV (např. uloženého z Excelu).
//
// CSV = obyčejný text, kde každý řádek je jeden produkt a sloupce
// jsou oddělené středníkem (český Excel) nebo čárkou:
//   název;cena;kategorie;popis
//   Flat white;72;Káva;Espresso s jemným mléčným krémem

// Výsledek čtení: produkty v pořádku a seznam chyb (podle řádků).
class CsvImportResult {
  final List<Product> products;
  final List<String> errors;

  const CsvImportResult({required this.products, required this.errors});
}

// Převede bajty souboru na text. Vrátí null, když soubor není v kódování
// UTF-8 (Excel to umí: Uložit jako → "CSV UTF-8").
String? decodeCsvBytes(Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return null;
  }
}

// Přečte produkty z textu CSV a zkontroluje každý řádek.
CsvImportResult parseProductsCsv(String text) {
  final products = <Product>[];
  final errors = <String>[];
  final seenNames = <String>{};

  // Excel někdy na začátek souboru přidá neviditelný znak (BOM) – odstraníme ho.
  if (text.startsWith('﻿')) text = text.substring(1);

  final lines = text.split(RegExp(r'\r?\n'));

  // Oddělovač poznáme podle prvního řádku: středník, nebo čárka.
  final firstLine = lines.firstWhere(
    (line) => line.trim().isNotEmpty,
    orElse: () => '',
  );
  final separator = firstLine.contains(';') ? ';' : ',';

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineNumber = i + 1; // lidé počítají řádky od 1
    if (line.trim().isEmpty) continue;

    final cells = splitCsvLine(line, separator);

    // První řádek může být záhlaví ("název;cena;...") – ten přeskočíme.
    if (line == firstLine && isHeader(cells)) continue;

    final name = cells.isNotEmpty ? cells[0] : '';
    final priceText = cells.length > 1 ? cells[1] : '';
    final category = cells.length > 2 ? cells[2] : '';
    final description = cells.length > 3 ? cells[3] : '';

    if (name.isEmpty) {
      errors.add('Řádek $lineNumber: chybí název');
      continue;
    }
    final price = parseCsvPrice(priceText);
    if (price == null) {
      errors.add('Řádek $lineNumber ($name): cena "$priceText" není číslo');
      continue;
    }
    if (price <= 0 || price > AppConfig.maxProductPrice) {
      errors.add('Řádek $lineNumber ($name): cena musí být 1–10 000 Kč');
      continue;
    }
    if (category.isEmpty) {
      errors.add('Řádek $lineNumber ($name): chybí kategorie');
      continue;
    }
    if (!seenNames.add(normalizeText(name))) {
      errors.add('Řádek $lineNumber: $name je v souboru dvakrát');
      continue;
    }

    products.add(Product(
      name: name,
      price: price,
      category: category,
      description: description,
    ));
  }

  return CsvImportResult(products: products, errors: errors);
}

// Je řádek záhlaví? (První sloupec se jmenuje "název" nebo "name".)
bool isHeader(List<String> cells) {
  if (cells.isEmpty) return false;
  return ['nazev', 'name', 'produkt'].contains(normalizeText(cells[0]));
}

// "72", "72,50", "72.5", "72 Kč" → číslo. Jinak null.
double? parseCsvPrice(String text) {
  final cleaned = text
      .toLowerCase()
      .replaceAll('kč', '')
      .replaceAll(' ', '')
      .replaceAll(',', '.');
  return double.tryParse(cleaned);
}

// Rozdělí řádek na buňky podle oddělovače.
// Hlídá uvozovky: Excel dá text do uvozovek, když obsahuje oddělovač,
// např. "Espresso; silné" je jedna buňka. Dvojité "" uvnitř = jedna ".
List<String> splitCsvLine(String line, String separator) {
  final cells = <String>[];
  final current = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        current.write('"'); // "" uvnitř uvozovek
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == separator && !inQuotes) {
      cells.add(current.toString().trim());
      current.clear();
    } else {
      current.write(char);
    }
  }
  cells.add(current.toString().trim());
  return cells;
}
