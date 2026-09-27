import 'package:flutter/material.dart';

import '../models/cart.dart';
import 'main_screen.dart';
import 'staff_screen.dart';

class HomeScreen extends StatelessWidget {
  final Cart cart;

  const HomeScreen({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('☕', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            const Text(
              'BREWLY',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Vítejte v naší kavárně',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MainScreen(cart: cart)),
                );
              },
              child: const Text('Prohlédnout menu'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () {}, child: const Text('Přihlásit se')),
            const SizedBox(height: 10),
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
              child: const Text('Obsluha'),
            ),
          ],
        ),
      ),
    );
  }
}
