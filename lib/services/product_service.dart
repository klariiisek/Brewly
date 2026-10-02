import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/menu_data.dart';
import '../models/product.dart';

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
          .map((doc) => Product.fromMap(doc.data()))
          .toList();

      // Seřadí produkty podle kategorie a pak podle názvu.
      products.sort((a, b) {
        final byCategory =
            _categoryRank(a.category).compareTo(_categoryRank(b.category));
        if (byCategory != 0) return byCategory;
        final byCategoryName = a.category.compareTo(b.category);
        if (byCategoryName != 0) return byCategoryName;
        return a.name.compareTo(b.name);
      });
      return products;
    });
  }

  // Pořadí kategorií v menu. Káva je v kavárně nejdůležitější, proto první.
  // Kategorie, které tu nejsou, se zařadí na konec.
  static const List<String> _categoryOrder = ['Káva', 'Dezerty', 'Nápoje'];

  int _categoryRank(String category) {
    final index = _categoryOrder.indexOf(category);
    return index == -1 ? _categoryOrder.length : index;
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
