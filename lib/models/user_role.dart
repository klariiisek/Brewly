// Role uživatele. Podle ní aplikace ukazuje různé části
// a bezpečnostní pravidla databáze povolují různé akce.
// - zakaznik: objednává
// - obsluha: vyřizuje objednávky a požadavky zákazníků
// - admin: vedoucí podniku – umí vše co obsluha + spravuje menu
enum UserRole {
  zakaznik,
  obsluha,
  admin;

  // Smí vyřizovat objednávky? (obsluha i admin)
  bool get canServe => this == obsluha || this == admin;

  // Smí upravovat menu a nastavení podniku? (jen admin)
  bool get isAdmin => this == admin;
}

// Převede text z databáze ("obsluha") na roli. Cokoli jiného = zákazník.
UserRole userRoleFromText(String? text) {
  for (final role in UserRole.values) {
    if (role.name == text) return role;
  }
  return UserRole.zakaznik;
}
