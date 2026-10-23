import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/menu_data.dart';
import '../models/menu_category.dart';
import '../models/product.dart';
import '../utils/streams.dart';
import '../utils/text.dart';
import 'category_service.dart';

// Služba, která se stará o produkty v databázi Firestore.
// Obrazovky se nemusí starat o to, JAK se data čtou – jen si řeknou o produkty.
class ProductService {
  final FirebaseFirestore db;
  final CategoryService categories;

  ProductService(this.db) : categories = CategoryService(db);

  // Kolekce "products" v databázi.
  CollectionReference<Map<String, dynamic>> get _products =>
      db.collection('products');

  // Proud (Stream) produktů: pokaždé, když se v databázi něco změní
  // (produkt nebo kategorie), pošle aplikaci nový seznam.
  //
  // Spojuje dvě kolekce – produkty a kategorie – podobně jako JOIN v SQL:
  // ke každému produktu dohledá podle categoryId název kategorie
  // a seřadí produkty podle pořadí kategorií a pak podle názvu.
  Stream<List<Product>> watchProducts() {
    return combineStreams(
      _products.snapshots(),
      categories.watchCategories(),
      _joinWithCategories,
    );
  }

  List<Product> _joinWithCategories(
    QuerySnapshot<Map<String, dynamic>> productDocs,
    List<MenuCategory> categoryList,
  ) {
    final categoriesById = {
      for (final category in categoryList) category.id: category,
    };
    final products = productDocs.docs.map((doc) {
      final category = categoriesById[doc.data()['categoryId']];
      return Product.fromMap(
        doc.data(),
        id: doc.id,
        categoryName: category?.name,
      );
    }).toList();

    // Pořadí kategorie; produkty bez platné kategorie jdou na konec.
    int rank(Product product) =>
        categoriesById[product.categoryId]?.order ?? 1 << 30;

    products.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      final byCategory = a.category.compareTo(b.category);
      if (byCategory != 0) return byCategory;
      return a.name.compareTo(b.name);
    });
    return products;
  }

  // ---------- Správa menu (jen admin – hlídají to pravidla databáze) ----------

  // Přidá nový produkt. Firestore mu sám vymyslí ID.
  Future<void> addProduct(Product product) {
    return _products.add(product.toMenuMap());
  }

  // Uloží změny existujícího produktu (podle jeho ID).
  Future<void> updateProduct(Product product) {
    return _products.doc(product.id).set(product.toMenuMap());
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

  // Hromadné nahrání produktů (z CSV souboru). Kategorie se v CSV píšou
  // názvem – které ještě neexistují, se založí.
  // Produkt se stejným názvem jako v menu se aktualizuje (cena, kategorie,
  // popis; dostupnost zůstane), ostatní se přidají jako nové.
  // Vrátí, kolik produktů se přidalo a kolik upravilo.
  Future<({int added, int updated})> importProducts(
    List<Product> products,
  ) async {
    final categoryIds = await categories.ensureCategories(
      products.map((product) => product.category),
    );

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
      final categoryId = categoryIds[normalizeText(product.category)]!;
      final id = idsByName[normalizeText(product.name)];
      if (id != null) {
        batch.update(_products.doc(id), {
          'name': product.name,
          'price': product.price,
          'categoryId': categoryId,
          'description': product.description,
        });
        updated++;
      } else {
        batch.set(_products.doc(), {
          'name': product.name,
          'price': product.price,
          'categoryId': categoryId,
          'description': product.description,
          'available': true,
        });
        added++;
      }
    }
    await batch.commit();
    return (added: added, updated: updated);
  }

  // ---------- Převod starých dat ----------
  // Dříve měl každý produkt kategorii uloženou jako text ("category": "Káva")
  // a pořadí kategorií bylo v nastavení podniku. Teď jsou kategorie
  // samostatná kolekce a produkty na ně odkazují přes categoryId.

  // Mají některé produkty ještě starý formát (bez categoryId)?
  static bool needsCategoryMigration(List<Product> products) =>
      products.any((product) => product.categoryId.isEmpty);

  // Převede staré produkty: založí kategorie (v pořadí z nastavení)
  // a u produktů nahradí text kategorie odkazem categoryId.
  // Vrátí, kolik produktů se převedlo.
  Future<int> migrateCategories() async {
    final productDocs = await _products.get();
    final oldProducts = productDocs.docs
        .where((doc) => (doc.data()['categoryId'] as String? ?? '').isEmpty)
        .toList();
    if (oldProducts.isEmpty) return 0;

    // Staré pořadí kategorií z nastavení podniku (pokud nějaké je).
    final settings =
        await db.collection('settings').doc('venue').get();
    final oldOrder = (settings.data()?['categoryOrder'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        <String>[];
    final names = [
      ...oldOrder,
      for (final doc in oldProducts)
        doc.data()['category'] as String? ?? 'Ostatní',
    ];
    final categoryIds = await categories.ensureCategories(names);

    final batch = db.batch();
    for (final doc in oldProducts) {
      final name = doc.data()['category'] as String? ?? 'Ostatní';
      batch.update(doc.reference, {
        'categoryId': categoryIds[normalizeText(name)],
        // Text kategorie už u produktu nepotřebujeme – smažeme ho.
        'category': FieldValue.delete(),
      });
    }
    await batch.commit();
    return oldProducts.length;
  }

  // Nahraje ukázkové menu (z menu_data.dart), ale jen když je databáze prázdná.
  // Vrátí true, když se menu nahrálo, a false, když už v databázi nějaké je.
  Future<bool> uploadSampleMenu() async {
    final existing = await _products.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return false;
    }
    await importProducts(sampleMenu);
    return true;
  }
}
