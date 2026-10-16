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
import 'services/request_service.dart';
import 'services/settings_service.dart';
import 'services/table_service.dart';
import 'services/user_service.dart';
import 'models/venue_settings.dart';
import 'theme/app_theme.dart';
import 'theme/palettes.dart';

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
    users: UserService(FirebaseFirestore.instance),
    products: ProductService(FirebaseFirestore.instance),
    orders: OrderService(FirebaseFirestore.instance),
    requests: RequestService(FirebaseFirestore.instance),
    tables: TableService(FirebaseFirestore.instance),
    settings: SettingsService(FirebaseFirestore.instance),
  );

  // Košík se vytvoří jen jednou při spuštění aplikace a předává se obrazovkám.
  final cart = Cart();

  // Když zákazník otevřel aplikaci z QR kódu na stole (…/?stul=4&kod=K7P2X9),
  // rovnou si zapamatujeme jeho stůl.
  final params = Uri.base.queryParameters;
  final tableNumber = int.tryParse(params['stul'] ?? '');
  final tableCode = params['kod'];
  if (tableNumber != null && tableCode != null) {
    cart.setTable(tableNumber, tableCode.toUpperCase());
  }

  runApp(MyApp(cart: cart, services: services));
}

class MyApp extends StatefulWidget {
  final Cart cart;
  final AppServices services;

  const MyApp({super.key, required this.cart, required this.services});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Stream<VenueSettings> settingsStream;

  @override
  void initState() {
    super.initState();
    settingsStream = widget.services.settings.watchSettings();
  }

  @override
  Widget build(BuildContext context) {
    // Celá aplikace poslouchá nastavení podniku. Když admin změní
    // barvu nebo název, aplikace se hned překreslí – všem zákazníkům.
    return StreamBuilder<VenueSettings>(
      stream: settingsStream,
      builder: (context, snapshot) {
        final settings = snapshot.data ?? VenueSettings.defaults;
        return VenueScope(
          settings: settings,
          child: MaterialApp(
            title: settings.name,
            debugShowCheckedModeBanner: false,
            // Téma sestavené z palety, kterou admin vybral.
            theme: AppTheme.build(paletteFor(settings.colorKey).colors),
            home: HomeScreen(cart: widget.cart, services: widget.services),
          ),
        );
      },
    );
  }
}