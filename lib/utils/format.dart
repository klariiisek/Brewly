// Zobrazí cenu bez desetinných míst, např. 45.0 -> "45 Kč".
String formatPrice(double price) {
  return '${price.toStringAsFixed(0)} Kč';
}
