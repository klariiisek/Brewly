import 'product.dart';
import 'product_option.dart';

class CartItem {
  // Produkt není "final": košík ho nahradí aktuální verzí z menu,
  // když admin změní cenu nebo ho označí jako vyprodaný.
  Product product;
  int quantity;

  // Co si zákazník vybral (např. ovesné mléko). Prázdné = vše výchozí.
  final List<ChosenOption> options;

  // false = produkt mezitím admin z menu smazal.
  bool isInMenu = true;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.options = const [],
  });

  // Cena jednoho kusu: cena produktu + příplatky za možnosti.
  double get unitPrice {
    var price = product.price;
    for (final option in options) {
      price += option.price;
    }
    return price;
  }

  // Cena všech kusů této položky.
  double get totalPrice => unitPrice * quantity;

  // Zvolené možnosti pro zákazníka i obsluhu: „Mléko: Ovesné · Sirup: Vanilka“.
  String get optionsText => options.map((option) => option.label).join(' · ');

  // Mají dvě položky stejné možnosti? (Cappuccino s ovesným a s kravským
  // mlékem jsou v košíku dvě různé položky.)
  bool hasSameOptions(CartItem other) {
    if (options.length != other.options.length) return false;
    for (var i = 0; i < options.length; i++) {
      if (options[i] != other.options[i]) return false;
    }
    return true;
  }

  // Dá se položka objednat? (Je v menu a není vyprodaná.)
  bool get canOrder => isInMenu && product.isAvailable;

  // Vytvoří položku z dat uložených v objednávce v databázi.
  factory CartItem.fromMap(Map<String, dynamic> data) {
    return CartItem(
      product: Product.fromMap(data, id: data['productId'] as String? ?? ''),
      quantity: data['quantity'] as int? ?? 1,
      options: [
        for (final option in data['options'] as List<dynamic>? ?? [])
          ChosenOption.fromMap(Map<String, dynamic>.from(option as Map)),
      ],
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
      // Jen když si zákazník něco vybral (starší objednávky pole nemají).
      if (options.isNotEmpty)
        'options': [for (final option in options) option.toMap()],
    };
  }
}
