import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/order_history.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

// Text tlačítka podle toho, co obsluha s objednávkou udělá jako další.
String nextStatusAction(OrderStatus status) {
  switch (status) {
    case OrderStatus.prijata:
      return 'Začít připravovat';
    case OrderStatus.pripravujeSe:
      return 'Označit jako připravenou';
    case OrderStatus.pripravena:
      return 'Předáno zákazníkovi';
    case OrderStatus.dokoncena:
      return 'Dokončeno';
  }
}

// Obrazovka pro obsluhu: aktivní a dokončené objednávky, změna stavu.
class StaffScreen extends StatefulWidget {
  final OrderHistory orderHistory;

  const StaffScreen({super.key, required this.orderHistory});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  void moveToNextStatus(Order order, int orderNumber) {
    setState(() {
      order.nextStatus();
    });
    showAppMessage(
      context,
      'Objednávka #$orderNumber: ${orderStatusText(order.status)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = widget.orderHistory.orders;

    // Rozdělení objednávek na aktivní a dokončené.
    // Aktivní: nejstarší nahoře, aby obsluha vyřizovala objednávky popořadě.
    final activeOrders =
        orders.where((order) => order.status != OrderStatus.dokoncena).toList();
    // Dokončené: nejnovější nahoře.
    final doneOrders = orders
        .where((order) => order.status == OrderStatus.dokoncena)
        .toList()
        .reversed
        .toList();

    // DefaultTabController řídí přepínání mezi záložkami nahoře.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Obsluha'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Aktivní (${activeOrders.length})'),
              Tab(text: 'Dokončené (${doneOrders.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildOrderList(
              activeOrders,
              emptyState: const EmptyState(
                icon: Icons.coffee_maker_outlined,
                title: 'Žádné aktivní objednávky',
                message: 'Nové objednávky od zákazníků se objeví tady.',
              ),
            ),
            buildOrderList(
              doneOrders,
              emptyState: const EmptyState(
                icon: Icons.task_alt,
                title: 'Zatím nic dokončeného',
                message: 'Vyřízené objednávky se přesunou sem.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOrderList(List<Order> orders, {required Widget emptyState}) {
    if (orders.isEmpty) {
      return emptyState;
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) => buildOrderCard(orders[index]),
    );
  }

  // Karta jedné objednávky pro obsluhu.
  Widget buildOrderCard(Order order) {
    // Číslo objednávky podle pořadí v celé historii (#1 = první objednávka).
    final orderNumber = widget.orderHistory.orders.indexOf(order) + 1;
    final isDone = order.status == OrderStatus.dokoncena;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stůl, číslo objednávky a stav.
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.coffee.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Center(
                    child: Text(
                      '${order.tableNumber}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.coffee,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stůl ${order.tableNumber}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkCoffee,
                        ),
                      ),
                      Text(
                        'Objednávka #$orderNumber • ${formatPrice(order.totalPrice)}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: order.status),
              ],
            ),
            const Divider(height: 24),

            // Položky objednávky.
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '${item.quantity}× ${item.product.name}',
                  style: const TextStyle(fontSize: 15),
                ),
              ),

            // Tlačítko pro posun na další stav (u dokončených se nezobrazí).
            if (!isDone) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => moveToNextStatus(order, orderNumber),
                  child: Text(nextStatusAction(order.status)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
