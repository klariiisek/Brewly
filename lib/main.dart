import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/cart.dart';
import 'screens/home_screen.dart';
import 'services/app_services.dart';
import 'services/auth_service.dart';
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

  // Služby pracují se skutečným Firebase (přihlašování a databáze).
  final services = AppServices(
    auth: AuthService(FirebaseAuth.instance),
    products: ProductService(FirebaseFirestore.instance),
    orders: OrderService(FirebaseFirestore.instance),
  );

  // Košík se vytvoří jen jednou při spuštění aplikace a předává se obrazovkám.
  runApp(MyApp(cart: Cart(), services: services));
}

class MyApp extends StatelessWidget {
  final Cart cart;
  final AppServices services;

  const MyApp({super.key, required this.cart, required this.services});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brewly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: HomeScreen(cart: cart, services: services),
    );
  }
}
