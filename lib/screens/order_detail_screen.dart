import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/order_progress.dart';

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
        // Průběh objednávky – živě se mění, jak obsluha posouvá stav.
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Column(
              children: [
                OrderProgress(status: order.status),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.table_restaurant,
                        size: 18, color: context.colors.muted),
                    const SizedBox(width: 6),
                    Text(
                      'Stůl ${order.tableNumber} • ${formatOrderDate(order.time)}',
                      style: TextStyle(color: context.colors.muted),
                    ),
                  ],
                ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.colors.primary,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
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
