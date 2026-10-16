import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/venue_settings.dart';

// Služba pro nastavení podniku (dokument settings/venue).
// Číst ho může každý, měnit jen admin (hlídají to pravidla databáze).
class SettingsService {
  final FirebaseFirestore db;

  SettingsService(this.db);

  DocumentReference<Map<String, dynamic>> get _venue =>
      db.collection('settings').doc('venue');

  // Živě sleduje nastavení. Dokud ho admin neuloží, vrací výchozí.
  Stream<VenueSettings> watchSettings() {
    return _venue
        .snapshots()
        .map((doc) => VenueSettings.fromMap(doc.data()));
  }

  Future<void> saveSettings(VenueSettings settings) {
    return _venue.set(settings.toMap());
  }

  // Uloží jen nové pořadí kategorií (ostatní nastavení zůstane, jak je).
  Future<void> saveCategoryOrder(VenueSettings current, List<String> order) {
    return saveSettings(current.withCategoryOrder(order));
  }
}
