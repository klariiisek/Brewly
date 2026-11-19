import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'opening_hours.dart';

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
  final String wifiName;
  final String wifiPassword;

  // Razítková karta: zapnutá?, za kterou kategorii jsou razítka
  // a kolik razítek je potřeba na odměnu.
  final bool loyaltyEnabled;
  final String loyaltyCategoryId;
  final int loyaltyGoal;

  // Otevírací doba pro každý den v týdnu (0 = pondělí … 6 = neděle).
  // null = ten den je zavřeno. Podle ní se nabízejí i časy rezervací.
  final List<DayHours?> openingDays;

  // Výchozí nastavení (než ho admin poprvé uloží) – z konfigurace aplikace.
  static final defaults = VenueSettings(
    name: AppConfig.defaultVenueName,
    slogan: AppConfig.defaultSlogan,
    colorKey: AppConfig.defaultColor,
    type: VenueType.values.byName(AppConfig.defaultVenueType),
  );

  const VenueSettings({
    required this.name,
    required this.slogan,
    required this.colorKey,
    required this.type,
    this.isOpen = true,
    this.announcement = '',
    this.address = '',
    this.wifiName = '',
    this.wifiPassword = '',
    this.loyaltyEnabled = false,
    this.loyaltyCategoryId = '',
    this.loyaltyGoal = AppConfig.defaultLoyaltyGoal,
    this.openingDays = defaultOpeningDays,
  });

  // Výchozí otevírací doba – každý den stejná (z konfigurace aplikace).
  static const defaultOpeningDays = <DayHours?>[
    _defaultDayHours, _defaultDayHours, _defaultDayHours, _defaultDayHours,
    _defaultDayHours, _defaultDayHours, _defaultDayHours,
  ];
  static const _defaultDayHours = DayHours(
    AppConfig.defaultOpenFrom,
    AppConfig.defaultOpenTo,
  );

  // Otevírací doba v konkrétní den (null = zavřeno).
  DayHours? openingHoursOn(DateTime day) => openingDays[day.weekday - 1];

  // Kdy jde v daný den rezervovat: od otevření do hodiny před zavřením
  // (null = ten den rezervace nejdou).
  DayHours? reservationHoursOn(DateTime day) {
    final open = openingHoursOn(day);
    if (open == null) return null;
    final last = open.to - AppConfig.lastReservationBeforeClosingMinutes;
    return last < open.from ? null : DayHours(open.from, last);
  }

  // Je razítková karta zapnutá a má vybranou kategorii?
  bool get hasLoyalty => loyaltyEnabled && loyaltyCategoryId.isNotEmpty;

  // Vyplnil admin nějaké informace pro zákazníky?
  bool get hasInfo =>
      address.isNotEmpty ||
      wifiName.isNotEmpty ||
      openingDays.any((day) => day != null);

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
      wifiName: text('wifiName', ''),
      wifiPassword: text('wifiPassword', ''),
      loyaltyEnabled: data['loyaltyEnabled'] as bool? ?? false,
      loyaltyCategoryId: text('loyaltyCategoryId', ''),
      loyaltyGoal: data['loyaltyGoal'] as int? ?? AppConfig.defaultLoyaltyGoal,
      // Starší data měla místo otevírací doby jen časy rezervací –
      // převezmeme je, aby se nastavení neztratilo.
      openingDays: _openingDaysFrom(
        data['openingDays'] ?? data['reservationHours'],
      ),
    );
  }

  // V databázi je seznam 7 textů "08:00-20:00" (prázdný = zavřeno).
  static List<DayHours?> _openingDaysFrom(Object? value) {
    if (value is! List || value.length != 7) return defaultOpeningDays;
    return [for (final day in value) DayHours.parse(day as String? ?? '')];
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
    String? wifiName,
    String? wifiPassword,
    bool? loyaltyEnabled,
    String? loyaltyCategoryId,
    int? loyaltyGoal,
    List<DayHours?>? openingDays,
  }) {
    return VenueSettings(
      name: name ?? this.name,
      slogan: slogan ?? this.slogan,
      colorKey: colorKey ?? this.colorKey,
      type: type ?? this.type,
      isOpen: isOpen ?? this.isOpen,
      announcement: announcement ?? this.announcement,
      address: address ?? this.address,
      wifiName: wifiName ?? this.wifiName,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      loyaltyEnabled: loyaltyEnabled ?? this.loyaltyEnabled,
      loyaltyCategoryId: loyaltyCategoryId ?? this.loyaltyCategoryId,
      loyaltyGoal: loyaltyGoal ?? this.loyaltyGoal,
      openingDays: openingDays ?? this.openingDays,
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
      'wifiName': wifiName,
      'wifiPassword': wifiPassword,
      'loyaltyEnabled': loyaltyEnabled,
      'loyaltyCategoryId': loyaltyCategoryId,
      'loyaltyGoal': loyaltyGoal,
      'openingDays': [
        for (final day in openingDays) day?.toString() ?? '',
      ],
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
