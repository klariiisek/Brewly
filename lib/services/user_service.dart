import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show ThemeMode;

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

  // Admin: živě všechny účty (zaměstnanci i zákazníci), seřazené podle jména.
  Stream<List<UserProfile>> watchAllUsers() {
    return _users.snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
          .toList();
      users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return users;
    });
  }

  // Admin změní roli jiného účtu (zákazník ↔ obsluha).
  // Pravidla hlídají, že admin nemění sebe ani jiného admina.
  Future<void> setRole(String uid, UserRole role) {
    return _users.doc(uid).update({'role': role.name});
  }

  // Uloží volbu světlého / tmavého vzhledu k účtu (platí na všech zařízeních).
  Future<void> updateThemeMode(String uid, ThemeMode mode) {
    return _users.doc(uid).update({'themeMode': mode.name});
  }

  // Přidá produkt do oblíbených, nebo ho z nich odebere.
  // arrayUnion / arrayRemove změní jen tuto položku seznamu – nemusíme
  // posílat celý seznam a nic se nepřepíše, kdyby měl zákazník
  // aplikaci otevřenou na dvou zařízeních.
  Future<void> setFavorite(String uid, String productId, bool isFavorite) {
    return _users.doc(uid).update({
      'favorites': isFavorite
          ? FieldValue.arrayUnion([productId])
          : FieldValue.arrayRemove([productId]),
    });
  }

  // Změní avatar (ikonu a barvu).
  Future<void> updateAvatar(String uid, String icon, String color) {
    return _users.doc(uid).update({'avatarIcon': icon, 'avatarColor': color});
  }
}
