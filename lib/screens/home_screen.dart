import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'staff_screen.dart';

class HomeScreen extends StatelessWidget {
  final Cart cart;
  final ProductService productService;

  const HomeScreen({
    super.key,
    required this.cart,
    required this.productService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Horní část: logo, název a uvítání.
              Expanded(child: buildWelcome()),
              // Spodní část: tlačítka.
              buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildWelcome() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo: hnědý čtverec s kulatými rohy a bílým šálkem.
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.coffee,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.coffee, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Brewly',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.darkCoffee,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vítejte v naší kavárně',
            style: TextStyle(fontSize: 17, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget buildButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MainScreen(
                    cart: cart,
                    productService: productService,
                  ),
                ),
              );
            },
            child: const Text('Prohlédnout menu'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            // Přihlášení zatím není hotové (přijde s Firebase).
            onPressed: () {},
            child: const Text('Přihlásit se'),
          ),
        ),
        const SizedBox(height: 8),
        // Dočasný vstup pro obsluhu, dokud nebudou přihlášení a role.
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    StaffScreen(orderHistory: cart.orderHistory),
              ),
            );
          },
          child: const Text('Vstup pro obsluhu'),
        ),
      ],
    );
  }
}
