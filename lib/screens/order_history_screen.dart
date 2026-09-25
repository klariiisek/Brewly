import 'package:flutter/material.dart';

import '../models/order_history.dart';
import 'order_detail_screen.dart';
import '../models/order.dart';

class OrderHistoryScreen extends StatelessWidget {
  final OrderHistory orderHistory;

  const OrderHistoryScreen({super.key, required this.orderHistory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historie objednávek')),
      body: ListView.builder(
        itemCount: orderHistory.orders.length,
        itemBuilder: (context, index) {
          final order = orderHistory.orders[index];

          return Card(
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(order: order),
                  ),
                );
              },
              title: Text('Objednávka ${index + 1}'),
              subtitle: Text(
  '${order.items.length} položek • ${orderStatusText(order.status)}',
),
              trailing: Text('${order.totalPrice} Kč'),
            ),
          );
        },
      ),
    );
  }
}
