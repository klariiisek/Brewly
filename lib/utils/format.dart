// Zobrazí cenu bez desetinných míst, např. 45.0 -> "45 Kč".
String formatPrice(double price) {
  return '${price.toStringAsFixed(0)} Kč';
}

// Čas ve tvaru 14:05 (minuty vždy dvoumístně).
String formatTime(DateTime time) {
  final minutes = time.minute.toString().padLeft(2, '0');
  return '${time.hour}:$minutes';
}

// Správný český tvar: 1 položka, 2–4 položky, 0 nebo 5 a víc položek.
String formatItemCount(int count) {
  if (count == 1) return '1 položka';
  if (count >= 2 && count <= 4) return '$count položky';
  return '$count položek';
}

// Správný český tvar: 1 produkt, 2–4 produkty, 0 nebo 5 a víc produktů.
String formatProductCount(int count) {
  if (count == 1) return '1 produkt';
  if (count >= 2 && count <= 4) return '$count produkty';
  return '$count produktů';
}

// Je datum dnes?
bool isToday(DateTime time) {
  final now = DateTime.now();
  return time.year == now.year && time.month == now.month && time.day == now.day;
}

// Kdy byla objednávka vytvořena: "dnes 14:05", nebo "14. 10. 14:05".
String formatOrderDate(DateTime time) {
  final day = isToday(time) ? 'dnes' : '${time.day}. ${time.month}.';
  return '$day ${formatTime(time)}';
}