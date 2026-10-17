import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_service.dart';

// Služba pro uživatelské profily v databázi (kolekce "users").
// Každý účet má dokument users/{uid} se jménem, e-mailem, rolí a avatarem.
class UserService {
  final FirebaseFirestore db;

  UserService(this.db);

  CollectionReference<Map<String, dynamic>> get _users =>
      db.collection('users');

  // Živě sleduje profil uživatele. Když profil v databázi ještě není
  // (první přihlášení), založí ho s rolí "zakaznik".
  // Role "obsluha" a "admin" se nastavují jen ručně ve Firebase konzoli.
  Stream<UserProfile> watchProfile(User user) {
    final profile = _users.doc(user.uid);

    return profile.snapshots().asyncMap((doc) async {
      if (!doc.exists) {
        final data = {
          'name': userDisplayName(user),
          'email': user.email ?? '',
          'role': UserRole.zakaznik.name,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await profile.set(data);
        return UserProfile.fromMap(user.uid, data);
      }

      // Oprava: při registraci se profil založí dřív, než se k účtu uloží
      // jméno – v profilu pak zůstane e-mail. Když účet už jméno má,
      // doplníme ho do profilu.
      final data = doc.data()!;
      final savedName = data['name'] as String? ?? '';
      final accountName = user.displayName ?? '';
      if (accountName.isNotEmpty &&
          (savedName.isEmpty || savedName == user.email)) {
        await profile.update({'name': accountName});
        return UserProfile.fromMap(user.uid, {...data, 'name': accountName});
      }
      return UserProfile.fromMap(user.uid, data);
    });
  }

  // Jen role (pro úvodní obrazovku – vstup pro obsluhu a admina).
  Stream<UserRole> watchRole(User user) {
    return watchProfile(user).map((profile) => profile.role);
  }

  // Změní jméno v profilu.
  Future<void> updateName(String uid, String name) {
    return _users.doc(uid).update({'name': name});
  }

  // Změní avatar (ikonu a barvu).
  Future<void> updateAvatar(String uid, String icon, String color) {
    return _users.doc(uid).update({'avatarIcon': icon, 'avatarColor': color});
  }
}
