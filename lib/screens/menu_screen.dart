import 'package:flutter/material.dart';

import '../models/product.dart';
import 'product_detail_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

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
      appBar: AppBar(title: const Text('Menu')),
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
                    builder: (context) => ProductDetailScreen(product: product),
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
