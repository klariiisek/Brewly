// Společné pomocné funkce pro testy (falešná databáze, přihlášení…).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/main.dart';
import 'package:brewly/data/menu_data.dart';
import 'package:brewly/models/cart.dart';
import 'package:brewly/models/cart_item.dart';
import 'package:brewly/services/app_services.dart';
import 'package:brewly/services/attendance_service.dart';
import 'package:brewly/services/auth_service.dart';
import 'package:brewly/services/order_service.dart';
import 'package:brewly/services/product_service.dart';
import 'package:brewly/services/request_service.dart';
import 'package:brewly/services/settings_service.dart';
import 'package:brewly/services/table_service.dart';
import 'package:brewly/services/user_service.dart';

// Testovací zákaznice, která je v testech "přihlášená".
final testUser = MockUser(uid: 'klara-123', email: 'klara@test.cz', displayName: 'Klára');

// Připraví aplikaci pro test s falešnou databází a falešným přihlašováním
// v paměti (místo skutečného Firebase).
// - withMenu: nahraje do databáze ukázkové menu
// - signedIn: zákaznice je na začátku přihlášená
// - db: vlastní databáze (aby test mohl předem vytvořit objednávky)
// - cart: vlastní košík (např. se stolem nastaveným jako z QR kódu)
Future<Widget> buildTestApp({
  bool withMenu = true,
  bool signedIn = true,
  FakeFirebaseFirestore? db,
  Cart? cart,
}) async {
  final database = db ?? FakeFirebaseFirestore();
  final productService = ProductService(database);
  if (withMenu) {
    await productService.uploadSampleMenu();
  }
  return MyApp(
    cart: cart ?? Cart(),
    services: AppServices(
      auth: AuthService(MockFirebaseAuth(signedIn: signedIn, mockUser: testUser)),
      users: UserService(database),
      products: productService,
      orders: OrderService(database),
      requests: RequestService(database),
      tables: TableService(database),
      settings: SettingsService(database),
      attendance: AttendanceService(database),
    ),
  );
}

// Názvy kategorií v databázi v jejich pořadí (podle pole order).
Future<List<String>> categoryNames(FakeFirebaseFirestore db) async {
  final docs = (await db.collection('categories').orderBy('order').get()).docs;
  return docs.map((doc) => doc.data()['name'] as String).toList();
}

// ID kategorie podle názvu.
Future<String> categoryIdOf(FakeFirebaseFirestore db, String name) async {
  final docs = (await db
          .collection('categories')
          .where('name', isEqualTo: name)
          .get())
      .docs;
  return docs.single.id;
}

// Spustí aplikaci a počká, až se načte (nastavení podniku z databáze).
Future<void> pumpApp(WidgetTester tester, Widget app) async {
  // Pára nad šálkem na úvodu se vlní dokola – v testech ji zastavíme
  // (jako když má uživatel v telefonu zapnuté „omezit animace“).
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

// Zadá v okně ručně kód stolu (jako když zákazník opíše kód pod QR kódem).
Future<void> enterTableCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextFormField).last, code);
  await tester.tap(find.text('Potvrdit stůl'));
  await tester.pumpAndSettle();
}

// Krátká pomocná funkce pro vytvoření objednávky v testech.
Future<String> createTestOrder(OrderService orderService, {int table = 1}) {
  return orderService.createOrder(
    items: [CartItem(product: sampleMenu.first, quantity: 2)],
    totalPrice: 90,
    tableNumber: table,
    tableCode: 'ABCDEF',
    userId: testUser.uid,
    customerName: 'Klára',
  );
}

// Posune obrazovku k prvku (když je mimo viditelnou část) a klepne na něj.
// Úvodní obrazovka je delší než testovací "telefon", odkazy pro obsluhu
// a admina jsou dole.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
