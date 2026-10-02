import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  // Vytvoří položku z dat uložených v objednávce v databázi.
  factory CartItem.fromMap(Map<String, dynamic> data) {
    return CartItem(
      product: Product.fromMap(data),
      quantity: data['quantity'] as int? ?? 1,
    );
  }

  // Převede položku na data pro uložení do objednávky v databázi.
  // Údaje o produktu se uloží přímo do objednávky, aby se objednávka
  // nezměnila, když se později změní cena v menu.
  Map<String, dynamic> toMap() {
    return {
      ...product.toMap(),
      'quantity': quantity,
    };
  }
}
