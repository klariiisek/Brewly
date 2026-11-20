import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_option.dart';

// Služba pro skupiny možností produktů (kolekce "optionGroups"),
// např. „Mléko“ nebo „Sirup“. Číst je může každý, měnit jen admin
// (hlídají to pravidla databáze).
class OptionService {
  final FirebaseFirestore db;

  OptionService(this.db);

  CollectionReference<Map<String, dynamic>> get _groups =>
      db.collection('optionGroups');

  // Živý proud skupin seřazených podle názvu.
  Stream<List<OptionGroup>> watchGroups() {
    return _groups.snapshots().map((snapshot) {
      final groups = snapshot.docs
          .map((doc) => OptionGroup.fromMap(doc.id, doc.data()))
          .toList();
      groups.sort((a, b) => a.name.compareTo(b.name));
      return groups;
    });
  }

  // Nová skupina (bez ID) se přidá, existující se přepíše.
  Future<void> saveGroup(OptionGroup group) {
    if (group.id.isEmpty) return _groups.add(group.toMap());
    return _groups.doc(group.id).set(group.toMap());
  }

  // Smazání skupiny. Produkty, které na ni odkazují, ji prostě přestanou
  // nabízet (neexistující ID se při zobrazení přeskočí).
  Future<void> deleteGroup(String id) {
    return _groups.doc(id).delete();
  }
}
