import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

// Zaměstnanec, který je právě v práci (dokument activeShifts/{uid}).
// Každý má nejvýš jeden takový dokument – nejde tedy dát Příchod dvakrát.
class ActiveShift {
  final String userId;
  final String userName;

  // Čas příchodu přesně tak, jak ho uložil server. Při odchodu se zkopíruje
  // do hotové směny a pravidla zkontrolují, že se nezměnil.
  // null = příchod se právě ukládá (server ještě čas nepotvrdil).
  final Timestamp? startStamp;

  const ActiveShift({
    required this.userId,
    required this.userName,
    required this.startStamp,
  });

  // Než server čas potvrdí, počítáme s aktuálním časem.
  DateTime get start => startStamp?.toDate() ?? DateTime.now();

  // Jak dlouho už je v práci.
  Duration get elapsed => DateTime.now().difference(start);

  factory ActiveShift.fromMap(Map<String, dynamic> data) {
    return ActiveShift(
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      startStamp: data['start'] as Timestamp?,
    );
  }
}

// Hotová směna: příchod a odchod (dokument shifts/{id}).
class Shift {
  final String id;
  final String userId;
  final String userName;
  final DateTime start;
  final DateTime end;

  // true = odchod doplnil admin (zaměstnanec se zapomněl odhlásit).
  final bool edited;

  const Shift({
    required this.id,
    required this.userId,
    required this.userName,
    required this.start,
    required this.end,
    this.edited = false,
  });

  // Odpracovaná doba.
  Duration get duration => end.difference(start);

  factory Shift.fromMap(String id, Map<String, dynamic> data) {
    final start = (data['start'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Shift(
      id: id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      start: start,
      // Odchod se právě ukládá → zatím aktuální čas.
      end: (data['end'] as Timestamp?)?.toDate() ?? DateTime.now(),
      edited: data['edited'] as bool? ?? false,
    );
  }
}

// Začátek měsíce, ve kterém je datum (1. den, 0:00).
DateTime monthStart(DateTime date) => DateTime(date.year, date.month);

// Směny, které začaly v daném měsíci. (Noční směna přes půlnoc
// na konci měsíce se počítá do měsíce, kdy začala.)
List<Shift> shiftsInMonth(List<Shift> shifts, DateTime month) {
  final from = monthStart(month);
  final to = DateTime(from.year, from.month + 1);
  return shifts
      .where((shift) => !shift.start.isBefore(from) && shift.start.isBefore(to))
      .toList();
}

// Součet odpracované doby.
Duration totalDuration(List<Shift> shifts) {
  return shifts.fold(Duration.zero, (sum, shift) => sum + shift.duration);
}
