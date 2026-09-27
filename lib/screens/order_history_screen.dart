import 'package:flutter/material.dart';

import '../models/order_history.dart';
import 'order_detail_screen.dart';
import '../models/order.dart';
import '../utils/format.dart';

class OrderHistoryScreen extends StatefulWidget {
  final OrderHistory orderHistory;

  const OrderHistoryScreen({super.key, required this.orderHistory});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final orderHistory = widget.orderHistory;

    return Scaffold(
      appBar: AppBar(title: const Text('Moje objednávky')),
      body: ListView.builder(
        itemCount: orderHistory.orders.length,
        itemBuilder: (context, index) {
          final order = orderHistory.orders[index];

          return Card(
            child: ListTile(
              onTap: () async {
                // Počká, až se detail objednávky zavře...
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(order: order),
                  ),
                );
                // ...a pak překreslí seznam, aby byl vidět nový stav.
                setState(() {});
              },
              title: Text('Objednávka ${index + 1}'),
              subtitle: Text(
                'Stůl ${order.tableNumber} • ${order.items.length} položek • ${orderStatusText(order.status)}',
              ),
              trailing: Text(formatPrice(order.totalPrice)),
            ),
          );
        },
      ),
    );
  }
}
