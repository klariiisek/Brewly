import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Ikonky, ze kterých si zákazník vybírá avatar. Klíč se ukládá do databáze.
// "pismeno" = první písmeno jména, "google" = fotka z Google účtu.
const Map<String, IconData> avatarIcons = {
  'kava': Icons.coffee,
  'dort': Icons.cake,
  'kocka': Icons.pets,
  'srdce': Icons.favorite,
  'hvezda': Icons.star,
  'kvet': Icons.local_florist,
  'slunce': Icons.wb_sunny,
  'mesic': Icons.nightlight_round,
  'hudba': Icons.music_note,
  'kniha': Icons.menu_book,
  'list': Icons.eco,
  'raketa': Icons.rocket_launch,
};

// Barvy avataru. Prázdný klíč = hlavní barva podniku.
const Map<String, Color> avatarColors = {
  'hneda': Color(0xFF6F4E37),
  'cervena': Color(0xFFC0392B),
  'oranzova': Color(0xFFE67E22),
  'zluta': Color(0xFFD4A017),
  'zelena': Color(0xFF3E8E5E),
  'modra': Color(0xFF2E6FB0),
  'fialova': Color(0xFF7B5EA7),
  'ruzova': Color(0xFFD35D8A),
};

// Kulatý avatar: fotka z Googlu, ikonka, nebo první písmeno jména.
class UserAvatar extends StatelessWidget {
  final String name;
  final String icon;
  final String color;
  final String? photoUrl; // fotka z Google účtu (pokud ji uživatel má)
  final double size;

  const UserAvatar({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    this.photoUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final background = avatarColors[color] ?? context.colors.primary;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    Widget letter() => Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );

    Widget child;
    if (icon == 'google' && photoUrl != null) {
      // Fotka z Googlu. Když se nenačte, ukáže se písmeno.
      child = ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (context, error, stack) => Center(child: letter()),
        ),
      );
    } else if (avatarIcons.containsKey(icon)) {
      child = Icon(avatarIcons[icon], size: size * 0.5, color: Colors.white);
    } else {
      child = letter();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: child,
    );
  }
}
