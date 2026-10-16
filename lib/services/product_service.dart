import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/menu_data.dart';
import '../models/product.dart';
import '../utils/text.dart';

// Služba, která se stará o produkty v databázi Firestore.
// Obrazovky se nemusí starat o to, JAK se data čtou – jen si řeknou o produkty.
class ProductService {
  final FirebaseFirestore db;

  ProductService(this.db);

  // Kolekce "products" v databázi.
  CollectionReference<Map<String, dynamic>> get _products =>
      db.collection('products');

  // Proud (Stream) produktů: pokaždé, když se v databázi něco změní,
  // pošle aplikaci nový seznam. Díky tomu se menu aktualizuje samo.
  Stream<List<Product>> watchProducts() {
    return _products.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), id: doc.id))
          .toList();

      // Seřadí produkty podle názvu. Pořadí kategorií určuje admin
      // v nastavení podniku (VenueSettings.sortProducts).
      products.sort((a, b) => a.name.compareTo(b.name));
      return products;
    });
  }

  // ---------- Správa menu (jen admin – hlídají to pravidla databáze) ----------

  // Data produktu pro uložení do menu (včetně dostupnosti).
  Map<String, dynamic> _menuData(Product product) {
    return {
      ...product.toMap(),
      'available': product.isAvailable,
    };
  }

  // Přidá nový produkt. Firestore mu sám vymyslí ID.
  Future<void> addProduct(Product product) {
    return _products.add(_menuData(product));
  }

  // Uloží změny existujícího produktu (podle jeho ID).
  Future<void> updateProduct(Product product) {
    return _products.doc(product.id).set(_menuData(product));
  }

  // Smaže produkt z menu. Staré objednávky to neovlivní,
  // protože mají údaje o produktu uložené u sebe.
  Future<void> deleteProduct(String id) {
    return _products.doc(id).delete();
  }

  // Rychlé přepnutí "vyprodáno" / "k dispozici".
  Future<void> setAvailable(String id, bool isAvailable) {
    return _products.doc(id).update({'available': isAvailable});
  }

  // Přejmenuje kategorii u všech jejích produktů najednou (batch).
  Future<void> renameCategory(String oldName, String newName) async {
    final products =
        await _products.where('category', isEqualTo: oldName).get();
    final batch = db.batch();
    for (final doc in products.docs) {
      batch.update(doc.reference, {'category': newName});
    }
    await batch.commit();
  }

  // Hromadné nahrání produktů (z CSV souboru).
  // Produkt se stejným názvem jako v menu se aktualizuje (cena, kategorie,
  // popis; dostupnost zůstane), ostatní se přidají jako nové.
  // Vrátí, kolik produktů se přidalo a kolik upravilo.
  Future<({int added, int updated})> importProducts(
    List<Product> products,
  ) async {
    // Současné menu: normalizovaný název → ID dokumentu.
    final existing = await _products.get();
    final idsByName = {
      for (final doc in existing.docs)
        normalizeText(doc.data()['name'] as String? ?? ''): doc.id,
    };

    var added = 0;
    var updated = 0;
    // Batch = všechny zápisy najednou (buď všechny, nebo žádný).
    // Firestore dovolí max. 500 zápisů v jednom batchi – na menu to stačí.
    final batch = db.batch();
    for (final product in products) {
      final id = idsByName[normalizeText(product.name)];
      if (id != null) {
        batch.update(_products.doc(id), product.toMap());
        updated++;
      } else {
        batch.set(_products.doc(), _menuData(product));
        added++;
      }
    }
    await batch.commit();
    return (added: added, updated: updated);
  }

  // Nahraje ukázkové menu (z menu_data.dart), ale jen když je databáze prázdná.
  // Vrátí true, když se menu nahrálo, a false, když už v databázi nějaké je.
  Future<bool> uploadSampleMenu() async {
    final existing = await _products.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return false;
    }

    // Batch = všechny zápisy se provedou najednou (buď všechny, nebo žádný).
    final batch = db.batch();
    for (final product in sampleMenu) {
      batch.set(_products.doc(), product.toMap());
    }
    await batch.commit();
    return true;
  }
}
