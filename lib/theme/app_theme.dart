import 'package:flutter/material.dart';

// Barvy Brewly na jednom místě.
class AppColors {
  static const Color coffee = Color(0xFF6F4E37); // hlavní kávově hnědá
  static const Color darkCoffee = Color(0xFF3E2723); // tmavá hnědá na text
  static const Color caramel = Color(0xFFC8894B); // akcent
  static const Color cream = Color(0xFFFAF6F1); // pozadí obrazovek
  static const Color muted = Color(0xFF8D7B6F); // méně důležitý text
  static const Color success = Color(0xFF5B8C5A); // zelená, např. "Připravena"
}

// Zaoblení rohů, aby všude vypadalo stejně.
class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
}

// Vzhled celé aplikace. Používá se v main.dart (theme: AppTheme.light).
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.coffee,
        primary: AppColors.coffee,
        secondary: AppColors.caramel,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.cream,

      // Horní lišta: krémová s tmavě hnědým nadpisem.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.darkCoffee,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.darkCoffee,
        ),
      ),

      // Karty: bílé, kulaté rohy, jemný stín.
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: AppColors.coffee.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      ),

      // Hlavní tlačítka: hnědá s bílým textem.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coffee,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
      ),

      // Tlačítka s rámečkem.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.coffee,
          side: const BorderSide(color: AppColors.coffee),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
      ),

      // Textová tlačítka.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.coffee),
      ),

      // Okna vysunutá zespodu (detail produktu).
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
        dragHandleColor: AppColors.muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Spodní lišta se záložkami.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.coffee.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.coffee);
          }
          return const IconThemeData(color: AppColors.muted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.coffee,
            );
          }
          return const TextStyle(fontSize: 12, color: AppColors.muted);
        }),
      ),

      // Hlášení dole na obrazovce (SnackBar).
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        width: 320,
        backgroundColor: AppColors.darkCoffee,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    );
  }
}
