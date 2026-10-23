import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/cart.dart';
import 'screens/home_screen.dart';
import 'screens/main_screen.dart';
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
import 'config/palettes.dart';

// Hlídá návrat do aplikace (viz main). Musí žít po celou dobu běhu aplikace.
AppLifecycleListener? lifecycleListener;

// "async" protože před spuštěním aplikace musíme počkat na připojení k Firebase.
Future<void> main() async {
  // Připraví Flutter, aby šlo něco udělat ještě před runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Připojí aplikaci k Firebase projektu (údaje jsou ve firebase_options.dart).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final db = FirebaseFirestore.instance;

  // Spolehlivé živé spojení i v Safari na iPhonu. Výchozí "proudové" spojení
  // se v Safari občas zasekne a změny (např. stav objednávky) nedorazí.
  // Long polling = aplikace se databáze opakovaně ptá na změny a každou
  // odpověď dostane celou – funguje ve všech prohlížečích.
  db.settings = const Settings(webExperimentalForceLongPolling: true);

  // Když se zákazník do aplikace vrátí (rozsvítí displej, přepne zpět
  // z jiné aplikace), obnovíme spojení s databází, aby hned viděl
  // aktuální stav objednávky. Mobilní prohlížeče totiž stránku na pozadí
  // uspávají, aby šetřily baterii.
  lifecycleListener = AppLifecycleListener(
    onResume: () async {
      await db.disableNetwork();
      await db.enableNetwork();
    },
  );

  // Služby pracují se skutečným Firebase (přihlašování a databáze).
  final services = AppServices(
    auth: AuthService(FirebaseAuth.instance),
    users: UserService(db),
    products: ProductService(db),
    orders: OrderService(db),
    requests: RequestService(db),
    tables: TableService(db),
    settings: SettingsService(db),
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

  // Přišel zákazník z QR kódu na stole? Pak úvodní obrazovku přeskočíme
  // a otevřeme rovnou menu – o jedno klepnutí méně.
  late final bool startInMenu = widget.cart.hasTable;

  // Pojistka: když nastavení nedorazí do 3 sekund (např. bez internetu),
  // použije se výchozí vzhled, aby aplikace nezůstala na načítání.
  bool waitedTooLong = false;
  Timer? waitTimer;

  @override
  void initState() {
    super.initState();
    settingsStream = widget.services.settings.watchSettings();
    waitTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => waitedTooLong = true);
    });
  }

  @override
  void dispose() {
    waitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Celá aplikace poslouchá nastavení podniku. Když admin změní
    // barvu nebo název, aplikace se hned překreslí – všem zákazníkům.
    return StreamBuilder<VenueSettings>(
      stream: settingsStream,
      builder: (context, snapshot) {
        // Dokud nastavení nedorazí, ukážeme neutrální načítání – jinak by
        // na půl sekundy problikl výchozí hnědý vzhled "Brewly".
        if (!snapshot.hasData && !snapshot.hasError && !waitedTooLong) {
          return const LoadingApp();
        }
        // Nastavení dorazilo – pojistku už nepotřebujeme.
        if (snapshot.hasData) waitTimer?.cancel();
        final settings = snapshot.data ?? VenueSettings.defaults;
        return VenueScope(
          settings: settings,
          child: MaterialApp(
            title: settings.name,
            debugShowCheckedModeBanner: false,
            // Téma sestavené z palety, kterou admin vybral.
            theme: AppTheme.build(paletteFor(settings.colorKey).colors),
            home: startInMenu
                ? MainScreen(cart: widget.cart, services: widget.services)
                : HomeScreen(cart: widget.cart, services: widget.services),
          ),
        );
      },
    );
  }
}

// Neutrální obrazovka načítání (bez barev a názvu podniku).
class LoadingApp extends StatelessWidget {
  const LoadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFFBDBDBD),
            ),
          ),
        ),
      ),
    );
  }
}