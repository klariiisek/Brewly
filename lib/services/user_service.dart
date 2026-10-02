import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_role.dart';
import 'auth_service.dart';

// Služba pro uživatelské profily v databázi (kolekce "users").
// Každý účet má dokument users/{uid} se jménem, e-mailem a rolí.
class UserService {
  final FirebaseFirestore db;

  UserService(this.db);

  CollectionReference<Map<String, dynamic>> get _users =>
      db.collection('users');

  // Živě sleduje roli uživatele. Když profil v databázi ještě není
  // (první přihlášení), založí ho s rolí "zakaznik".
  // Roli "obsluha" může nastavit jen správce ve Firebase konzoli.
  Stream<UserRole> watchRole(User user) {
    final profile = _users.doc(user.uid);

    return profile.snapshots().asyncMap((doc) async {
      if (!doc.exists) {
        await profile.set({
          'name': userDisplayName(user),
          'email': user.email ?? '',
          'role': UserRole.zakaznik.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return UserRole.zakaznik;
      }
      return userRoleFromText(doc.data()?['role'] as String?);
    });
  }
}
