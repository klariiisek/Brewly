import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
import '../services/app_services.dart';
import '../widgets/app_message.dart';
import 'cart_screen.dart';
import 'menu_screen.dart';
import 'order_detail_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';

// Hlavní obrazovka zákazníka se spodní lištou: Menu | Košík | Objednávky | Profil.
//
// Aplikace zákazníka vede sama:
// - z menu se plovoucí lištou dostane rovnou do košíku,
// - po objednání se mu hned otevře sledování objednávky,
// - když je objednávka připravená, ukáže se upozornění, ať je kdekoli.
class MainScreen extends StatefulWidget {
  final Cart cart;
  final AppServices services;

  const MainScreen({super.key, required this.cart, required this.services});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Která záložka je vybraná: 0 = Menu, 1 = Košík, 2 = Objednávky, 3 = Profil.
  int selectedIndex = 0;

  // Hlídání objednávek přihlášeného zákazníka kvůli upozornění „připraveno“.
  StreamSubscription<User?>? userSubscription;
  StreamSubscription<List<Order>>? ordersSubscription;
  String? watchedUserId;

  // Poslední známý stav každé objednávky (podle ID).
  Map<String, OrderStatus>? lastStatuses;

  // Objednávky přihlášeného zákazníka – z nich se počítají razítka
  // na razítkové kartě (košík a profil).
  List<Order> myOrders = [];

  // Je přihlášená obsluha nebo admin? Pak je zákaznická část jen náhled:
  // vše jde prohlédnout, ale objednávat a volat obsluhu nejde
  // (zkreslilo by to statistiky a zmátlo obsluhu).
  StreamSubscription<UserProfile>? profileSubscription;
  bool isPreview = false;

  // Oblíbené produkty přihlášeného zákazníka (ID produktů).
  Set<String> favorites = {};

  @override
  void initState() {
    super.initState();
    final auth = widget.services.auth;
    watchOrdersOf(auth.currentUser);
    userSubscription = auth.userChanges().listen(watchOrdersOf);
  }

  @override
  void dispose() {
    userSubscription?.cancel();
    ordersSubscription?.cancel();
    profileSubscription?.cancel();
    super.dispose();
  }

  // Začne sledovat objednávky přihlášeného uživatele (po odhlášení přestane).
  void watchOrdersOf(User? user) {
    if (user?.uid == watchedUserId) return;
    watchedUserId = user?.uid;
    ordersSubscription?.cancel();
    profileSubscription?.cancel();
    lastStatuses = null;
    if (mounted) {
      setState(() {
        myOrders = [];
        isPreview = false;
        favorites = {};
      });
    }
    if (user == null) return;

    // Z profilu: role (náhled pro obsluhu/admina) a oblíbené produkty.
    profileSubscription = widget.services.users.watchProfile(user).listen(
      (profile) {
        if (!mounted) return;
        setState(() {
          isPreview = profile.role.canServe;
          favorites = profile.favorites.toSet();
        });
      },
      // Chyba (např. chvilku po odhlášení) = necháme poslední stav.
      onError: (Object error) {},
    );

    ordersSubscription = widget.services.orders
        .watchMyOrders(user.uid)
        .listen(checkForReadyOrders, onError: (Object error) {});
  }

  // Porovná nové stavy s předchozími. Když se objednávka právě teď
  // změnila na „Připravena“, ukáže upozornění.
  void checkForReadyOrders(List<Order> orders) {
    if (mounted) setState(() => myOrders = orders);
    final previous = lastStatuses;
    lastStatuses = {for (final order in orders) order.id: order.status};
    // Při prvním načtení jen zapamatujeme stavy – staré objednávky,
    // které už připravené byly, neoznamujeme.
    if (previous == null || !mounted) return;

    for (final order in orders) {
      final wasReady = previous[order.id] == OrderStatus.pripravena;
      if (order.status == OrderStatus.pripravena && !wasReady) {
        showReadyBanner(order);
      }
    }
  }

  // Výrazné upozornění nahoře, které zůstane, dokud ho zákazník nezavře.
  void showReadyBanner(Order order) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        leading: const Text('🎉', style: TextStyle(fontSize: 28)),
        content: Text(
          'Vaše objednávka č. ${order.number} je připravená!',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              openOrder(order.id);
            },
            child: const Text('Zobrazit'),
          ),
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Srdíčko u produktu: přidá / odebere oblíbený produkt.
  // Nepřihlášený zákazník se nejdřív musí přihlásit (oblíbené jsou u účtu).
  Future<void> toggleFavorite(Product product) async {
    final user = widget.services.auth.currentUser;
    if (user == null) {
      showAppMessage(context, 'Pro oblíbené produkty se prosím přihlaste');
      return;
    }
    final isFavorite = !favorites.contains(product.id);
    try {
      await widget.services.users.setFavorite(user.uid, product.id, isFavorite);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Oblíbené se nepodařilo uložit');
    }
  }

  // Překreslí obrazovku (hlavně číslo u košíku v liště).
  void refresh() {
    setState(() {});
  }

  // Přepne na zvolenou záložku.
  void goToTab(int index) {
    // Staré hlášení schováme, aby na nové záložce nepřekrývalo tlačítka.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      selectedIndex = index;
    });
  }

  // Otevře detail objednávky se sledováním průběhu.
  void openOrder(String orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          orderId: orderId,
          orderService: widget.services.orders,
        ),
      ),
    );
  }

  // Po odeslání objednávky: pod detail dáme záložku Objednávky
  // a rovnou otevřeme sledování nové objednávky.
  void onOrderCreated(String orderId) {
    goToTab(2);
    openOrder(orderId);
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;

    return Scaffold(
      // IndexedStack drží všechny záložky "naživu", ale ukazuje jen jednu.
      // Díky tomu se třeba neztratí obsah košíku při přepnutí.
      body: IndexedStack(
        index: selectedIndex,
        children: [
          MenuScreen(
            cart: cart,
            productService: widget.services.products,
            onCartChanged: refresh,
            onOpenCart: () => goToTab(1),
            favorites: favorites,
            onToggleFavorite: toggleFavorite,
          ),
          CartScreen(
            cart: cart,
            services: widget.services,
            myOrders: myOrders,
            isPreview: isPreview,
            onCartChanged: refresh,
            onOrderCreated: onOrderCreated,
            onGoToMenu: () => goToTab(0),
          ),
          OrderHistoryScreen(
            services: widget.services,
            cart: cart,
            isPreview: isPreview,
            onGoToMenu: () => goToTab(0),
          ),
          ProfileScreen(services: widget.services, myOrders: myOrders),
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
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
