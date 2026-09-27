import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/status_badge.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  final int orderNumber;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Objednávka #$orderNumber')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Stůl a stav objednávky.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.table_restaurant, color: AppColors.coffee),
                  const SizedBox(width: 12),
                  Text(
                    'Stůl ${order.tableNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCoffee,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge(status: order.status),
                ],
              ),
            ),
          ),

          // Položky objednávky a celková cena.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}×',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.coffee,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(item.product.name)),
                          Text(formatPrice(item.product.price * item.quantity)),
                        ],
                      ),
                    ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Celkem',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatPrice(order.totalPrice),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.coffee,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
