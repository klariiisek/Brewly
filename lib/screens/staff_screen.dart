import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/order_service.dart';
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
  final OrderService orderService;

  const StaffScreen({super.key, required this.orderService});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  // Živý proud všech objednávek z databáze (vytvoří se jen jednou).
  late final Stream<List<Order>> ordersStream;

  @override
  void initState() {
    super.initState();
    ordersStream = widget.orderService.watchAllOrders();
  }

  // Uloží do databáze další stav objednávky. Obrazovka se pak překreslí
  // sama, protože databáze pošle změnu přes stream.
  Future<void> moveToNextStatus(Order order) async {
    try {
      await widget.orderService.moveToNextStatus(order);
      if (!mounted) return;
      showAppMessage(
        context,
        'Objednávka #${order.number}: '
        '${orderStatusText(nextOrderStatus(order.status))}',
      );
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Stav se nepodařilo změnit');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Obsluha')),
            body: const EmptyState(
              icon: Icons.cloud_off,
              title: 'Objednávky se nepodařilo načíst',
              message: 'Zkontrolujte připojení k internetu.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Obsluha')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return buildTabs(snapshot.data!);
      },
    );
  }

  Widget buildTabs(List<Order> orders) {
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
    final orderNumber = order.number;
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
                  onPressed: () => moveToNextStatus(order),
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
