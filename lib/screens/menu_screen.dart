import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

class MenuScreen extends StatelessWidget {
  final Cart cart;

  MenuScreen({super.key}) : cart = Cart();

  final List<Product> products = const [
    Product(name: 'Espresso', price: 45, category: 'Káva'),
    Product(name: 'Cappuccino', price: 65, category: 'Káva'),
    Product(name: 'Latte', price: 70, category: 'Káva'),
    Product(name: 'Cheesecake', price: 85, category: 'Dezerty'),
    Product(name: 'Tiramisu', price: 90, category: 'Dezerty'),
    Product(name: 'Domácí limonáda', price: 55, category: 'Nápoje'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen(cart: cart)),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailScreen(product: product, cart: cart),
                  ),
                );
              },
              title: Text(product.name),
              subtitle: Text(product.category),
              trailing: Text('${product.price} Kč'),
            ),
          );
        },
      ),
    );
  }
}
