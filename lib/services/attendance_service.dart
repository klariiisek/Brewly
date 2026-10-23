import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shift.dart';

// Docházka obsluhy (jako píchačky v práci): Příchod a Odchod.
//
// Dvě kolekce:
// - activeShifts/{uid} = kdo je právě v práci a od kdy (jeden dokument
//   na člověka, takže nejde dát Příchod dvakrát),
// - shifts/{id} = hotové směny (příchod + odchod).
// Časy bere server (serverTimestamp), ne telefon – nedají se tedy podvrhnout.
class AttendanceService {
  final FirebaseFirestore db;

  AttendanceService(this.db);

  CollectionReference<Map<String, dynamic>> get _active =>
      db.collection('activeShifts');

  CollectionReference<Map<String, dynamic>> get _shifts =>
      db.collection('shifts');

  // Živě: je zaměstnanec v práci? (null = není)
  Stream<ActiveShift?> watchActiveShift(String userId) {
    return _active.doc(userId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : ActiveShift.fromMap(data);
    });
  }

  // Příchod: zapíše, že je zaměstnanec v práci (čas doplní server).
  Future<void> clockIn({required String userId, required String userName}) {
    return _active.doc(userId).set({
      'userId': userId,
      'userName': userName,
      'start': FieldValue.serverTimestamp(),
    });
  }

  // Odchod: v jednom hromadném zápisu (batch) uloží hotovou směnu
  // a smaže záznam „v práci“. Buď se povede obojí, nebo nic.
  Future<void> clockOut(ActiveShift active) {
    final batch = db.batch();
    batch.set(_shifts.doc(), {
      'userId': active.userId,
      'userName': active.userName,
      'start': active.startStamp,
      'end': FieldValue.serverTimestamp(),
      'edited': false,
    });
    batch.delete(_active.doc(active.userId));
    return batch.commit();
  }

  // Admin ukončí zapomenutou směnu – čas odchodu zadá sám.
  // Směna se označí jako upravená (edited), aby bylo vidět, kdo ji ukončil.
  Future<void> closeForgottenShift(ActiveShift active, DateTime end) {
    final batch = db.batch();
    batch.set(_shifts.doc(), {
      'userId': active.userId,
      'userName': active.userName,
      'start': active.startStamp,
      'end': Timestamp.fromDate(end),
      'edited': true,
    });
    batch.delete(_active.doc(active.userId));
    return batch.commit();
  }

  // Živě: všechny směny jednoho zaměstnance, nejnovější nahoře.
  // Měsíc vybíráme až v aplikaci, aby databáze nepotřebovala zvláštní index.
  Stream<List<Shift>> watchMyShifts(String userId) {
    return _shifts
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_newestFirst);
  }

  // Admin: živě všechny směny, které začaly v daném měsíci.
  Stream<List<Shift>> watchShiftsInMonth(DateTime month) {
    final from = monthStart(month);
    final to = DateTime(from.year, from.month + 1);
    return _shifts
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('start', isLessThan: Timestamp.fromDate(to))
        .snapshots()
        .map(_newestFirst);
  }

  // Admin: živě všichni, kdo jsou právě v práci (nejdéle přihlášení nahoře).
  Stream<List<ActiveShift>> watchActiveShifts() {
    return _active.snapshots().map((snapshot) {
      final active = snapshot.docs
          .map((doc) => ActiveShift.fromMap(doc.data()))
          .toList();
      active.sort((a, b) => a.start.compareTo(b.start));
      return active;
    });
  }

  List<Shift> _newestFirst(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final shifts = snapshot.docs
        .map((doc) => Shift.fromMap(doc.id, doc.data()))
        .toList();
    shifts.sort((a, b) => b.start.compareTo(a.start));
    return shifts;
  }
}
