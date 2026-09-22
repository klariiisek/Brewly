import 'package:flutter/material.dart';
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
      body: ListView.builder(
        itemCount: order.items.length,
        itemBuilder: (context, index) {
          final item = order.items[index];

          return ListTile(
            title: Text(item.product.name),
            subtitle: Text('${item.quantity}×'),
            trailing: Text(
              '${item.product.price * item.quantity} Kč',
            ),
          );
        },
      ),
    );
  }
}