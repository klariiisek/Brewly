import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/cart.dart';
import 'screens/home_screen.dart';
import 'services/order_service.dart';
import 'services/product_service.dart';
import 'theme/app_theme.dart';

// "async" protože před spuštěním aplikace musíme počkat na připojení k Firebase.
Future<void> main() async {
  // Připraví Flutter, aby šlo něco udělat ještě před runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Připojí aplikaci k Firebase projektu (údaje jsou ve firebase_options.dart).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Košík (a s ním historie objednávek) se vytvoří jen jednou
  // při spuštění aplikace a pak se předává obrazovkám.
  final cart = Cart();

  // Služby pro produkty a objednávky pracují se skutečnou databází Firestore.
  final productService = ProductService(FirebaseFirestore.instance);
  final orderService = OrderService(FirebaseFirestore.instance);

  runApp(
    MyApp(
      cart: cart,
      productService: productService,
      orderService: orderService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final Cart cart;
  final ProductService productService;
  final OrderService orderService;

  const MyApp({
    super.key,
    required this.cart,
    required this.productService,
    required this.orderService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brewly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: HomeScreen(
        cart: cart,
        productService: productService,
        orderService: orderService,
      ),
    );
  }
}
