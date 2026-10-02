import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import 'cart_screen.dart';
import 'menu_screen.dart';
import 'order_history_screen.dart';

// Hlavní obrazovka zákazníka se spodní lištou: Menu | Košík | Objednávky.
class MainScreen extends StatefulWidget {
  final Cart cart;
  final ProductService productService;
  final OrderService orderService;

  const MainScreen({
    super.key,
    required this.cart,
    required this.productService,
    required this.orderService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Která záložka je vybraná: 0 = Menu, 1 = Košík, 2 = Objednávky.
  int selectedIndex = 0;

  // Překreslí obrazovku (hlavně číslo u košíku v liště).
  void refresh() {
    setState(() {});
  }

  // Přepne na zvolenou záložku.
  void goToTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;

    return Scaffold(
      // IndexedStack drží všechny záložky "naživu", ale ukazuje jen jednu.
      // Díky tomu se třeba neztratí vybraný stůl v košíku při přepnutí.
      body: IndexedStack(
        index: selectedIndex,
        children: [
          MenuScreen(
            cart: cart,
            productService: widget.productService,
            onCartChanged: refresh,
          ),
          CartScreen(
            cart: cart,
            orderService: widget.orderService,
            onCartChanged: refresh,
            onOrderCreated: () => goToTab(2),
            onGoToMenu: () => goToTab(0),
          ),
          OrderHistoryScreen(
            orderHistory: cart.orderHistory,
            orderService: widget.orderService,
            onGoToMenu: () => goToTab(0),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: goToTab,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.local_cafe_outlined),
            selectedIcon: Icon(Icons.local_cafe),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('${cart.itemCount}'),
              isLabelVisible: cart.itemCount > 0,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              label: Text('${cart.itemCount}'),
              isLabelVisible: cart.itemCount > 0,
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'Košík',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Objednávky',
          ),
        ],
      ),
    );
  }
}
