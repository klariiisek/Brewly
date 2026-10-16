class Product {
  // ID dokumentu v databázi (potřebujeme ho, když admin produkt upravuje).
  // U produktů uložených v objednávce je prázdné.
  final String id;
  final String name;
  final double price;
  final String category;
  final String description;

  // false = vyprodáno: zákazník produkt vidí, ale nemůže ho objednat.
  final bool isAvailable;

  const Product({
    this.id = '',
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    this.isAvailable = true,
  });

  // Vytvoří produkt z dat načtených z databáze (Firestore).
  // Když nějaký údaj chybí, použije se náhradní hodnota, aby aplikace nespadla.
  factory Product.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return Product(
      id: id,
      name: data['name'] as String? ?? 'Bez názvu',
      // V databázi může být cena celé číslo (45) i desetinné (45.5).
      price: (data['price'] as num? ?? 0).toDouble(),
      category: data['category'] as String? ?? 'Ostatní',
      description: data['description'] as String? ?? '',
      isAvailable: data['available'] as bool? ?? true,
    );
  }

  // Převede produkt na data pro uložení do databáze.
  // (Dostupnost sem nepatří – ta se ukládá jen v menu, ne v objednávkách.)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'description': description,
    };
  }
}
