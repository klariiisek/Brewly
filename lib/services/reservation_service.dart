import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reservation.dart';

// Služba pro rezervace stolů (kolekce "reservations").
class ReservationService {
  final FirebaseFirestore db;

  ReservationService(this.db);

  CollectionReference<Map<String, dynamic>> get _reservations =>
      db.collection('reservations');

  // Zákazník pošle novou rezervaci. Čeká, až ji obsluha potvrdí.
  Future<void> createReservation({
    required String userId,
    required String customerName,
    required DateTime time,
    required int people,
    required String note,
  }) {
    return _reservations.add({
      'userId': userId,
      'customerName': customerName,
      'time': Timestamp.fromDate(time),
      'people': people,
      'note': note,
      'status': ReservationStatus.ceka.name,
      'tableNumber': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Živě: rezervace jednoho zákazníka, seřazené podle času.
  // (Řadíme v aplikaci, aby databáze nepotřebovala zvláštní index.)
  Stream<List<Reservation>> watchMyReservations(String userId) {
    return _reservations
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_sortedByTime);
  }

  // Živě pro obsluhu: rezervace od dnešního rána dál, nejbližší první.
  Stream<List<Reservation>> watchUpcomingReservations() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _reservations
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .orderBy('time')
        .snapshots()
        .map(_sortedByTime);
  }

  // Zákazník zruší svou rezervaci.
  Future<void> cancel(String reservationId) {
    return _reservations.doc(reservationId).update({
      'status': ReservationStatus.zrusena.name,
    });
  }

  // Obsluha rezervaci potvrdí a případně rovnou přidělí stůl (0 = bez stolu).
  Future<void> confirm(String reservationId, int tableNumber) {
    return _reservations.doc(reservationId).update({
      'status': ReservationStatus.potvrzena.name,
      'tableNumber': tableNumber,
    });
  }

  // Obsluha rezervaci odmítne (např. je plno).
  Future<void> decline(String reservationId) {
    return _reservations.doc(reservationId).update({
      'status': ReservationStatus.odmitnuta.name,
    });
  }

  List<Reservation> _sortedByTime(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final reservations = snapshot.docs
        .map((doc) => Reservation.fromMap(doc.id, doc.data()))
        .toList();
    reservations.sort((a, b) => a.time.compareTo(b.time));
    return reservations;
  }
}
