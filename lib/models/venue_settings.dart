import 'package:flutter/material.dart';

import 'product.dart';

// Typ podniku – podle něj se mění ikona a emoji v aplikaci.
enum VenueType {
  kavarna('Kavárna', Icons.coffee, '☕'),
  cukrarna('Cukrárna', Icons.cake, '🧁'),
  bar('Bar', Icons.local_bar, '🍸'),
  pivnice('Pivnice', Icons.sports_bar, '🍺'),
  restaurace('Restaurace', Icons.restaurant, '🍽️');

  final String label;
  final IconData icon;
  final String emoji;

  const VenueType(this.label, this.icon, this.emoji);
}

// Nastavení podniku, které mění admin. V databázi je to jediný
// dokument settings/venue a celá aplikace ho živě poslouchá.
class VenueSettings {
  final String name; // název podniku, např. "Kavárna U Lípy"
  final String slogan; // krátký text na úvodní obrazovce
  final String colorKey; // klíč palety, např. "kava" (viz palettes.dart)
  final VenueType type;
  final List<String> categoryOrder; // pořadí kategorií v menu

  // Výchozí nastavení (než ho admin poprvé uloží) – kavárna Brewly.
  static const defaults = VenueSettings(
    name: 'Brewly',
    slogan: 'Vítejte v naší kavárně',
    colorKey: 'kava',
    type: VenueType.kavarna,
    categoryOrder: ['Káva', 'Dezerty', 'Nápoje'],
  );

  const VenueSettings({
    required this.name,
    required this.slogan,
    required this.colorKey,
    required this.type,
    required this.categoryOrder,
  });

  // Z dat v databázi. Co chybí, doplní se z výchozího nastavení.
  factory VenueSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return defaults;
    return VenueSettings(
      name: data['name'] as String? ?? defaults.name,
      slogan: data['slogan'] as String? ?? defaults.slogan,
      colorKey: data['color'] as String? ?? defaults.colorKey,
      type: VenueType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => defaults.type,
      ),
      categoryOrder: (data['categoryOrder'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          defaults.categoryOrder,
    );
  }

  // Kopie nastavení s jiným pořadím kategorií (ostatní zůstane stejné).
  VenueSettings withCategoryOrder(List<String> order) {
    return VenueSettings(
      name: name,
      slogan: slogan,
      colorKey: colorKey,
      type: type,
      categoryOrder: order,
    );
  }

  // Všechny kategorie: ty, které mají produkty, i ty, které admin
  // založil dopředu (jsou zatím jen v pořadí). Seřazené podle pořadí.
  List<String> allCategories(List<Product> products) {
    return sortCategories([
      ...categoryOrder,
      ...products.map((product) => product.category),
    ]);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slogan': slogan,
      'color': colorKey,
      'type': type.name,
      'categoryOrder': categoryOrder,
    };
  }

  // Seřadí kategorie podle nastaveného pořadí. Kategorie, které v pořadí
  // ještě nejsou (např. nově přidané), budou na konci podle abecedy.
  List<String> sortCategories(Iterable<String> categories) {
    int rank(String category) {
      final index = categoryOrder.indexOf(category);
      return index == -1 ? categoryOrder.length : index;
    }

    final sorted = categories.toSet().toList();
    sorted.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.compareTo(b);
    });
    return sorted;
  }

  // Seřadí produkty podle pořadí kategorií (uvnitř kategorie podle názvu).
  List<Product> sortProducts(List<Product> products) {
    final categories = sortCategories(products.map((p) => p.category));
    return [
      for (final category in categories)
        ...products.where((product) => product.category == category),
    ];
  }
}

// Zpřístupní nastavení podniku všem obrazovkám pod ní – podobně jako
// Theme.of(context). Obrazovka si ho vezme přes VenueScope.of(context)
// a když admin nastavení změní, Flutter ji sám překreslí.
class VenueScope extends InheritedWidget {
  final VenueSettings settings;

  const VenueScope({super.key, required this.settings, required super.child});

  static VenueSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<VenueScope>();
    return scope?.settings ?? VenueSettings.defaults;
  }

  @override
  bool updateShouldNotify(VenueScope oldWidget) =>
      settings != oldWidget.settings;
}
