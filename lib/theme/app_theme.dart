import 'package:flutter/material.dart';

import '../widgets/venue_pattern.dart';

// Barvy aplikace (paleta). Admin si v nastavení podniku vybere jednu
// z připravených palet (viz palettes.dart) a celá aplikace se přebarví.
//
// Paleta je uložená v tématu (Theme) jako "rozšíření" (ThemeExtension).
// Obrazovky si barvy berou přes context.colors – a když se téma změní,
// Flutter je sám překreslí novými barvami.
class AppColors extends ThemeExtension<AppColors> {
  final Color primary; // hlavní barva (tlačítka, ikony, ceny)
  final Color dark; // tmavá barva na nadpisy a text
  final Color accent; // doplňková barva (přechod v hlavičce, akcenty)
  final Color background; // pozadí obrazovek
  final Color muted; // méně důležitý text

  // Zelená pro "Připravena" je stejná ve všech paletách.
  static const Color success = Color(0xFF5B8C5A);

  const AppColors({
    required this.primary,
    required this.dark,
    required this.accent,
    required this.background,
    required this.muted,
  });

  // Tyhle dvě metody po nás Flutter u ThemeExtension vyžaduje.
  // copyWith = kopie se změněnými barvami, lerp = plynulý přechod mezi
  // dvěma paletami (díky tomu se aplikace přebarví s jemnou animací).
  @override
  AppColors copyWith({
    Color? primary,
    Color? dark,
    Color? accent,
    Color? background,
    Color? muted,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      dark: dark ?? this.dark,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      muted: muted ?? this.muted,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      dark: Color.lerp(dark, other.dark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

// Zkratka: context.colors.primary místo Theme.of(context).extension<AppColors>()!
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

// Písmo celé aplikace. Uvádí se i u jednotlivých stylů v tématu níže –
// styly tlačítek, horní a spodní lišty se totiž z tématu nedědí.
const String appFont = 'Lexend';

// Zaoblení rohů, aby všude vypadalo stejně.
class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
}

// Vzhled celé aplikace sestavený z vybrané palety.
// Používá se v main.dart: theme: AppTheme.build(paleta).
class AppTheme {
  static ThemeData build(AppColors colors) {
    return ThemeData(
      // Písmo celé aplikace (přibalené v assets/fonts, viz pubspec.yaml).
      fontFamily: appFont,
      extensions: [colors],
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        primary: colors.primary,
        secondary: colors.accent,
        surface: Colors.white,
      ),
      // Obrazovky jsou průhledné – pozadí s barvou a vzorem podniku jim
      // dává přechod mezi stránkami (PatternedPageTransitionsBuilder).
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const PatternedPageTransitionsBuilder(),
        },
      ),

      // Horní lišta: barva pozadí s tmavým nadpisem.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.dark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: appFont,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colors.dark,
        ),
      ),

      // Karty: bílé, kulaté rohy, jemný stín.
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: colors.primary.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      ),

      // Hlavní tlačítka: hlavní barva s bílým textem.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: appFont,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
      ),

      // Tlačítka s rámečkem.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
      ),

      // Textová tlačítka.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.primary),
      ),

      // Textová pole (e-mail, heslo...): bílá, kulaté rohy, barevný rámeček.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        prefixIconColor: colors.primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: colors.muted.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: colors.muted.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),

      // Záložky nahoře (např. Aktivní / Dokončené u obsluhy).
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.muted,
        indicatorColor: colors.primary,
        labelStyle: const TextStyle(
          fontFamily: appFont,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Okna vysunutá zespodu (detail produktu).
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
        dragHandleColor: colors.muted,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Spodní lišta se záložkami.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: colors.primary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.primary);
          }
          return IconThemeData(color: colors.muted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: appFont,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            );
          }
          return TextStyle(
            fontFamily: appFont,
            fontSize: 12,
            color: colors.muted,
          );
        }),
      ),

      // Hlášení dole na obrazovce (SnackBar).
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        width: 320,
        backgroundColor: colors.dark,
        contentTextStyle: const TextStyle(
          fontFamily: appFont,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    );
  }
}
