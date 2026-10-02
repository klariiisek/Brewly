// Role uživatele. Podle ní aplikace ukazuje různé části
// a bezpečnostní pravidla databáze povolují různé akce.
enum UserRole {
  zakaznik,
  obsluha,
}

// Převede text z databáze ("obsluha") na roli. Cokoli jiného = zákazník.
UserRole userRoleFromText(String? text) {
  if (text == UserRole.obsluha.name) return UserRole.obsluha;
  return UserRole.zakaznik;
}
