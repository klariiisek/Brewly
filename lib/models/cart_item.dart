import 'product.dart';

class CartItem {
  // Produkt není "final": košík ho nahradí aktuální verzí z menu,
  // když admin změní cenu nebo ho označí jako vyprodaný.
  Product product;
  int quantity;

  // false = produkt mezitím admin z menu smazal.
  bool isInMenu = true;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  // Dá se položka objednat? (Je v menu a není vyprodaná.)
  bool get canOrder => isInMenu && product.isAvailable;

  // Vytvoří položku z dat uložených v objednávce v databázi.
  factory CartItem.fromMap(Map<String, dynamic> data) {
    return CartItem(
      product: Product.fromMap(data, id: data['productId'] as String? ?? ''),
      quantity: data['quantity'] as int? ?? 1,
    );
  }

  // Převede položku na data pro uložení do objednávky v databázi.
  // Údaje o produktu se uloží přímo do objednávky, aby se objednávka
  // nezměnila, když se později změní cena v menu.
  Map<String, dynamic> toMap() {
    return {
      ...product.toMap(),
      // ID produktu v menu – obsluha podle něj porovná cenu s aktuálním menu.
      'productId': product.id,
      'quantity': quantity,
    };
  }
}
