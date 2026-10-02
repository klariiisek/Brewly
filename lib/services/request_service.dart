import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_request.dart';

// Služba pro požadavky zákazníků na obsluhu (kolekce "requests").
class RequestService {
  final FirebaseFirestore db;

  RequestService(this.db);

  CollectionReference<Map<String, dynamic>> get _requests =>
      db.collection('requests');

  // Zákazník odešle požadavek ("Přivolat obsluhu" nebo "Chci zaplatit").
  //
  // Ochrana proti spamu: každý zákazník má pro každý typ jen JEDEN dokument
  // s pevným ID, např. "abc123_platba". Bezpečnostní pravidla dovolí dokument
  // znovu použít až poté, co ho obsluha vyřídí. Dokud požadavek čeká,
  // databáze další stejný požadavek odmítne.
  Future<void> createRequest({
    required RequestType type,
    required int tableNumber,
    required String userId,
    required String customerName,
  }) {
    return _requests.doc('${userId}_${type.name}').set({
      'type': type.name,
      'tableNumber': tableNumber,
      'userId': userId,
      'customerName': customerName,
      'status': 'cekajici',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Živě: nevyřízené požadavky jednoho zákazníka
  // (aby tlačítko vědělo, že už o něm obsluha ví).
  Stream<List<ServiceRequest>> watchMyPendingRequests(String userId) {
    return _requests
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => _pendingOnly(snapshot));
  }

  // Živě: všechny nevyřízené požadavky pro obsluhu, nejstarší nahoře.
  Stream<List<ServiceRequest>> watchPendingRequests() {
    return _requests
        .where('status', isEqualTo: 'cekajici')
        .snapshots()
        .map((snapshot) => _pendingOnly(snapshot));
  }

  // Obsluha označí požadavek jako vyřízený.
  Future<void> markDone(String requestId) {
    return _requests.doc(requestId).update({'status': 'vyrizeno'});
  }

  // Převede data z databáze na seznam nevyřízených požadavků seřazených
  // podle času (nejstarší první). Řadíme v aplikaci, aby databáze
  // nepotřebovala zvláštní index.
  List<ServiceRequest> _pendingOnly(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final requests = snapshot.docs
        .map((doc) => ServiceRequest.fromMap(doc.id, doc.data()))
        .where((request) => !request.isDone)
        .toList();
    requests.sort((a, b) {
      // Požadavek bez času (právě odeslaný) patří na konec.
      final aTime = a.createdAt ?? DateTime(9999);
      final bTime = b.createdAt ?? DateTime(9999);
      return aTime.compareTo(bTime);
    });
    return requests;
  }
}
