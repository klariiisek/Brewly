import 'package:flutter/material.dart';

// Typ podniku – podle něj se mění ikona a emoji v aplikaci.
enum VenueType {
  kavarna('Kavárna', Icons.coffee, '☕'),
  cukrarna('Cukrárna', Icons.cake, '🧁'),
  bar('Bar', Icons.local_bar, '🍸'),
  pivnice('Pivnice', Icons.sports_bar, '🍺'),
  restaurace('Restaurace', Icons.restaurant, '🍽️');

  final String label;
  final IconData icon;
  final String emoji;

  const VenueType(this.label, this.icon, this.emoji);
}

// Nastavení podniku, které mění admin. V databázi je to jediný
// dokument settings/venue a celá aplikace ho živě poslouchá.
class VenueSettings {
  final String name; // název podniku, např. "Kavárna U Lípy"
  final String slogan; // krátký text na úvodní obrazovce
  final String colorKey; // klíč palety, např. "kava" (viz palettes.dart)
  final VenueType type;

  // Provoz podniku.
  final bool isOpen; // false = zavřeno, objednávat nejde
  final String announcement; // oznámení nahoře v menu (prázdné = žádné)

  // Informace pro zákazníky (prázdné = nezobrazí se).
  final String address;
  final String openingHours;
  final String wifiName;
  final String wifiPassword;

  // Výchozí nastavení (než ho admin poprvé uloží) – kavárna Brewly.
  static const defaults = VenueSettings(
    name: 'Brewly',
    slogan: 'Vítejte v naší kavárně',
    colorKey: 'kava',
    type: VenueType.kavarna,
  );

  const VenueSettings({
    required this.name,
    required this.slogan,
    required this.colorKey,
    required this.type,
    this.isOpen = true,
    this.announcement = '',
    this.address = '',
    this.openingHours = '',
    this.wifiName = '',
    this.wifiPassword = '',
  });

  // Vyplnil admin nějaké informace pro zákazníky?
  bool get hasInfo =>
      address.isNotEmpty || openingHours.isNotEmpty || wifiName.isNotEmpty;

  // Z dat v databázi. Co chybí, doplní se z výchozího nastavení.
  factory VenueSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return defaults;
    String text(String key, String fallback) =>
        data[key] as String? ?? fallback;

    return VenueSettings(
      name: text('name', defaults.name),
      slogan: text('slogan', defaults.slogan),
      colorKey: text('color', defaults.colorKey),
      type: VenueType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => defaults.type,
      ),

      isOpen: data['isOpen'] as bool? ?? true,
      announcement: text('announcement', ''),
      address: text('address', ''),
      openingHours: text('openingHours', ''),
      wifiName: text('wifiName', ''),
      wifiPassword: text('wifiPassword', ''),
    );
  }

  // Kopie nastavení, ve které se změní jen zadané údaje.
  VenueSettings copyWith({
    String? name,
    String? slogan,
    String? colorKey,
    VenueType? type,
    bool? isOpen,
    String? announcement,
    String? address,
    String? openingHours,
    String? wifiName,
    String? wifiPassword,
  }) {
    return VenueSettings(
      name: name ?? this.name,
      slogan: slogan ?? this.slogan,
      colorKey: colorKey ?? this.colorKey,
      type: type ?? this.type,
      isOpen: isOpen ?? this.isOpen,
      announcement: announcement ?? this.announcement,
      address: address ?? this.address,
      openingHours: openingHours ?? this.openingHours,
      wifiName: wifiName ?? this.wifiName,
      wifiPassword: wifiPassword ?? this.wifiPassword,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slogan': slogan,
      'color': colorKey,
      'type': type.name,
      'isOpen': isOpen,
      'announcement': announcement,
      'address': address,
      'openingHours': openingHours,
      'wifiName': wifiName,
      'wifiPassword': wifiPassword,
    };
  }
}

// Zpřístupní nastavení podniku všem obrazovkám pod ní – podobně jako
// Theme.of(context). Obrazovka si ho vezme přes VenueScope.of(context)
// a když admin nastavení změní, Flutter ji sám překreslí.
class VenueScope extends InheritedWidget {
  final VenueSettings settings;

  const VenueScope({super.key, required this.settings, required super.child});

  static VenueSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<VenueScope>();
    return scope?.settings ?? VenueSettings.defaults;
  }

  @override
  bool updateShouldNotify(VenueScope oldWidget) =>
      settings != oldWidget.settings;
}
