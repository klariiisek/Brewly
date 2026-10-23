class Product {
  // ID dokumentu v databázi (potřebujeme ho, když admin produkt upravuje).
  // U produktů uložených v objednávce je prázdné.
  final String id;
  final String name;
  final double price;

  // Odkaz na kategorii (ID dokumentu v kolekci "categories") – cizí klíč.
  final String categoryId;

  // Název kategorie. V menu se doplní podle categoryId z kolekce kategorií,
  // v objednávce je uložený přímo (kopie z doby objednání).
  final String category;

  final String description;

  // Ikona vybraná adminem (např. "latte"). Prázdná = aplikace ji odhadne
  // podle názvu (viz drink_icon.dart).
  final String icon;

  // false = vyprodáno: zákazník produkt vidí, ale nemůže ho objednat.
  final bool isAvailable;

  const Product({
    this.id = '',
    required this.name,
    required this.price,
    this.categoryId = '',
    required this.category,
    required this.description,
    this.icon = '',
    this.isAvailable = true,
  });

  // Vytvoří produkt z dat načtených z databáze (Firestore).
  // Když nějaký údaj chybí, použije se náhradní hodnota, aby aplikace nespadla.
  // categoryName = název kategorie dohledaný podle categoryId (v menu).
  factory Product.fromMap(
    Map<String, dynamic> data, {
    String id = '',
    String? categoryName,
  }) {
    return Product(
      id: id,
      name: data['name'] as String? ?? 'Bez názvu',
      // V databázi může být cena celé číslo (45) i desetinné (45.5).
      price: (data['price'] as num? ?? 0).toDouble(),
      categoryId: data['categoryId'] as String? ?? '',
      category: categoryName ?? data['category'] as String? ?? 'Ostatní',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? '',
      isAvailable: data['available'] as bool? ?? true,
    );
  }

  // Údaje produktu pro uložení do objednávky (kopie včetně názvu kategorie,
  // aby se objednávka nezměnila, když admin později produkt upraví).
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'description': description,
    };
  }

  // Údaje produktu pro uložení do menu (kolekce "products"): kategorie
  // jen jako odkaz (categoryId), název kategorie je v kolekci "categories".
  Map<String, dynamic> toMenuMap() {
    return {
      'name': name,
      'price': price,
      'categoryId': categoryId,
      'description': description,
      'icon': icon,
      'available': isAvailable,
    };
  }
}
