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

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.avatarIcon = 'pismeno',
    this.avatarColor = '',
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: userRoleFromText(data['role'] as String?),
      avatarIcon: data['avatarIcon'] as String? ?? 'pismeno',
      avatarColor: data['avatarColor'] as String? ?? '',
    );
  }
}
