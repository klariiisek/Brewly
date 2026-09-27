// Zobrazí cenu bez desetinných míst, např. 45.0 -> "45 Kč".
String formatPrice(double price) {
  return '${price.toStringAsFixed(0)} Kč';
}

// Správný český tvar: 1 položka, 2–4 položky, 0 nebo 5 a víc položek.
String formatItemCount(int count) {
  if (count == 1) return '1 položka';
  if (count >= 2 && count <= 4) return '$count položky';
  return '$count položek';
}
