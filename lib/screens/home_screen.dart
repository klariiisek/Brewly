import 'package:flutter/material.dart';

import 'menu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                  MaterialPageRoute(builder: (context) => const MenuScreen()),
                );
              },
              child: const Text('Prohlédnout menu'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () {}, child: const Text('Přihlásit se')),
          ],
        ),
      ),
    );
  }
}
