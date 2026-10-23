// ============================================================================
//  KONFIGURACE APLIKACE
// ============================================================================
//
// Tady je všechno, co nastavuje PROGRAMÁTOR při nasazení aplikace pro
// konkrétní podnik. Za provozu se to nemění – změna znamená upravit tento
// soubor a aplikaci znovu sestavit a nahrát na web.
//
// Naopak to, co mění VEDOUCÍ PODNIKU (admin) přímo v aplikaci – název,
// barva, otevřeno/zavřeno, oznámení… – je v databázi (dokument
// settings/venue), aby se to změnilo hned všem zákazníkům.
//
// Barevné palety, ze kterých admin vybírá, jsou v souboru palettes.dart.
//
// ⚠️ Limity označené [pravidla] jsou zapsané i v souboru firestore.rules
//    (pravidla databáze neumí číst soubory aplikace). Při změně je potřeba
//    upravit obě místa.
class AppConfig {
  // ---------- Aplikace ----------

  // Adresa, na které aplikace běží. Je v QR kódech na stolech.
  static const String appUrl = 'https://brewly-9e944.web.app';

  // ---------- Podnik ----------

  // Počet stolů. Každý stůl má QR kód s tajným kódem. [pravidla]
  static const int tableCount = 10;

  // Délka tajného kódu stolu (např. K7P2X9).
  static const int tableCodeLength = 6;

  // Výchozí vzhled podniku – platí, dokud admin v aplikaci nic nenastaví.
  static const String defaultVenueName = 'Brewly';
  static const String defaultSlogan = 'Vítejte v naší kavárně';
  static const String defaultColor = 'kava'; // klíč palety z palettes.dart
  static const String defaultVenueType = 'kavarna';

  // ---------- Menu a objednávky ----------

  // Nejvyšší cena jednoho produktu v Kč.
  static const double maxProductPrice = 10000;

  // Nejvíc položek v jedné objednávce. [pravidla]
  static const int maxOrderItems = 50;

  // Nejvíc produktů v jednom nahrání z CSV (Firestore zvládne max. 500
  // zápisů najednou, kategorie potřebují pár zápisů navíc).
  static const int maxCsvProducts = 400;

  // ---------- Délky textů (počet znaků) ----------

  static const int maxVenueNameLength = 40; // [pravidla]
  static const int maxSloganLength = 80; // [pravidla]
  static const int maxAnnouncementLength = 120; // [pravidla]
  static const int maxAddressLength = 100; // [pravidla]
  static const int maxOpeningHoursLength = 300; // [pravidla]
  static const int maxWifiLength = 50; // [pravidla]
  static const int maxCategoryNameLength = 40; // [pravidla]
  static const int maxUserNameLength = 40;
}
