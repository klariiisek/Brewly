import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// KONFIGURACE: barevné palety, ze kterých admin vybírá v nastavení podniku.
// Novou paletu přidá programátor sem (a její klíč do firestore.rules).
// Každá má hlavní barvu, tmavou na text, doplňkovou, pozadí a šedou.
// Klíč (např. "kava") se ukládá do databáze.
class Palette {
  final String key;
  final String label;
  final AppColors colors;

  const Palette(this.key, this.label, this.colors);
}

const List<Palette> palettes = [
  Palette('kava', 'Kávová', AppColors(
    primary: Color(0xFF6F4E37),
    dark: Color(0xFF3E2723),
    accent: Color(0xFFC8894B),
    background: Color(0xFFFAF6F1),
    muted: Color(0xFF8D7B6F),
  )),
  Palette('bordo', 'Bordó', AppColors(
    primary: Color(0xFF7B1E3A),
    dark: Color(0xFF3B0D1C),
    accent: Color(0xFFC9A227),
    background: Color(0xFFFBF5F6),
    muted: Color(0xFF8E7479),
  )),
  Palette('terakota', 'Terakota', AppColors(
    primary: Color(0xFFB4532A),
    dark: Color(0xFF4A2212),
    accent: Color(0xFFE9B44C),
    background: Color(0xFFFBF6F2),
    muted: Color(0xFF94786A),
  )),
  Palette('olivova', 'Olivová', AppColors(
    primary: Color(0xFF5F6B3A),
    dark: Color(0xFF2F3520),
    accent: Color(0xFFC08A3E),
    background: Color(0xFFF8F7F0),
    muted: Color(0xFF7F8270),
  )),
  Palette('lesni', 'Lesní zelená', AppColors(
    primary: Color(0xFF2E5E4E),
    dark: Color(0xFF173029),
    accent: Color(0xFFD9A441),
    background: Color(0xFFF3F7F4),
    muted: Color(0xFF6E8279),
  )),
  Palette('namornicka', 'Námořnická', AppColors(
    primary: Color(0xFF1F3A5F),
    dark: Color(0xFF0F1E33),
    accent: Color(0xFFD4A373),
    background: Color(0xFFF4F6F9),
    muted: Color(0xFF6B7A8C),
  )),
  Palette('levandulova', 'Levandulová', AppColors(
    primary: Color(0xFF6B5B95),
    dark: Color(0xFF342B4D),
    accent: Color(0xFFE6A57E),
    background: Color(0xFFF7F5FA),
    muted: Color(0xFF857D96),
  )),
  Palette('grafitova', 'Grafitová', AppColors(
    primary: Color(0xFF3A3A3C),
    dark: Color(0xFF1C1C1E),
    accent: Color(0xFFE07A5F),
    background: Color(0xFFF6F6F4),
    muted: Color(0xFF7A7A7E),
  )),
];

// Najde paletu podle klíče z databáze. Neznámý klíč = první (kávová).
Palette paletteFor(String key) {
  return palettes.firstWhere(
    (palette) => palette.key == key,
    orElse: () => palettes.first,
  );
}
