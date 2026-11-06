import 'package:flutter/material.dart' show ThemeMode;

import 'user_role.dart';

// Profil uživatele z databáze (dokument users/{uid}).
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final UserRole role;

  // Avatar: klíč ikony (viz user_avatar.dart) a klíč barvy.
  // "pismeno" = první písmeno jména, "google" = fotka z Google účtu.
  final String avatarIcon;
  final String avatarColor;

  // Světlý / tmavý vzhled, nebo podle nastavení zařízení (výchozí).
  final ThemeMode themeMode;

  // Oblíbené produkty (ID produktů v menu).
  final List<String> favorites;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.avatarIcon = 'pismeno',
    this.avatarColor = '',
    this.themeMode = ThemeMode.system,
    this.favorites = const [],
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: userRoleFromText(data['role'] as String?),
      avatarIcon: data['avatarIcon'] as String? ?? 'pismeno',
      avatarColor: data['avatarColor'] as String? ?? '',
      // V databázi jako text "light" / "dark" / "system".
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == data['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      favorites: List<String>.from(data['favorites'] as List? ?? []),
    );
  }
}
