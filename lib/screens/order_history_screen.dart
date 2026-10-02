import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/order_history.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final OrderHistory orderHistory;
  final OrderService orderService;

  // Volitelné: tlačítko "Přejít do menu" u prázdného seznamu.
  final VoidCallback? onGoToMenu;

  const OrderHistoryScreen({
    super.key,
    required this.orderHistory,
    required this.orderService,
    this.onGoToMenu,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  // Živý proud objednávek z databáze (vytvoří se jen jednou).
  late final Stream<List<Order>> ordersStream;

  @override
  void initState() {
    super.initState();
    ordersStream = widget.orderService.watchAllOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje objednávky')),
      body: StreamBuilder<List<Order>>(
        stream: ordersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.cloud_off,
              title: 'Objednávky se nepodařilo načíst',
              message: 'Zkontrolujte připojení k internetu.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Jen "moje" objednávky (odeslané z tohoto zařízení),
          // nejnovější nahoře.
          final myIds = widget.orderHistory.orderIds;
          final orders = snapshot.data!
              .where((order) => myIds.contains(order.id))
              .toList()
              .reversed
              .toList();

          if (orders.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Zatím nemáte žádné objednávky',
              message: 'Vaše objednávky se zobrazí tady.',
              buttonText: 'Přejít do menu',
              onPressed: widget.onGoToMenu,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            itemCount: orders.length,
            itemBuilder: (context, index) => buildOrderCard(orders[index]),
          );
        },
      ),
    );
  }

  Widget buildOrderCard(Order order) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(
                orderId: order.id,
                orderService: widget.orderService,
              ),
            ),
          );
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
                      'Objednávka #${order.number}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkCoffee,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stůl ${order.tableNumber} • ${formatItemCount(order.items.length)}',
                      style: const TextStyle(color: AppColors.muted),
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
  }
}
