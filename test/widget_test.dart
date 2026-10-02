import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewly/main.dart';
import 'package:brewly/data/menu_data.dart';
import 'package:brewly/models/cart.dart';
import 'package:brewly/models/cart_item.dart';
import 'package:brewly/models/order.dart';
import 'package:brewly/models/service_request.dart';
import 'package:brewly/services/app_services.dart';
import 'package:brewly/services/auth_service.dart';
import 'package:brewly/services/order_service.dart';
import 'package:brewly/services/product_service.dart';
import 'package:brewly/services/request_service.dart';
import 'package:brewly/services/table_service.dart';
import 'package:brewly/services/user_service.dart';
import 'package:brewly/utils/format.dart';

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
    ),
  );
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

void main() {
  testWidgets('Úvodní obrazovka zobrazuje název a tlačítko menu',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp());

    // Ověří, že je vidět název kavárny a tlačítko pro menu.
    expect(find.text('Brewly'), findsOneWidget);
    expect(find.text('Prohlédnout menu'), findsOneWidget);
  });

  test('Správné skloňování počtu položek', () {
    expect(formatItemCount(1), '1 položka');
    expect(formatItemCount(3), '3 položky');
    expect(formatItemCount(5), '5 položek');
  });

  test('Ukázkové menu se nahraje do databáze jen jednou', () async {
    final db = FakeFirebaseFirestore();
    final productService = ProductService(db);

    expect(await productService.uploadSampleMenu(), true);
    // Podruhé už se nic nenahraje, protože menu v databázi je.
    expect(await productService.uploadSampleMenu(), false);

    final saved = await db.collection('products').get();
    expect(saved.docs.length, sampleMenu.length);
  });

  testWidgets('Prázdná databáze ukáže prázdné menu',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp(withMenu: false));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    expect(find.text('Menu je zatím prázdné'), findsOneWidget);
  });

  testWidgets('Prázdný košík ukáže tlačítko zpět do menu',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();
    expect(find.text('Košík je prázdný'), findsOneWidget);

    // Tlačítko vrátí zákazníka do menu.
    await tester.tap(find.text('Přejít do menu'));
    await tester.pumpAndSettle();
    expect(find.text('Co si dnes dáte?'), findsOneWidget);
  });

  testWidgets('Kategorie v menu filtrují produkty', (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Klikne na štítek "Dezerty".
    await tester.tap(find.text('Dezerty'));
    await tester.pumpAndSettle();

    expect(find.text('Tiramisu'), findsOneWidget);
    expect(find.text('Espresso'), findsNothing);
  });

  testWidgets('Detail zespodu přidá vybrané množství do košíku',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp());
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Otevře detail Latte kliknutím na kartu.
    await tester.tap(find.text('Latte'));
    await tester.pumpAndSettle();

    // Zvýší množství na 3.
    await tester.tap(find.byTooltip('Zvýšit množství'));
    await tester.tap(find.byTooltip('Zvýšit množství'));
    await tester.pump();
    expect(find.text('Přidat do košíku · 210 Kč'), findsOneWidget);

    // Přidá do košíku, okno se zavře.
    await tester.tap(find.text('Přidat do košíku · 210 Kč'));
    await tester.pumpAndSettle();
    expect(find.text('Přidáno: 3× Latte'), findsOneWidget);

    // V liště je u košíku číslo 3.
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('Objednávka přes spodní lištu: menu → košík → objednávky',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp());

    // Otevře menu.
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Přidá první produkt (Cappuccino – káva je první, pak abecedně) tlačítkem +.
    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pump();
    // Počká, až zmizí hlášení "Přidáno: 1× Cappuccino".
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Číslo 1 u košíku ve spodní liště.
    expect(find.text('1'), findsWidgets);

    // Přepne na záložku Košík.
    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();
    expect(find.text('Cappuccino'), findsWidgets);

    // Stůl zatím nemá (neskenoval QR kód) → "Objednat" se zeptá na kód stolu.
    await tester.tap(find.text('Objednat'));
    await tester.pumpAndSettle();
    expect(find.text('U kterého stolu sedíte?'), findsOneWidget);
    await enterTableCode(tester, '3-abcdef');

    // Objednávka se odešle a aplikace sama přepne na objednávky.
    expect(find.text('Moje objednávky'), findsOneWidget);
    expect(find.textContaining('Stůl 3 •'), findsOneWidget);
  });

  test('Objednávky dostanou pořadová čísla a jde měnit jejich stav', () async {
    final orderService = OrderService(FakeFirebaseFirestore());

    await createTestOrder(orderService, table: 1);
    await createTestOrder(orderService, table: 2);

    final orders = await orderService.watchAllOrders().first;
    expect(orders.map((order) => order.number), [1, 2]);
    expect(orders.first.status, OrderStatus.prijata);
    expect(orders.first.items.first.quantity, 2);

    // Posune první objednávku na další stav.
    await orderService.moveToNextStatus(orders.first);
    final updated = await orderService.watchOrder(orders.first.id).first;
    expect(updated!.status, OrderStatus.pripravujeSe);

    // Objednávky se ukládají i s tím, kdo je vytvořil.
    final myOrders = await orderService.watchMyOrders(testUser.uid).first;
    expect(myOrders.length, 2);
    expect(myOrders.first.customerName, 'Klára');
    final otherOrders = await orderService.watchMyOrders('nekdo-jiny').first;
    expect(otherOrders, isEmpty);
  });

  testWidgets('Nepřihlášený zákazník musí se před objednáním přihlásit',
      (WidgetTester tester) async {
    // Zákazník přišel z QR kódu stolu 2 (stůl je v košíku už nastavený).
    final cart = Cart()..setTable(2, 'ABCDEF');
    await tester.pumpWidget(await buildTestApp(signedIn: false, cart: cart));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Přidá produkt a přejde do košíku – stůl je tam z QR kódu.
    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();
    expect(find.text('Stůl 2'), findsOneWidget);

    // "Objednat" otevře přihlášení.
    await tester.tap(find.text('Objednat'));
    await tester.pumpAndSettle();
    expect(find.text('Přihlášení'), findsOneWidget);

    // Vyplní přihlášení a přihlásí se – objednávka se pak sama dokončí.
    await tester.enterText(find.byType(TextFormField).at(0), 'klara@test.cz');
    await tester.enterText(find.byType(TextFormField).at(1), 'tajneheslo');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Přihlásit se'));
    await tester.pumpAndSettle();

    expect(find.text('Moje objednávky'), findsOneWidget);
    expect(find.textContaining('Stůl 2 •'), findsOneWidget);
  });

  testWidgets('Přihlášení přes Google přihlásí uživatele',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp(signedIn: false));
    await tester.tap(find.text('Přihlásit se'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pokračovat přes Google'));
    await tester.pumpAndSettle();

    // Přihlašovací obrazovka se zavřela a úvod zdraví přihlášenou uživatelku.
    expect(find.text('Vítejte, Klára'), findsOneWidget);
    expect(find.text('Odhlásit se'), findsOneWidget);
  });

  testWidgets('Registrace kontroluje, že se hesla shodují',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp(signedIn: false));
    await tester.tap(find.text('Přihlásit se'));
    await tester.pumpAndSettle();
    // Odkaz na registraci je dole – stránka se musí nejdřív posunout.
    // (Textová pole jsou uvnitř taky "posuvná", proto posouváme tu první =
    // celou stránku.)
    await tester.scrollUntilVisible(
      find.text('Zaregistrujte se'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Zaregistrujte se'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Klára');
    await tester.enterText(find.byType(TextFormField).at(1), 'klara@test.cz');
    await tester.enterText(find.byType(TextFormField).at(2), 'heslo123');
    await tester.enterText(find.byType(TextFormField).at(3), 'jineheslo');
    await tester.ensureVisible(find.text('Zaregistrovat se'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zaregistrovat se'));
    await tester.pumpAndSettle();

    expect(find.text('Hesla se neshodují'), findsOneWidget);
  });

  testWidgets('Moje objednávky vyzvou nepřihlášeného k přihlášení',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp(signedIn: false));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objednávky').last);
    await tester.pumpAndSettle();

    expect(find.text('Přihlaste se'), findsOneWidget);
  });

  testWidgets('Zákazník nevidí vstup pro obsluhu a dostane profil zákazníka',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await tester.pumpWidget(await buildTestApp(db: db));
    await tester.pumpAndSettle();

    expect(find.text('Vstup pro obsluhu'), findsNothing);

    // Při prvním přihlášení se v databázi založil profil s rolí zákazník.
    final profile = await db.collection('users').doc(testUser.uid).get();
    expect(profile.data()?['role'], 'zakaznik');
  });

  testWidgets('Nepřihlášený návštěvník nevidí vstup pro obsluhu',
      (WidgetTester tester) async {
    await tester.pumpWidget(await buildTestApp(signedIn: false));
    await tester.pumpAndSettle();

    expect(find.text('Vstup pro obsluhu'), findsNothing);
  });

  testWidgets('Obsluha posune objednávku až do Dokončených',
      (WidgetTester tester) async {
    // Připraví databázi s jednou objednávkou ke stolu 5.
    final db = FakeFirebaseFirestore();
    await createTestOrder(OrderService(db), table: 5);
    // Testovací uživatelka má v profilu roli obsluha.
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});

    await tester.pumpWidget(await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vstup pro obsluhu'));
    await tester.pumpAndSettle();

    // První je záložka Požadavky – přepne na Aktivní.
    await tester.tap(find.text('Aktivní (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Stůl 5'), findsOneWidget);

    // Projde všechny stavy pomocí tlačítka na kartě.
    await tester.tap(find.text('Začít připravovat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Označit jako připravenou'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Předáno zákazníkovi'));
    await tester.pumpAndSettle();

    // Objednávka se přesunula do Dokončených.
    expect(find.text('Aktivní (0)'), findsOneWidget);
    expect(find.text('Dokončené (1)'), findsOneWidget);
    expect(find.text('Žádné aktivní objednávky'), findsOneWidget);
  });

  testWidgets('Zákazník přivolá obsluhu – nejdřív zadá kód stolu',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await tester.pumpWidget(await buildTestApp(db: db));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objednávky').last);
    await tester.pumpAndSettle();

    // Stůl ještě není → aplikace se zeptá na kód stolu.
    await tester.tap(find.text('Přivolat obsluhu'));
    await tester.pumpAndSettle();
    expect(find.text('U kterého stolu sedíte?'), findsOneWidget);

    // Špatný tvar kódu → chyba u pole.
    await enterTableCode(tester, '7');
    expect(find.text('Kód má tvar číslo stolu, pomlčka a 6 znaků'),
        findsOneWidget);

    // Správný tvar → požadavek se odešle.
    await enterTableCode(tester, '7-K7P2X9');

    // Požadavek je v databázi i s kódem a tlačítko ukazuje, že se čeká.
    expect(find.text('Obsluha o vás ví…'), findsOneWidget);
    expect(find.text('Stůl 7'), findsOneWidget);
    final saved = await db.collection('requests').get();
    expect(saved.docs.single.data()['type'], 'obsluha');
    expect(saved.docs.single.data()['tableNumber'], 7);
    expect(saved.docs.single.data()['tableCode'], 'K7P2X9');
  });

  test('Kód stolu: čtení ručně opsaného kódu a odkaz v QR kódu', () {
    final parsed = parseShortTableCode(' 4-k7p2x9 ');
    expect(parsed?.number, 4);
    expect(parsed?.code, 'K7P2X9');
    expect(parseShortTableCode('11-K7P2X9'), isNull); // stůl 11 neexistuje
    expect(parseShortTableCode('4-K7P'), isNull); // krátký kód
    expect(tableLink(4, 'K7P2X9'),
        'https://brewly-9e944.web.app/?stul=4&kod=K7P2X9');
  });

  testWidgets('Obsluha vygeneruje kódy a uvidí QR kódy stolů',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});

    await tester.pumpWidget(await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vstup pro obsluhu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Stoly a QR kódy'));
    await tester.pumpAndSettle();

    expect(find.text('Stoly zatím nemají kódy'), findsOneWidget);
    await tester.tap(find.text('Vygenerovat kódy'));
    await tester.pumpAndSettle();

    // V databázi je 10 stolů, každý s jiným šestiznakovým kódem.
    final tables = await db.collection('tables').get();
    expect(tables.docs.length, 10);
    final codes = tables.docs.map((doc) => doc.data()['code'] as String);
    expect(codes.toSet().length, 10);
    expect(codes.every((code) => code.length == 6), true);
    expect(find.text('Stůl 1'), findsOneWidget);
  });

  testWidgets('Obsluha vidí požadavek a vyřídí ho', (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});
    await RequestService(db).createRequest(
      type: RequestType.platba,
      tableNumber: 3,
      tableCode: 'ABCDEF',
      userId: 'host-1',
      customerName: 'Pavel',
    );

    await tester.pumpWidget(await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vstup pro obsluhu'));
    await tester.pumpAndSettle();

    expect(find.text('Požadavky (1)'), findsOneWidget);
    expect(find.text('Stůl 3 • Chce zaplatit'), findsOneWidget);

    await tester.tap(find.text('Vyřízeno'));
    await tester.pumpAndSettle();

    expect(find.text('Požadavky (0)'), findsOneWidget);
    expect(find.text('Žádné požadavky'), findsOneWidget);
  });
}
