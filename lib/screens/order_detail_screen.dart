import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

// Detail objednávky. Sleduje objednávku v databázi živě,
// takže zákazník hned vidí, když obsluha změní stav.
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final OrderService orderService;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.orderService,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final Stream<Order?> orderStream;

  @override
  void initState() {
    super.initState();
    orderStream = widget.orderService.watchOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Order?>(
      stream: orderStream,
      builder: (context, snapshot) {
        final order = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              order == null ? 'Objednávka' : 'Objednávka #${order.number}',
            ),
          ),
          body: buildBody(snapshot, order),
        );
      },
    );
  }

  Widget buildBody(AsyncSnapshot<Order?> snapshot, Order? order) {
    if (snapshot.hasError) {
      return const EmptyState(
        icon: Icons.cloud_off,
        title: 'Objednávku se nepodařilo načíst',
        message: 'Zkontrolujte připojení k internetu.',
      );
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (order == null) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Objednávka nenalezena',
        message: 'Tato objednávka už v databázi není.',
      );
    }

    return ListView(
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
    );
  }
}
