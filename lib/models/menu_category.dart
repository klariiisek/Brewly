// Kategorie menu (např. Káva, Dezerty). V databázi je to kolekce
// "categories" a produkty na ni odkazují přes categoryId – podobně jako
// cizí klíč v relační databázi. Díky tomu je název kategorie uložený jen
// jednou: přejmenování = změna jednoho dokumentu, ne všech produktů.
//
// (Jmenuje se MenuCategory, protože "Category" už ve Flutteru existuje.)
class MenuCategory {
  final String id;
  final String name;

  // Pořadí v menu: 0 = první.
  final int order;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.order,
  });

  factory MenuCategory.fromMap(String id, Map<String, dynamic> data) {
    return MenuCategory(
      id: id,
      name: data['name'] as String? ?? 'Bez názvu',
      order: data['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'order': order,
    };
  }
}
