import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/order_history.dart';

// Obrazovka pro obsluhu: přehled všech objednávek a změna jejich stavu.
class StaffScreen extends StatefulWidget {
  final OrderHistory orderHistory;

  const StaffScreen({super.key, required this.orderHistory});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  Widget build(BuildContext context) {
    final orders = widget.orderHistory.orders;

    return Scaffold(
      appBar: AppBar(title: const Text('Obsluha – objednávky')),
      body: orders.isEmpty
          ? const Center(child: Text('Zatím nejsou žádné objednávky'))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                // Z položek udělá text, např. "2× Espresso, 1× Latte".
                final itemsText = order.items
                    .map((item) => '${item.quantity}× ${item.product.name}')
                    .join(', ');

                return Card(
                  child: ListTile(
                    title: Text(
                      'Stůl ${order.tableNumber} • ${orderStatusText(order.status)}',
                    ),
                    subtitle: Text('Objednávka ${index + 1}: $itemsText'),
                    trailing: ElevatedButton(
                      onPressed: order.status == OrderStatus.dokoncena
                          ? null
                          : () {
                              setState(() {
                                order.nextStatus();
                              });
                            },
                      child: const Text('Další stav'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
