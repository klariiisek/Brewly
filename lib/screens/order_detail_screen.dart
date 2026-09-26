import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail objednávky'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Stav: ${orderStatusText(order.status)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: order.status == OrderStatus.dokoncena
                ? null
                : () {
                    setState(() {
                      order.nextStatus();
                    });
                  },
            child: const Text('Další stav'),
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
                    '${item.product.price * item.quantity} Kč',
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
