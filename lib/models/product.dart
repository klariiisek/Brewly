class Product {
  final String name;
  final double price;
  final String category;
  final String description;

  const Product({
    required this.name,
    required this.price,
    required this.category,
    required this.description,
  });

  // Vytvoří produkt z dat načtených z databáze (Firestore).
  // Když nějaký údaj chybí, použije se náhradní hodnota, aby aplikace nespadla.
  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      name: data['name'] as String? ?? 'Bez názvu',
      // V databázi může být cena celé číslo (45) i desetinné (45.5).
      price: (data['price'] as num? ?? 0).toDouble(),
      category: data['category'] as String? ?? 'Ostatní',
      description: data['description'] as String? ?? '',
    );
  }

  // Převede produkt na data pro uložení do databáze.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'description': description,
    };
  }
}
