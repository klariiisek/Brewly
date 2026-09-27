import 'package:flutter/material.dart';

import 'models/cart.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  // Košík (a s ním historie objednávek) se vytvoří jen jednou
  // při spuštění aplikace a pak se předává obrazovkám.
  final cart = Cart();
  runApp(MyApp(cart: cart));
}

class MyApp extends StatelessWidget {
  final Cart cart;

  const MyApp({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brewly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: HomeScreen(cart: cart),
    );
  }
}
