import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_category.dart';
import '../utils/text.dart';

// Služba pro kategorie menu (kolekce "categories").
// Číst je může každý, měnit jen admin (hlídají to pravidla databáze).
class CategoryService {
  final FirebaseFirestore db;

  CategoryService(this.db);

  CollectionReference<Map<String, dynamic>> get _categories =>
      db.collection('categories');

  // Seřadí kategorie podle pořadí (a stejné pořadí podle názvu).
  static List<MenuCategory> _sorted(List<MenuCategory> categories) {
    categories.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
    });
    return categories;
  }

  // Živý proud kategorií v pořadí, v jakém je uvidí zákazníci.
  Stream<List<MenuCategory>> watchCategories() {
    return _categories.snapshots().map((snapshot) => _sorted(snapshot.docs
        .map((doc) => MenuCategory.fromMap(doc.id, doc.data()))
        .toList()));
  }

  // Přidá kategorii na konec (order = počet dosavadních). Vrátí její ID.
  Future<String> addCategory(String name, {required int order}) async {
    final doc = await _categories.add({'name': name, 'order': order});
    return doc.id;
  }

  // Přejmenování = změna jediného dokumentu. Produkty se měnit nemusí,
  // protože odkazují na ID kategorie, ne na její název.
  Future<void> renameCategory(String id, String name) {
    return _categories.doc(id).update({'name': name});
  }

  Future<void> deleteCategory(String id) {
    return _categories.doc(id).delete();
  }

  // Uloží nové pořadí: každá kategorie dostane order podle místa v seznamu.
  Future<void> saveOrder(List<MenuCategory> categories) async {
    final batch = db.batch();
    for (var i = 0; i < categories.length; i++) {
      batch.update(_categories.doc(categories[i].id), {'order': i});
    }
    await batch.commit();
  }

  // Najde kategorie podle názvů a ty, které ještě nejsou, založí (na konec).
  // Vrátí mapu: normalizovaný název ("kava") → ID kategorie.
  // Používá se při nahrání z CSV a při převodu starých dat.
  Future<Map<String, String>> ensureCategories(Iterable<String> names) async {
    final existing = await _categories.get();
    final ids = <String, String>{};
    var nextOrder = 0;
    for (final doc in existing.docs) {
      final category = MenuCategory.fromMap(doc.id, doc.data());
      ids[normalizeText(category.name)] = category.id;
      if (category.order >= nextOrder) nextOrder = category.order + 1;
    }

    final batch = db.batch();
    var created = false;
    for (final name in names) {
      final key = normalizeText(name);
      if (key.isEmpty || ids.containsKey(key)) continue;
      final doc = _categories.doc();
      batch.set(doc, {'name': name.trim(), 'order': nextOrder++});
      ids[key] = doc.id;
      created = true;
    }
    if (created) await batch.commit();
    return ids;
  }
}
