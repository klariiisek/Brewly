import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/service_request.dart';
import '../models/venue_settings.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';
import 'staff_tables_screen.dart';

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

// Obrazovka pro obsluhu: požadavky zákazníků, aktivní a dokončené objednávky.
class StaffScreen extends StatefulWidget {
  final AppServices services;

  const StaffScreen({super.key, required this.services});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  // Živé proudy z databáze (vytvoří se jen jednou).
  late final Stream<List<Order>> ordersStream;
  late final Stream<List<ServiceRequest>> requestsStream;

  @override
  void initState() {
    super.initState();
    ordersStream = widget.services.orders.watchAllOrders();
    requestsStream = widget.services.requests.watchPendingRequests();
  }

  // Označí požadavek zákazníka jako vyřízený – zmizí ze seznamu.
  Future<void> markRequestDone(ServiceRequest request) async {
    try {
      await widget.services.requests.markDone(request.id);
      if (!mounted) return;
      showAppMessage(context, 'Stůl ${request.tableNumber}: vyřízeno');
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Požadavek se nepodařilo vyřídit');
    }
  }

  // Otevřeno / zavřeno. Když je zavřeno, zákazníci nemůžou objednávat.
  Future<void> setOpen(bool isOpen) async {
    try {
      await widget.services.settings.setOpen(isOpen);
      if (!mounted) return;
      showAppMessage(
        context,
        isOpen
            ? 'Otevřeno – zákazníci můžou objednávat'
            : 'Zavřeno – nové objednávky nejdou odeslat',
      );
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Změnu se nepodařilo uložit');
    }
  }

  // Uloží do databáze další stav objednávky. Obrazovka se pak překreslí
  // sama, protože databáze pošle změnu přes stream.
  Future<void> moveToNextStatus(Order order) async {
    try {
      await widget.services.orders.moveToNextStatus(order);
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
        final orders = snapshot.data!;

        // Druhý proud: požadavky zákazníků (než dorazí, bereme prázdný seznam).
        return StreamBuilder<List<ServiceRequest>>(
          stream: requestsStream,
          builder: (context, requestSnapshot) {
            return buildTabs(orders, requestSnapshot.data ?? []);
          },
        );
      },
    );
  }

  Widget buildTabs(List<Order> orders, List<ServiceRequest> requests) {
    // Rozdělení objednávek na aktivní a dokončené.
    // Aktivní: nejstarší nahoře, aby obsluha vyřizovala objednávky popořadě.
    final activeOrders =
        orders.where((order) => order.status != OrderStatus.dokoncena).toList();
    // Dokončené: jen dnešní, nejnovější nahoře (starší jsou v historii).
    final doneOrders = orders
        .where((order) =>
            order.status == OrderStatus.dokoncena && isToday(order.time))
        .toList()
        .reversed
        .toList();

    // DefaultTabController řídí přepínání mezi záložkami nahoře.
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Obsluha'),
          actions: [
            buildOpenSwitch(),
            IconButton(
              icon: const Icon(Icons.qr_code_2),
              tooltip: 'Stoly a QR kódy',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaffTablesScreen(
                      tableService: widget.services.tables,
                    ),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            // Tři záložky se nemusí vejít – dají se posouvat do stran.
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Požadavky (${requests.length})'),
              Tab(text: 'Aktivní (${activeOrders.length})'),
              Tab(text: 'Dokončené (${doneOrders.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildRequestList(requests),
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
                title: 'Dnes zatím nic dokončeného',
                message: 'Dnešní vyřízené objednávky se přesunou sem.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Přepínač v horní liště: "Otevřeno" / "Zavřeno".
  Widget buildOpenSwitch() {
    final isOpen = VenueScope.of(context).isOpen;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isOpen ? 'Otevřeno' : 'Zavřeno',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isOpen
                ? AppColors.success
                : Theme.of(context).colorScheme.error,
          ),
        ),
        Switch(
          value: isOpen,
          onChanged: setOpen,
        ),
      ],
    );
  }

  Widget buildRequestList(List<ServiceRequest> requests) {
    if (requests.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none,
        title: 'Žádné požadavky',
        message: 'Když zákazník přivolá obsluhu nebo chce zaplatit, '
            'objeví se to tady.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: requests.length,
      itemBuilder: (context, index) => buildRequestCard(requests[index]),
    );
  }

  // Karta požadavku: stůl, co zákazník chce, kdo a kdy, tlačítko Vyřízeno.
  Widget buildRequestCard(ServiceRequest request) {
    final isPayment = request.type == RequestType.platba;
    // Platba karamelově, přivolání hnědě.
    final color = isPayment ? context.colors.accent : context.colors.primary;
    final time = request.createdAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(
                isPayment
                    ? Icons.payments_outlined
                    : Icons.notifications_active_outlined,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stůl ${request.tableNumber} • ${requestTypeText(request.type)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.colors.dark,
                    ),
                  ),
                  Text(
                    time == null
                        ? request.customerName
                        : '${request.customerName} • ${formatTime(time)}',
                    style: TextStyle(color: context.colors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => markRequestDone(request),
              child: const Text('Vyřízeno'),
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
                    color: context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Center(
                    child: Text(
                      '${order.tableNumber}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
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
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: context.colors.dark,
                        ),
                      ),
                      Text(
                        // Starší objednávky jméno zákazníka nemají.
                        order.customerName.isEmpty
                            ? '#$orderNumber • ${formatOrderDate(order.time)} • '
                                '${formatPrice(order.totalPrice)}'
                            : '#$orderNumber • ${formatOrderDate(order.time)} • '
                                '${order.customerName} • '
                                '${formatPrice(order.totalPrice)}',
                        style: TextStyle(color: context.colors.muted),
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
