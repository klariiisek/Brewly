import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../l10n/language.dart';
import 'opening_hours.dart';

// DayHours (čas od–do) je v opening_hours.dart – ostatní soubory ho tak
// dostanou i přes import rezervací.
export 'opening_hours.dart';

// Stav rezervace. Nová rezervace čeká, až ji obsluha potvrdí nebo odmítne.
// Zákazník ji může zrušit (dokud čeká nebo je potvrzená).
enum ReservationStatus { ceka, potvrzena, odmitnuta, zrusena }

// Název stavu v jazyce aplikace (t = překlady, viz lib/l10n).
String reservationStatusText(AppLocalizations t, ReservationStatus status) {
  switch (status) {
    case ReservationStatus.ceka:
      return t.resPending;
    case ReservationStatus.potvrzena:
      return t.resConfirmed;
    case ReservationStatus.odmitnuta:
      return t.resDeclined;
    case ReservationStatus.zrusena:
      return t.resCancelled;
  }
}

// Rezervace stolu: kdo, kdy a kolik lidí. Konkrétní stůl přidělí obsluha
// při potvrzení (0 = zatím žádný).
class Reservation {
  final String id;
  final String userId;
  final String customerName;
  final DateTime time;
  final int people;
  final String note;
  final ReservationStatus status;
  final int tableNumber;

  const Reservation({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.time,
    required this.people,
    required this.note,
    required this.status,
    required this.tableNumber,
  });

  factory Reservation.fromMap(String id, Map<String, dynamic> data) {
    return Reservation(
      id: id,
      userId: data['userId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime(2000),
      people: data['people'] as int? ?? 1,
      note: data['note'] as String? ?? '',
      status: ReservationStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => ReservationStatus.ceka,
      ),
      tableNumber: data['tableNumber'] as int? ?? 0,
    );
  }

  // Ještě nenastala a platí (čeká nebo je potvrzená).
  bool get isUpcoming =>
      time.isAfter(DateTime.now()) &&
      (status == ReservationStatus.ceka ||
          status == ReservationStatus.potvrzena);

  // Zákazník ji smí zrušit (pravidla to hlídají taky).
  bool get canCancel => isUpcoming;
}

// Stoly, které jsou v době rezervace [reservation] už obsazené jinou
// potvrzenou rezervací. Bereme, že hosté sedí u stolu [duration]
// (např. 2 hodiny), takže rezervace v 18:00 a v 19:00 se překrývají.
// Výsledek: číslo stolu → rezervace, která ho má.
Map<int, Reservation> occupiedTables(
  Reservation reservation,
  List<Reservation> all, {
  required Duration duration,
}) {
  return {
    for (final other in all)
      if (other.id != reservation.id &&
          other.status == ReservationStatus.potvrzena &&
          other.tableNumber > 0 &&
          other.time.difference(reservation.time).abs() < duration)
        other.tableNumber: other,
  };
}

// Časy, na které jde rezervovat v daný den: po půl hodinách od prvního
// do posledního času rezervace podle [hours] (null = ten den nejde
// rezervovat).
// Dnes jen časy aspoň [minAdvance] od teď.
List<DateTime> reservationSlots(
  DateTime day, {
  required DayHours? hours,
  required Duration minAdvance,
  DateTime? now,
}) {
  if (hours == null) return [];
  final earliest = (now ?? DateTime.now()).add(minAdvance);
  final slots = <DateTime>[];
  for (var minute = hours.from; minute <= hours.to; minute += 30) {
    final slot = DateTime(day.year, day.month, day.day, 0, minute);
    if (slot.isAfter(earliest)) slots.add(slot);
  }
  return slots;
}
