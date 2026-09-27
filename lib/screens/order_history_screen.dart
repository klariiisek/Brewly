import 'package:flutter/material.dart';

import '../models/order_history.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final OrderHistory orderHistory;

  // Volitelné: tlačítko "Přejít do menu" u prázdného seznamu.
  final VoidCallback? onGoToMenu;

  const OrderHistoryScreen({
    super.key,
    required this.orderHistory,
    this.onGoToMenu,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final orders = widget.orderHistory.orders;

    return Scaffold(
      appBar: AppBar(title: const Text('Moje objednávky')),
      body: orders.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Zatím nemáte žádné objednávky',
              message: 'Vaše objednávky se zobrazí tady.',
              buttonText: 'Přejít do menu',
              onPressed: widget.onGoToMenu,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                // Nejnovější objednávka nahoře: bereme seznam od konce.
                final orderIndex = orders.length - 1 - index;
                final order = orders[orderIndex];
                final orderNumber = orderIndex + 1;

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      // Počká, až se detail objednávky zavře...
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailScreen(
                            order: order,
                            orderNumber: orderNumber,
                          ),
                        ),
                      );
                      // ...a pak překreslí seznam, aby byl vidět nový stav.
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Objednávka #$orderNumber',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkCoffee,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Stůl ${order.tableNumber} • ${formatItemCount(order.items.length)}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              StatusBadge(status: order.status),
                              const SizedBox(height: 8),
                              Text(
                                formatPrice(order.totalPrice),
                                style: const TextStyle(
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
                );
              },
            ),
    );
  }
}
