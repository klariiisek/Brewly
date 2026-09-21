import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

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
                // zatím nic
              },
              child: const Text('Přidat do košíku'),
            ),
          ],
        ),
      ),
    );
  }
}
