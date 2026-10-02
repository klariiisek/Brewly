import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/service_request.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'app_message.dart';
import 'table_picker.dart';

// Karta "Potřebujete něco?" s tlačítky Přivolat obsluhu a Chci zaplatit.
// Zobrazuje se přihlášenému zákazníkovi v záložce Objednávky.
class TableServiceCard extends StatefulWidget {
  final AppServices services;
  final Cart cart;
  final User user;

  const TableServiceCard({
    super.key,
    required this.services,
    required this.cart,
    required this.user,
  });

  @override
  State<TableServiceCard> createState() => _TableServiceCardState();
}

class _TableServiceCardState extends State<TableServiceCard> {
  // Živý proud nevyřízených požadavků tohoto zákazníka.
  late final Stream<List<ServiceRequest>> pendingStream;

  @override
  void initState() {
    super.initState();
    pendingStream =
        widget.services.requests.watchMyPendingRequests(widget.user.uid);
  }

  Future<void> chooseTable() async {
    final table = await showTablePicker(
      context,
      current: widget.cart.tableNumber,
    );
    if (table != null) {
      setState(() => widget.cart.tableNumber = table);
    }
  }

  Future<void> sendRequest(RequestType type) async {
    // Bez stolu by obsluha nevěděla, kam jít – nejdřív se zeptáme.
    if (widget.cart.tableNumber == null) {
      await chooseTable();
      if (widget.cart.tableNumber == null || !mounted) return;
    }

    try {
      await widget.services.requests.createRequest(
        type: type,
        tableNumber: widget.cart.tableNumber!,
        userId: widget.user.uid,
        customerName: userDisplayName(widget.user),
      );
      if (!mounted) return;
      showAppMessage(
        context,
        type == RequestType.platba
            ? 'Obsluha za vámi přijde s účtem'
            : 'Obsluha za vámi brzy přijde',
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      // Databáze odmítla další požadavek, protože předchozí ještě čeká.
      showAppMessage(
        context,
        error.code == 'permission-denied'
            ? 'Obsluha o vás už ví, vydržte prosím chvilku'
            : 'Požadavek se nepodařilo odeslat',
      );
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Požadavek se nepodařilo odeslat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.cart.tableNumber;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<ServiceRequest>>(
          stream: pendingStream,
          builder: (context, snapshot) {
            final pending = snapshot.data ?? [];
            // Čeká už nějaký požadavek daného typu?
            bool isWaiting(RequestType type) =>
                pending.any((request) => request.type == type);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Potřebujete něco?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkCoffee,
                        ),
                      ),
                    ),
                    // Aktuální stůl – kliknutím se dá změnit.
                    TextButton.icon(
                      onPressed: chooseTable,
                      icon: const Icon(Icons.table_restaurant, size: 18),
                      label: Text(table == null ? 'Vybrat stůl' : 'Stůl $table'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: buildButton(
                        type: RequestType.obsluha,
                        icon: Icons.notifications_active_outlined,
                        label: 'Přivolat obsluhu',
                        waiting: isWaiting(RequestType.obsluha),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: buildButton(
                        type: RequestType.platba,
                        icon: Icons.payments_outlined,
                        label: 'Chci zaplatit',
                        waiting: isWaiting(RequestType.platba),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildButton({
    required RequestType type,
    required IconData icon,
    required String label,
    required bool waiting,
  }) {
    return FilledButton.tonalIcon(
      // Když už požadavek čeká, tlačítko je neaktivní (null).
      onPressed: waiting ? null : () => sendRequest(type),
      icon: Icon(waiting ? Icons.hourglass_top : icon, size: 18),
      label: Text(
        waiting ? 'Obsluha o vás ví…' : label,
        textAlign: TextAlign.center,
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    );
  }
}
