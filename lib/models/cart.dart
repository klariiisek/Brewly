import 'cart_item.dart';
import 'product.dart';

class Cart {
  final List<CartItem> items = [];

  // Stůl, u kterého zákazník sedí, a jeho tajný kód z QR kódu na stole.
  // Otazník (int?, String?) = zatím nevybraný (null).
  // Používá je objednávka i "Přivolat obsluhu" / "Chci zaplatit".
  int? tableNumber;
  String? tableCode;

  // Má zákazník stůl (z QR kódu nebo opsaného kódu)?
  bool get hasTable => tableNumber != null && tableCode != null;

  void setTable(int number, String code) {
    tableNumber = number;
    tableCode = code;
  }

  void clearTable() {
    tableNumber = null;
    tableCode = null;
  }

  // Odměna z razítkové karty: ID produktu, jehož jeden kus je zdarma.
  // null = zákazník odměnu neuplatnil.
  String? rewardProductId;

  // Položka, ze které je jeden kus zdarma.
  CartItem? get rewardItem {
    for (final item in items) {
      if (item.product.id == rewardProductId) return item;
    }
    return null;
  }

  // Kolik se odečte za odměnu (cena jednoho kusu).
  double get rewardDiscount => rewardItem?.product.price ?? 0;

  // Nejdražší objednatelný kus z kategorie razítkové karty
  // (ať se zákazníkovi odměna co nejvíc vyplatí). null = v košíku žádný není.
  CartItem? bestRewardItem(String categoryId) {
    CartItem? best;
    for (final item in items) {
      if (item.product.categoryId != categoryId || !item.canOrder) continue;
      if (best == null || item.product.price > best.product.price) best = item;
    }
    return best;
  }

  // Zákazník uplatní odměnu na nejdražší kus z kategorie karty.
  void useReward(String categoryId) {
    rewardProductId = bestRewardItem(categoryId)?.product.id;
  }

  void clearReward() {
    rewardProductId = null;
  }

  // Vyprázdní košík po odeslání objednávky (stůl zůstává).
  void clear() {
    items.clear();
    clearReward();
  }

  // Přidá položku. Stejný produkt (podle ID) se jen sečte s tím, co už
  // v košíku je.
  void addItem(CartItem item) {
    for (final existingItem in items) {
      if (isSameProduct(existingItem.product, item.product)) {
        existingItem.quantity += item.quantity;
        return;
      }
    }

    items.add(item);
  }

  // Je to stejný produkt? Podle ID; produkty bez ID (ukázková data) podle názvu.
  static bool isSameProduct(Product a, Product b) {
    if (a.id.isNotEmpty || b.id.isNotEmpty) return a.id == b.id;
    return a.name == b.name;
  }

  // Porovná košík s aktuálním menu z databáze: u každé položky použije
  // aktuální cenu a dostupnost. Když produkt v menu už není, označí ho.
  void syncWithMenu(List<Product> menu) {
    for (final item in items) {
      Product? current;
      for (final product in menu) {
        if (isSameProduct(item.product, product)) {
          current = product;
          break;
        }
      }
      item.isInMenu = current != null;
      if (current != null) {
        item.product = current;
      }
    }
    // Produkt s odměnou z košíku zmizel nebo se vyprodal → odměna se zruší.
    if (rewardProductId != null && !(rewardItem?.canOrder ?? false)) {
      clearReward();
    }
  }

  // Je v košíku něco, co už nejde objednat (vyprodané nebo smazané)?
  bool get hasUnavailableItems => items.any((item) => !item.canOrder);

  // Celkový počet kusů v košíku (např. 2× Espresso + 1× Latte = 3).
  int get itemCount {
    int count = 0;

    for (final item in items) {
      count += item.quantity;
    }

    return count;
  }

  // Cena všech položek (před odečtením odměny).
  double get subtotal {
    double total = 0;

    for (final item in items) {
      total += item.product.price * item.quantity;
    }

    return total;
  }

  // Kolik zákazník zaplatí (s odečtenou odměnou z razítkové karty).
  double get totalPrice => subtotal - rewardDiscount;
}
