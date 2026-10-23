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

// Správný český tvar: 1 směna, 2–4 směny, 0 nebo 5 a víc směn.
String formatShiftCount(int count) {
  if (count == 1) return '1 směna';
  if (count >= 2 && count <= 4) return '$count směny';
  return '$count směn';
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
// Délka ve tvaru "8 h 05 min", krátká jen "45 min".
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '$minutes min';
  return '$hours h ${minutes.toString().padLeft(2, '0')} min';
}

const _monthNames = [
  'leden', 'únor', 'březen', 'duben', 'květen', 'červen',
  'červenec', 'srpen', 'září', 'říjen', 'listopad', 'prosinec',
];

const _weekdayNames = ['po', 'út', 'st', 'čt', 'pá', 'so', 'ne'];

// Měsíc a rok, např. "říjen 2026".
String formatMonth(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.year}';
}

// Den s názvem, např. "čt 23. 10.".
String formatDay(DateTime date) {
  return '${_weekdayNames[date.weekday - 1]} ${date.day}. ${date.month}.';
}
