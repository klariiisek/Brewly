import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/loyalty.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/venue_settings.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/drink_icon.dart';
import '../widgets/table_code_sheet.dart';
import 'login_screen.dart';
import '../l10n/language.dart';

class CartScreen extends StatefulWidget {
  final Cart cart;
  final AppServices services;

  // Objednávky zákazníka – podle nich se počítají razítka na kartě.
  final List<Order> myOrders;

  // Náhled pro obsluhu/admina: košík funguje, ale objednat nejde.
  final bool isPreview;

  // Zavolá se, když se změní obsah košíku (aby se aktualizovalo číslo v liště).
  final VoidCallback onCartChanged;

  // Zavolá se po vytvoření objednávky s jejím ID (aplikace ji rovnou otevře).
  final ValueChanged<String> onOrderCreated;

  // Zavolá se z prázdného košíku tlačítkem "Přejít do menu".
  final VoidCallback onGoToMenu;

  const CartScreen({
    super.key,
    required this.cart,
    required this.services,
    this.myOrders = const [],
    this.isPreview = false,
    required this.onCartChanged,
    required this.onOrderCreated,
    required this.onGoToMenu,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Živé menu z databáze – košík podle něj hlídá ceny a vyprodané produkty.
  late final Stream<List<Product>> productsStream;

  @override
  void initState() {
    super.initState();
    productsStream = widget.services.products.watchProducts();
  }

  void increase(CartItem item) {
    setState(() {
      item.quantity++;
    });
    widget.onCartChanged();
  }

  // Sníží množství. Když je jen 1 kus, položku z košíku odebere.
  // Vyprodanou nebo smazanou položku odebere celou najednou.
  void decrease(CartItem item) {
    setState(() {
      if (item.quantity > 1 && item.canOrder) {
        item.quantity--;
      } else {
        widget.cart.items.remove(item);
      }
    });
    widget.onCartChanged();
  }

  // Odesílá se právě objednávka? (Tlačítko se mezitím zablokuje.)
  bool isSending = false;

  Future<void> placeOrder() async {
    // Pojistka: když má podnik zavřeno, objednat nejde.
    if (!VenueScope.of(context).isOpen) {
      showAppMessage(context, context.t.closedCannotOrder);
      return;
    }

    // Pojistka: s vyprodaným produktem v košíku nejde objednat.
    if (widget.cart.hasUnavailableItems) {
      showAppMessage(context, context.t.removeSoldOutFirst);
      return;
    }

    // Bez stolu (z QR kódu) nelze objednat – zeptáme se na kód stolu.
    if (!widget.cart.hasTable) {
      final hasTable = await askForTableCode(context, widget.cart);
      if (!hasTable || !mounted) return;
      setState(() {});
    }

    // Objednávat může jen přihlášený zákazník. Když není přihlášený,
    // otevře se přihlášení a po něm se objednávka dokončí.
    var user = widget.services.auth.currentUser;
    if (user == null) {
      showAppMessage(context, context.t.signInToOrder);
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LoginScreen(authService: widget.services.auth),
        ),
      );
      user = widget.services.auth.currentUser;
      if (loggedIn != true || user == null || !mounted) return;
    }

    setState(() {
      isSending = true;
    });

    try {
      // Uloží objednávku do databáze i s tím, kdo ji vytvořil.
      final orderId = await widget.services.orders.createOrder(
        items: widget.cart.items,
        totalPrice: widget.cart.totalPrice,
        tableNumber: widget.cart.tableNumber!,
        tableCode: widget.cart.tableCode!,
        userId: user.uid,
        customerName: userDisplayName(user),
        rewardProductId: widget.cart.rewardItem?.product.id,
        rewardDiscount: widget.cart.rewardDiscount,
        // Kolik razítek odměna stojí teď – kdyby admin počet později
        // změnil, tahle odměna se nepřepočítá.
        // (Každá 10. káva zdarma = odměna stojí 9 razítek.)
        rewardStamps: VenueScope.of(context).loyaltyGoal - 1,
      );
      if (!mounted) return;

      setState(() {
        widget.cart.clear();
      });
      widget.onCartChanged();
      showAppMessage(context, context.t.orderSent);
      widget.onOrderCreated(orderId);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      if (error.code == 'permission-denied' && !VenueScope.of(context).isOpen) {
        // Podnik mezitím zavřel – databáze objednávku odmítla.
        showAppMessage(context, context.t.closedCannotOrder);
      } else if (error.code == 'permission-denied' &&
          widget.cart.rewardItem != null) {
        // Databáze odmítla odměnu – např. admin mezitím změnil počet razítek
        // nebo kartu vypnul. Odměnu zrušíme, zákazník může objednat znovu.
        setState(widget.cart.clearReward);
        showAppMessage(
          context,
          context.t.rewardFailed,
        );
      } else if (error.code == 'permission-denied') {
        // Databáze objednávku odmítla. Nejčastěji kvůli kódu stolu (špatně
        // opsaný nebo už neplatný), ale může to být i špatné datum v telefonu
        // (číslo objednávky se počítá podle dnešního dne). Přesný důvod
        // databáze neprozradí, proto zmíníme obojí.
        setState(() => widget.cart.clearTable());
        showAppMessage(
          context,
          context.t.orderDenied,
        );
      } else {
        showAppMessage(context, context.t.orderFailed);
      }
    } catch (error) {
      // Např. bez internetu: košík zůstane, zákazník to může zkusit znovu.
      if (!mounted) return;
      showAppMessage(context, context.t.orderFailed);
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.navCart)),
      // Při každé změně menu (cena, vyprodáno, smazání) se košík překreslí.
      body: StreamBuilder<List<Product>>(
        stream: productsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            widget.cart.syncWithMenu(snapshot.data!);
          }
          return buildBody();
        },
      ),
    );
  }

  Widget buildBody() {
    final items = widget.cart.items;

    return items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: context.t.cartEmpty,
              message: context.t.cartEmptyHint,
              buttonText: context.t.goToMenu,
              onPressed: widget.onGoToMenu,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return buildCartItem(items[index]);
                    },
                  ),
                ),
                buildOrderPanel(),
              ],
            );
  }

  // Karta jedné položky: ikona, název, cena a tlačítka − / +.
  // Vyprodaná nebo smazaná položka je zešedlá, s upozorněním a košem.
  Widget buildCartItem(CartItem item) {
    final problem = !item.isInMenu
        ? context.t.noLongerOffered
        : !item.product.isAvailable
            ? context.t.soldOutRemove
            : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: problem == null ? 1 : 0.5,
                child: buildItemInfo(item),
              ),
            ),
            if (problem != null)
              // Jen tlačítko pro odebrání a krátké vysvětlení.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: context.t.remove,
                    onPressed: () => decrease(item),
                  ),
                  Text(
                    problem,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              )
            else ...[
              IconButton(
                // U posledního kusu se místo "−" ukáže koš.
                icon: Icon(
                  item.quantity > 1 ? Icons.remove : Icons.delete_outline,
                ),
                tooltip: item.quantity > 1
                    ? context.t.decreaseQuantity
                    : context.t.remove,
                onPressed: () => decrease(item),
              ),
              Text(
                '${item.quantity}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: context.t.increaseQuantity,
                onPressed: () => increase(item),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Ikona kategorie, název a cena položky.
  Widget buildItemInfo(CartItem item) {
    return Row(
          children: [
            ProductIcon(product: item.product, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.colors.dark,
                    ),
                  ),
                  // Zvolené možnosti, např. „Mléko: Ovesné“.
                  if (item.options.isNotEmpty)
                    Text(
                      item.optionsText,
                      style: TextStyle(fontSize: 13, color: context.colors.muted),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    formatPrice(item.totalPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
    );
  }

  // Bílý panel dole: výběr stolu, celková cena a tlačítko Objednat.
  Widget buildOrderPanel() {
    // Otevřeno / zavřeno podle nastavení podniku (přepíná obsluha).
    final isOpen = VenueScope.of(context).isOpen;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                context.t.table,
                style: TextStyle(fontSize: 16, color: context.colors.muted),
              ),
              const Spacer(),
              // Stůl z QR kódu. Kliknutím se dá zadat kód stolu ručně.
              TextButton.icon(
                icon: const Icon(Icons.qr_code_2, size: 20),
                label: Text(
                  widget.cart.hasTable
                      ? context.t.tableTitle(widget.cart.tableNumber!)
                      : context.t.enterTableCode,
                ),
                onPressed: () async {
                  await askForTableCode(context, widget.cart);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          const Divider(height: 24),
          buildReward(),
          Row(
            children: [
              Text(
                context.t.total,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                formatPrice(widget.cart.totalPrice),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          // Upozornění, proč teď nejde objednat.
          if (widget.isPreview) ...[
            const SizedBox(height: 12),
            Text(
              context.t.previewOnly,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.muted),
            ),
          ] else if (!isOpen) ...[
            const SizedBox(height: 12),
            Text(
              context.t.closedCannotOrderDot,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ] else if (widget.cart.hasUnavailableItems) ...[
            const SizedBox(height: 12),
            Text(
              context.t.soldOutInCart,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // Během odesílání je tlačítko neaktivní (null), aby se
              // objednávka neodeslala dvakrát. Neaktivní je i tehdy,
              // když je v košíku něco vyprodaného.
              onPressed: isSending ||
                      widget.isPreview ||
                      !isOpen ||
                      widget.cart.hasUnavailableItems
                  ? null
                  : placeOrder,
              child: Text(isSending ? context.t.sending : context.t.placeOrder),
            ),
          ),
        ],
      ),
    );
  }

  // Razítková karta v košíku: kolik razítek chybí, nebo tlačítko
  // „Uplatnit odměnu“, když má zákazník plnou kartu.
  Widget buildReward() {
    final venue = VenueScope.of(context);
    final cart = widget.cart;
    if (!venue.hasLoyalty || widget.services.auth.currentUser == null) {
      return const SizedBox.shrink();
    }
    final status = loyaltyStatus(
      widget.myOrders,
      categoryId: venue.loyaltyCategoryId,
      goal: venue.loyaltyGoal,
    );
    final colors = context.colors;
    final rewardItem = cart.rewardItem;

    Widget row(IconData icon, String text, {Widget? trailing, Color? color}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: TextStyle(color: color ?? colors.dark)),
            ),
            ?trailing, // ? = přidá se, jen když není null
          ],
        ),
      );
    }

    // Odměna je uplatněná: ukážeme slevu a možnost ji zrušit.
    if (rewardItem != null) {
      return row(
        Icons.card_giftcard,
        context.t.rewardFree(
          rewardItem.product.name,
          formatPrice(cart.rewardDiscount),
        ),
        color: AppColors.success,
        trailing: TextButton(
          onPressed: () => setState(cart.clearReward),
          child: Text(context.t.cancel),
        ),
      );
    }
    if (!status.hasReward) {
      return row(
        Icons.loyalty_outlined,
        context.t.loyaltyProgress(
          '${status.filled}',
          '${status.needed}',
          context.t.stampCount(status.missing),
        ),
      );
    }
    // Plná karta, ale v košíku není nic z kategorie karty.
    final best = cart.bestRewardItem(venue.loyaltyCategoryId);
    if (best == null) {
      return row(
        Icons.card_giftcard,
        context.t.loyaltyFullHint,
        color: AppColors.success,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.card_giftcard),
          label: Text(context.t.useReward(best.product.name)),
          onPressed: () {
            setState(() => cart.useReward(venue.loyaltyCategoryId));
            widget.onCartChanged();
          },
        ),
      ),
    );
  }
}
