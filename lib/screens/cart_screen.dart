import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/order.dart';
import '../widgets/app_message.dart';
import '../utils/format.dart';

class CartScreen extends StatefulWidget {
  final Cart cart;

  // Zavolá se, když se změní obsah košíku (aby se aktualizovalo číslo v liště).
  final VoidCallback onCartChanged;

  // Zavolá se po vytvoření objednávky (přepne na záložku Objednávky).
  final VoidCallback onOrderCreated;

  const CartScreen({
    super.key,
    required this.cart,
    required this.onCartChanged,
    required this.onOrderCreated,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Počet stolů v kavárně.
  static const int tableCount = 10;

  // Vybraný stůl. Otazník (int?) znamená, že zatím nemusí být vybraný (null).
  int? selectedTable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Košík')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.cart.items.length,
              itemBuilder: (context, index) {
                final item = widget.cart.items[index];

                return ListTile(
                  title: Text(item.product.name),
                  subtitle: Text('${item.quantity}×'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (item.quantity > 1) {
                              item.quantity--;
                            } else {
                              widget.cart.items.removeAt(index);
                            }
                          });
                          widget.onCartChanged();
                        },
                      ),
                      Text('${item.quantity}×'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            item.quantity++;
                          });
                          widget.onCartChanged();
                        },
                      ),
                      const SizedBox(width: 10),
                      Text(formatPrice(item.product.price * item.quantity)),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Stůl:', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: selectedTable,
                  hint: const Text('Vyberte stůl'),
                  // Vytvoří nabídku stolů 1 až tableCount.
                  items: List.generate(tableCount, (index) {
                    final number = index + 1;
                    return DropdownMenuItem(
                      value: number,
                      child: Text('Stůl $number'),
                    );
                  }),
                  onChanged: (number) {
                    setState(() {
                      selectedTable = number;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Celkem: ${formatPrice(widget.cart.totalPrice)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.cart.items.isEmpty) {
                    showAppMessage(context, 'Košík je prázdný');
                    return;
                  }
                  if (selectedTable == null) {
                    showAppMessage(context, 'Vyberte prosím stůl');
                    return;
                  }
                  final order = Order(
                    items: List.from(widget.cart.items),
                    totalPrice: widget.cart.totalPrice,
                    tableNumber: selectedTable!,
                    status: OrderStatus.prijata,
                  );
                  widget.cart.orderHistory.addOrder(order);
                  setState(() {
                    widget.cart.items.clear();
                  });
                  showAppMessage(context, 'Objednávka byla vytvořena');
                  widget.onOrderCreated();
                },
                child: const Text('Objednat'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
