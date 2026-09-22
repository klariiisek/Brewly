import 'package:flutter/material.dart';

import '../models/cart.dart';

class CartScreen extends StatefulWidget {
  final Cart cart;

  const CartScreen({super.key, required this.cart});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
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
                        },
                      ),
                      Text('${item.quantity}×'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            item.quantity++;
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      Text('${item.product.price * item.quantity} Kč'),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Celkem: ${widget.cart.totalPrice} Kč',
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Košík je prázdný'),
      ),
    );
    return;
  }

  setState(() {
    widget.cart.items.clear();
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Objednávka byla vytvořena'),
    ),
  );
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
