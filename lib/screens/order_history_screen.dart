import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';
import 'login_screen.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final AppServices services;

  // Volitelné: tlačítko "Přejít do menu" u prázdného seznamu.
  final VoidCallback? onGoToMenu;

  const OrderHistoryScreen({
    super.key,
    required this.services,
    this.onGoToMenu,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  // Proud přihlášeného uživatele.
  late final Stream<User?> userStream;

  // Proud objednávek pro aktuálního uživatele. Vytvoří se znovu jen tehdy,
  // když se přihlásí někdo jiný (aby se databáze nedotazovala zbytečně často).
  String? streamUserId;
  Stream<List<Order>>? ordersStream;

  @override
  void initState() {
    super.initState();
    userStream = widget.services.auth.userChanges();
  }

  Stream<List<Order>> ordersFor(String userId) {
    if (userId != streamUserId || ordersStream == null) {
      streamUserId = userId;
      ordersStream = widget.services.orders.watchMyOrders(userId);
    }
    return ordersStream!;
  }

  void openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(authService: widget.services.auth),
      ),
    );
  }

  Future<void> signOut() async {
    await widget.services.auth.signOut();
    if (!mounted) return;
    showAppMessage(context, 'Byli jste odhlášeni');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: userStream,
      // Než proud pošle první hodnotu, použije se aktuálně přihlášený uživatel.
      initialData: widget.services.auth.currentUser,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Moje objednávky'),
            actions: [
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Odhlásit se',
                  onPressed: signOut,
                ),
            ],
          ),
          body: user == null
              ? EmptyState(
                  icon: Icons.person_outline,
                  title: 'Přihlaste se',
                  message: 'Po přihlášení tu uvidíte své objednávky.',
                  buttonText: 'Přihlásit se',
                  onPressed: openLogin,
                )
              : buildOrders(user),
        );
      },
    );
  }

  Widget buildOrders(User user) {
    return StreamBuilder<List<Order>>(
      stream: ordersFor(user.uid),
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

        // Nejnovější objednávka nahoře.
        final orders = snapshot.data!.reversed.toList();

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
                orderService: widget.services.orders,
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
