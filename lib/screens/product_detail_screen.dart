import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../widgets/app_message.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final Cart cart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(product.category),
            const SizedBox(height: 10),
            Text('${product.price} Kč'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                cart.addItem(CartItem(product: product));
                showAppMessage(context, 'Přidáno do košíku');
              },
              child: const Text('Přidat do košíku'),
            ),
          ],
        ),
      ),
    );
  }
}
