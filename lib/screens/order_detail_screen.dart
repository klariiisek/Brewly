import 'package:flutter/material.dart';

import '../utils/format.dart';
import '../models/order.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail objednávky'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Stůl ${order.tableNumber} • Stav: ${orderStatusText(order.status)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];

                return ListTile(
                  title: Text(item.product.name),
                  subtitle: Text('${item.quantity}×'),
                  trailing: Text(
                    formatPrice(item.product.price * item.quantity),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
