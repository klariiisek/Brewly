import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/cart_item.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';
import '../widgets/table_code_sheet.dart';
import 'login_screen.dart';

class CartScreen extends StatefulWidget {
  final Cart cart;
  final AppServices services;

  // Zavolá se, když se změní obsah košíku (aby se aktualizovalo číslo v liště).
  final VoidCallback onCartChanged;

  // Zavolá se po vytvoření objednávky (přepne na záložku Objednávky).
  final VoidCallback onOrderCreated;

  // Zavolá se z prázdného košíku tlačítkem "Přejít do menu".
  final VoidCallback onGoToMenu;

  const CartScreen({
    super.key,
    required this.cart,
    required this.services,
    required this.onCartChanged,
    required this.onOrderCreated,
    required this.onGoToMenu,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void increase(CartItem item) {
    setState(() {
      item.quantity++;
    });
    widget.onCartChanged();
  }

  // Sníží množství. Když je jen 1 kus, položku z košíku odebere.
  void decrease(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
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
      showAppMessage(context, 'Pro objednání se prosím přihlaste');
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
      await widget.services.orders.createOrder(
        items: widget.cart.items,
        totalPrice: widget.cart.totalPrice,
        tableNumber: widget.cart.tableNumber!,
        tableCode: widget.cart.tableCode!,
        userId: user.uid,
        customerName: userDisplayName(user),
      );
      if (!mounted) return;

      setState(() {
        widget.cart.items.clear();
      });
      widget.onCartChanged();
      showAppMessage(context, 'Objednávka byla odeslána');
      widget.onOrderCreated();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      if (error.code == 'permission-denied') {
        // Databáze odmítla kód stolu (špatně opsaný nebo už neplatný).
        setState(() => widget.cart.clearTable());
        showAppMessage(
          context,
          'Kód stolu neplatí. Naskenujte prosím QR kód na stole znovu.',
        );
      } else {
        showAppMessage(context, 'Objednávku se nepodařilo odeslat');
      }
    } catch (error) {
      // Např. bez internetu: košík zůstane, zákazník to může zkusit znovu.
      if (!mounted) return;
      showAppMessage(context, 'Objednávku se nepodařilo odeslat');
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
    final items = widget.cart.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Košík')),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Košík je prázdný',
              message: 'Vyberte si něco dobrého z menu.',
              buttonText: 'Přejít do menu',
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
            ),
    );
  }

  // Karta jedné položky: ikona, název, cena a tlačítka − / +.
  Widget buildCartItem(CartItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.coffee.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(
                categoryIcon(item.product.category),
                color: AppColors.coffee,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCoffee,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPrice(item.product.price * item.quantity),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.coffee,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              // U posledního kusu se místo "−" ukáže koš.
              icon: Icon(
                item.quantity > 1 ? Icons.remove : Icons.delete_outline,
              ),
              tooltip: item.quantity > 1 ? 'Snížit množství' : 'Odebrat',
              onPressed: () => decrease(item),
            ),
            Text(
              '${item.quantity}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Zvýšit množství',
              onPressed: () => increase(item),
            ),
          ],
        ),
      ),
    );
  }

  // Bílý panel dole: výběr stolu, celková cena a tlačítko Objednat.
  Widget buildOrderPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.coffee.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Stůl',
                style: TextStyle(fontSize: 16, color: AppColors.muted),
              ),
              const Spacer(),
              // Stůl z QR kódu. Kliknutím se dá zadat kód stolu ručně.
              TextButton.icon(
                icon: const Icon(Icons.qr_code_2, size: 20),
                label: Text(
                  widget.cart.hasTable
                      ? 'Stůl ${widget.cart.tableNumber}'
                      : 'Zadat kód stolu',
                ),
                onPressed: () async {
                  await askForTableCode(context, widget.cart);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Text(
                'Celkem',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                formatPrice(widget.cart.totalPrice),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.coffee,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // Během odesílání je tlačítko neaktivní (null), aby se
              // objednávka neodeslala dvakrát.
              onPressed: isSending ? null : placeOrder,
              child: Text(isSending ? 'Odesílám…' : 'Objednat'),
            ),
          ),
        ],
      ),
    );
  }
}
