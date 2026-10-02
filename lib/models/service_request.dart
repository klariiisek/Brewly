import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

// Požadavek zákazníka na obsluhu: "Přivolat obsluhu" nebo "Chci zaplatit".
enum RequestType {
  obsluha,
  platba,
}

String requestTypeText(RequestType type) {
  switch (type) {
    case RequestType.obsluha:
      return 'Přivolává obsluhu';
    case RequestType.platba:
      return 'Chce zaplatit';
  }
}

class ServiceRequest {
  final String id;
  final RequestType type;
  final int tableNumber;
  final String userId;
  final String customerName;
  // Vyřízený požadavek už obsluha neuvidí v seznamu.
  final bool isDone;
  // Kdy zákazník požadavek odeslal (těsně po odeslání může být null,
  // než databáze doplní čas).
  final DateTime? createdAt;

  const ServiceRequest({
    required this.id,
    required this.type,
    required this.tableNumber,
    required this.userId,
    required this.customerName,
    required this.isDone,
    required this.createdAt,
  });

  factory ServiceRequest.fromMap(String id, Map<String, dynamic> data) {
    return ServiceRequest(
      id: id,
      type: data['type'] == RequestType.platba.name
          ? RequestType.platba
          : RequestType.obsluha,
      tableNumber: data['tableNumber'] as int? ?? 0,
      userId: data['userId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      isDone: data['status'] == 'vyrizeno',
      // Firestore ukládá čas jako Timestamp; převedeme ho na DateTime.
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
