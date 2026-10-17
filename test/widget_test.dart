import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
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
import 'package:brewly/models/user_role.dart';
import 'package:brewly/models/venue_settings.dart';
import 'package:brewly/theme/app_theme.dart';
import 'package:brewly/theme/palettes.dart';
import 'package:brewly/services/app_services.dart';
import 'package:brewly/services/auth_service.dart';
import 'package:brewly/services/order_service.dart';
import 'package:brewly/services/product_service.dart';
import 'package:brewly/services/request_service.dart';
import 'package:brewly/services/settings_service.dart';
import 'package:brewly/services/table_service.dart';
import 'package:brewly/services/user_service.dart';
import 'package:brewly/utils/csv_import.dart';
import 'package:brewly/utils/format.dart';
import 'package:brewly/utils/text.dart';
import 'package:brewly/widgets/change_password_dialog.dart';
import 'package:brewly/widgets/product_card.dart';
import 'package:brewly/widgets/user_avatar.dart';

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

void main() {
  testWidgets('Úvodní obrazovka zobrazuje název a tlačítko menu',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp());

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
    await pumpApp(tester, await buildTestApp(withMenu: false));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    expect(find.text('Menu je zatím prázdné'), findsOneWidget);
  });

  testWidgets('Prázdný košík ukáže tlačítko zpět do menu',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp());
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

  testWidgets('Hlavička menu se po přidání do košíku zmenší',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp());
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();
    expect(find.text('Co si dnes dáte?'), findsOneWidget);

    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pumpAndSettle();

    expect(find.text('Co si dnes dáte?'), findsNothing);
    expect(find.text('Menu ☕'), findsOneWidget);
  });

  testWidgets('Kategorie v menu filtrují produkty', (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp());
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
    await pumpApp(tester, await buildTestApp());
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
    await pumpApp(tester, await buildTestApp());

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
    await pumpApp(tester, await buildTestApp(signedIn: false, cart: cart));
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
    await pumpApp(tester, await buildTestApp(signedIn: false));
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
    await pumpApp(tester, await buildTestApp(signedIn: false));
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
    await pumpApp(tester, await buildTestApp(signedIn: false));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objednávky').last);
    await tester.pumpAndSettle();

    expect(find.text('Přihlaste se'), findsOneWidget);
  });

  testWidgets('Zákazník nevidí vstup pro obsluhu a dostane profil zákazníka',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();

    expect(find.text('Vstup pro obsluhu'), findsNothing);

    // Při prvním přihlášení se v databázi založil profil s rolí zákazník.
    final profile = await db.collection('users').doc(testUser.uid).get();
    expect(profile.data()?['role'], 'zakaznik');
  });

  testWidgets('Nepřihlášený návštěvník nevidí vstup pro obsluhu',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp(signedIn: false));
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

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    // Obsluha nevidí správu menu – ta je jen pro admina.
    expect(find.text('Správa menu'), findsNothing);
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
    await pumpApp(tester, await buildTestApp(db: db));
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

    await pumpApp(tester, await buildTestApp(db: db));
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

    await pumpApp(tester, await buildTestApp(db: db));
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

  testWidgets('Košík hlídá změny v menu: cenu i vyprodání',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await pumpApp(tester, await buildTestApp(db: db));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Zákazník si dá do košíku Cappuccino (65 Kč) a otevře košík.
    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();

    // Admin mezitím zdraží Cappuccino na 80 Kč – košík se přepočítá.
    final cappuccino = (await db
            .collection('products')
            .where('name', isEqualTo: 'Cappuccino')
            .get())
        .docs
        .single
        .reference;
    await cappuccino.update({'price': 80});
    await tester.pumpAndSettle();
    expect(find.text(formatPrice(80)), findsWidgets);

    // Admin ho označí jako vyprodaný – objednat nejde, jen odebrat.
    await cappuccino.update({'available': false});
    await tester.pumpAndSettle();
    expect(find.text('Vyprodáno – odeberte z košíku'), findsOneWidget);
    final orderButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Objednat'));
    expect(orderButton.onPressed, isNull);

    await tester.tap(find.byTooltip('Odebrat'));
    await tester.pumpAndSettle();
    expect(find.text('Košík je prázdný'), findsOneWidget);
  });

  test('Role z databáze: neznámý text je zákazník', () {
    expect(userRoleFromText('admin'), UserRole.admin);
    expect(userRoleFromText('obsluha'), UserRole.obsluha);
    expect(userRoleFromText('cokoli'), UserRole.zakaznik);
    expect(UserRole.admin.canServe, true);
    expect(UserRole.obsluha.isAdmin, false);
  });

  testWidgets('Admin přidá do menu nový produkt', (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    // Admin vidí oba vstupy.
    expect(find.text('Vstup pro obsluhu'), findsOneWidget);
    await tester.tap(find.text('Správa menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Přidat produkt'));
    await tester.pumpAndSettle();

    // Prázdný formulář neprojde kontrolou.
    await tester.ensureVisible(find.text('Uložit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uložit'));
    await tester.pumpAndSettle();
    expect(find.text('Zadejte název'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Název'), 'Flat white');
    await tester.enterText(find.widgetWithText(TextFormField, 'Cena'), '72,5');
    // Kategorie kliknutím na štítek.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Káva'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Uložit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uložit'));
    await tester.pumpAndSettle();

    final saved = await db
        .collection('products')
        .where('name', isEqualTo: 'Flat white')
        .get();
    expect(saved.docs.single.data()['price'], 72.5);
    // Produkt odkazuje na kategorii přes její ID (cizí klíč).
    expect(saved.docs.single.data()['categoryId'],
        await categoryIdOf(db, 'Káva'));
    expect(saved.docs.single.data()['available'], true);
  });

  testWidgets('Vyprodaný produkt zákazník vidí, ale nemůže ho přidat',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Správa menu'));
    await tester.pumpAndSettle();

    // Admin přepne první produkt (Cappuccino) na vyprodaný.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    final cappuccino = await db
        .collection('products')
        .where('name', isEqualTo: 'Cappuccino')
        .get();
    expect(cappuccino.docs.single.data()['available'], false);

    // V menu pro zákazníky je označený a tlačítko + nejde zmáčknout.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    // Vyprodané Cappuccino je až na konci, první je teď Espresso.
    List<ProductCard> cards() =>
        tester.widgetList<ProductCard>(find.byType(ProductCard)).toList();
    String firstProductName() => cards().first.product.name;
    expect(firstProductName(), 'Espresso');

    // V kategorii Káva (vejde se celá na obrazovku) je Cappuccino poslední,
    // označené jako vyprodané a jeho tlačítko + nejde zmáčknout.
    await tester.tap(find.text('Káva'));
    await tester.pumpAndSettle();
    expect(cards().last.product.name, 'Cappuccino');
    expect(find.text('${formatPrice(65)} • Vyprodáno'), findsOneWidget);
    final addButton = tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add).last);
    expect(addButton.onPressed, isNull);

    // Když se Cappuccino zase prodává, vrátí se nahoru.
    await cappuccino.docs.single.reference.update({'available': true});
    await tester.pumpAndSettle();
    expect(firstProductName(), 'Cappuccino');
  });

  test('Hledání nezávisí na diakritice a velkých písmenech', () {
    expect(normalizeText('Káva'), 'kava');
    expect(normalizeText('  ŽLUŤOUČKÝ Kůň '), 'zlutoucky kun');
  });

  test('CSV: přečte produkty a najde chybné řádky', () {
    final result = parseProductsCsv(
      '﻿název;cena;kategorie;popis\r\n'
      'Flat white;72;Káva;Espresso s mlékem\r\n'
      'Brownies;65,50 Kč;Dezerty;"Čokoládový; s ořechy"\r\n'
      '\r\n'
      'Čaj;;Nápoje;Bez ceny\r\n'
      'Voda;20;;Bez kategorie\r\n'
      'flat WHITE;80;Káva;Podruhé\r\n'
      'Džus;35;Nápoje\r\n',
    );

    expect(result.products.map((p) => p.name),
        ['Flat white', 'Brownies', 'Džus']);
    expect(result.products[1].price, 65.5);
    // Středník v uvozovkách je součást popisu, ne oddělovač.
    expect(result.products[1].description, 'Čokoládový; s ořechy');
    // Popis není povinný.
    expect(result.products[2].description, '');
    expect(result.errors, [
      'Řádek 5 (Čaj): cena "" není číslo',
      'Řádek 6 (Voda): chybí kategorie',
      'Řádek 7: flat WHITE je v souboru dvakrát',
    ]);
  });

  test('CSV oddělené čárkou a bez záhlaví', () {
    final result = parseProductsCsv('Latte,70,Káva,"Jemná, mléčná"');
    expect(result.errors, isEmpty);
    expect(result.products.single.description, 'Jemná, mléčná');
  });

  test('Hromadné nahrání: stejný název aktualizuje, nový přidá', () async {
    final db = FakeFirebaseFirestore();
    final productService = ProductService(db);
    await productService.uploadSampleMenu();
    // Latte je vyprodané – po nahrání má vyprodané zůstat.
    final latte = (await db
            .collection('products')
            .where('name', isEqualTo: 'Latte')
            .get())
        .docs
        .single
        .reference;
    await latte.update({'available': false});

    final counts = await productService.importProducts(
      parseProductsCsv('latte;75;Káva;Nový popis\nFlat white;72;Káva;').products,
    );

    expect(counts.added, 1);
    expect(counts.updated, 1);
    final updatedLatte = (await latte.get()).data()!;
    expect(updatedLatte['price'], 75);
    expect(updatedLatte['available'], false);
    final all = await db.collection('products').get();
    expect(all.docs.length, sampleMenu.length + 1);
  });

  testWidgets('Admin vyhledá produkt ve správě menu',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Správa menu'));
    await tester.pumpAndSettle();

    // "tira" najde Tiramisu, nic jiného.
    await tester.enterText(find.byType(TextField), 'tira');
    await tester.pumpAndSettle();
    expect(find.text('Tiramisu'), findsOneWidget);
    expect(find.text('Espresso'), findsNothing);

    // "napoje" bez diakritiky najde kategorii Nápoje.
    await tester.enterText(find.byType(TextField), 'napoje');
    await tester.pumpAndSettle();
    expect(find.text('Domácí limonáda'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'pizza');
    await tester.pumpAndSettle();
    expect(find.text('Nic nenalezeno'), findsOneWidget);

    // Křížek hledání zruší.
    await tester.tap(find.byTooltip('Zrušit hledání'));
    await tester.pumpAndSettle();
    expect(find.text('Espresso'), findsOneWidget);
  });

  test('Nastavení podniku: výchozí hodnoty', () {
    final settings = VenueSettings.fromMap({
      'name': 'Bar U Lípy',
      'type': 'bar',
    });
    expect(settings.name, 'Bar U Lípy');
    expect(settings.type, VenueType.bar);
    // Co v databázi chybí, doplní se z výchozího nastavení.
    expect(settings.colorKey, 'kava');
    // Neznámá paleta = kávová.
    expect(paletteFor('neexistuje').key, 'kava');
  });

  testWidgets('Menu řadí kategorie podle jejich pořadí',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await ProductService(db).uploadSampleMenu();
    // Nápoje dáme na první místo.
    await db
        .collection('categories')
        .doc(await categoryIdOf(db, 'Nápoje'))
        .update({'order': -1});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    final first =
        tester.widgetList<ProductCard>(find.byType(ProductCard)).first;
    expect(first.product.name, 'Domácí limonáda');
  });

  testWidgets('Admin změní název, typ a barvu podniku',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nastavení podniku'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Název podniku'), 'Bar U Lípy');
    await tester.pumpAndSettle();
    // Náhled ukazuje nový název ještě před uložením (+ text v poli).
    expect(find.text('Bar U Lípy'), findsNWidgets(2));

    // Posune obrazovku dolů, dokud není prvek vidět, a klikne na něj.
    Future<void> scrollAndTap(Finder finder) async {
      await tester.scrollUntilVisible(finder, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await scrollAndTap(find.widgetWithText(ChoiceChip, 'Bar'));
    await scrollAndTap(find.byTooltip('Bordó'));
    await scrollAndTap(find.text('Uložit nastavení'));
    await tester.pumpAndSettle();

    final saved = (await db.collection('settings').doc('venue').get()).data()!;
    expect(saved['name'], 'Bar U Lípy');
    expect(saved['type'], 'bar');
    expect(saved['color'], 'bordo');

    // Zpět na úvod: nový název, ikona baru a celá aplikace v barvě bordó.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Bar U Lípy'), findsOneWidget);
    expect(find.text('powered by Brewly'), findsOneWidget);
    expect(find.byIcon(Icons.local_bar), findsOneWidget);
    final context = tester.element(find.text('Bar U Lípy'));
    expect(context.colors.primary, paletteFor('bordo').colors.primary);
  });

  testWidgets('Admin spravuje kategorie: přidá, přejmenuje, smaže',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Správa menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kategorie'));
    await tester.pumpAndSettle();

    expect(find.text('3 produkty'), findsOneWidget); // Káva
    expect(find.text('2 produkty'), findsOneWidget); // Dezerty

    // Přidá prázdnou kategorii Snídaně. Stejný název podruhé nejde.
    await tester.tap(find.text('Přidat kategorii'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'káva');
    await tester.tap(find.text('Přidat'));
    await tester.pumpAndSettle();
    expect(find.text('Taková kategorie už je'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Snídaně');
    await tester.tap(find.text('Přidat'));
    await tester.pumpAndSettle();
    expect(find.text('0 produktů'), findsOneWidget);
    expect(await categoryNames(db), ['Káva', 'Dezerty', 'Nápoje', 'Snídaně']);

    // Přejmenuje Dezerty na Sladké. Změní se jen dokument kategorie –
    // produkty na ni dál odkazují stejným ID.
    final dessertsId = await categoryIdOf(db, 'Dezerty');
    await tester.tap(find.byTooltip('Přejmenovat').at(1));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Sladké');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Přejmenovat'));
    await tester.pumpAndSettle();
    expect(await categoryIdOf(db, 'Sladké'), dessertsId);
    final sweets = await db
        .collection('products')
        .where('categoryId', isEqualTo: dessertsId)
        .get();
    expect(sweets.docs.length, 2);
    expect(await categoryNames(db), ['Káva', 'Sladké', 'Nápoje', 'Snídaně']);

    // Smazat jde jen prázdnou kategorii (Snídaně je poslední).
    await tester.tap(find.byTooltip('Smazat').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Smazat'));
    await tester.pumpAndSettle();
    expect(find.text('Snídaně'), findsNothing);
    expect(await categoryNames(db), ['Káva', 'Sladké', 'Nápoje']);
  });

  testWidgets('Zavřeno: menu to ukáže a objednat nejde',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('settings').doc('venue').set({
      'isOpen': false,
      'announcement': 'Dnes −20 % na dezerty',
    });

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Teď máme zavřeno'), findsOneWidget);
    expect(find.text('Dnes −20 % na dezerty'), findsOneWidget);

    // Do košíku přidat jde, ale tlačítko Objednat je neaktivní.
    await tester.tap(find.byTooltip('Přidat do košíku').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Košík').last);
    await tester.pumpAndSettle();
    expect(find.text('Teď máme zavřeno, objednat zatím nejde.'), findsOneWidget);
    final orderButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Objednat'));
    expect(orderButton.onPressed, isNull);
  });

  testWidgets('Obsluha přepne podnik na Zavřeno', (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vstup pro obsluhu'));
    await tester.pumpAndSettle();

    expect(find.text('Otevřeno'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Zavřeno'), findsOneWidget);
    final saved = (await db.collection('settings').doc('venue').get()).data()!;
    expect(saved, {'isOpen': false});
  });

  testWidgets('Zákazník uvidí informace o podniku a heslo k Wi-Fi',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('settings').doc('venue').set({
      'address': 'Lipová 12, Praha',
      'wifiName': 'Brewly-host',
      'wifiPassword': 'kafe1234',
    });

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Informace o podniku'));
    await tester.pumpAndSettle();

    expect(find.text('Lipová 12, Praha'), findsOneWidget);
    expect(find.text('Heslo: kafe1234'), findsOneWidget);
    expect(find.text('● Teď máme otevřeno'), findsOneWidget);
  });

  test('Uložení nastavení nesmaže otevřeno ani informace', () {
    const settings = VenueSettings(
      name: 'Bistro',
      slogan: '',
      colorKey: 'kava',
      type: VenueType.restaurace,
      isOpen: false,
      wifiName: 'Bistro',
    );
    final changed = settings.copyWith(name: 'Bistro Na Rohu');
    expect(changed.isOpen, false);
    expect(changed.wifiName, 'Bistro');
    expect(VenueSettings.fromMap(changed.toMap()).name, 'Bistro Na Rohu');
  });

  testWidgets('Zavřeno: obsluhu přivolat nejde, zaplatit ano',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('settings').doc('venue').set({'isOpen': false});

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objednávky').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('obsluhu nejde přivolat'), findsOneWidget);
    ButtonStyleButton button(String label) => tester.widget<ButtonStyleButton>(
        find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)));
    expect(button('Přivolat obsluhu').onPressed, isNull);
    expect(button('Chci zaplatit').onPressed, isNotNull);
  });

  test('Čísla objednávek začínají každý den od 1', () async {
    expect(OrderService.dayKey(DateTime.utc(2026, 10, 16, 15)), 20261016);
    expect(OrderService.nextNumber(null, 20261016), 1);
    expect(OrderService.nextNumber({'last': 7, 'day': 20261016}, 20261016), 8);
    expect(OrderService.nextNumber({'last': 57, 'day': 20261015}, 20261016), 1);
    // Staré počítadlo bez dne (před touto změnou) = taky od 1.
    expect(OrderService.nextNumber({'last': 120}, 20261016), 1);

    // Včera skončili na #57 – dnešní první objednávka má #1, další #2.
    final db = FakeFirebaseFirestore();
    final yesterday = OrderService.dayKey(
        DateTime.now().subtract(const Duration(days: 1)));
    await db
        .collection('counters')
        .doc('orders')
        .set({'last': 57, 'day': yesterday});
    final orderService = OrderService(db);
    final first = await createTestOrder(orderService);
    final second = await createTestOrder(orderService);
    expect((await db.collection('orders').doc(first).get()).data()!['number'], 1);
    expect((await db.collection('orders').doc(second).get()).data()!['number'], 2);
  });

  testWidgets('Obsluha vidí v Dokončených jen dnešní objednávky',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});
    final base = {
      'items': [],
      'totalPrice': 90,
      'tableNumber': 2,
      'status': 'dokoncena',
      'userId': 'host',
      'customerName': 'Pavel',
    };
    await db.collection('orders').add({
      ...base,
      'number': 5,
      'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1))),
    });
    await db.collection('orders').add({
      ...base,
      'number': 1,
      'createdAt': Timestamp.now(),
    });

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.tap(find.text('Vstup pro obsluhu'));
    await tester.pumpAndSettle();

    expect(find.text('Dokončené (1)'), findsOneWidget);
  });

  test('Převod starých produktů: kategorie z textu do kolekce', () async {
    final db = FakeFirebaseFirestore();
    // Starý formát: kategorie jako text, pořadí v nastavení podniku.
    await db.collection('settings').doc('venue').set({
      'categoryOrder': ['Dezerty', 'Káva'],
    });
    await db.collection('products').add(
        {'name': 'Latte', 'price': 70, 'category': 'Káva', 'description': ''});
    await db.collection('products').add(
        {'name': 'Dort', 'price': 80, 'category': 'Dezerty', 'description': ''});

    final productService = ProductService(db);
    expect(await productService.migrateCategories(), 2);

    expect(await categoryNames(db), ['Dezerty', 'Káva']);
    final latte = (await db
            .collection('products')
            .where('name', isEqualTo: 'Latte')
            .get())
        .docs
        .single
        .data();
    expect(latte['categoryId'], await categoryIdOf(db, 'Káva'));
    expect(latte.containsKey('category'), false);
    // Podruhé už není co převádět.
    expect(await productService.migrateCategories(), 0);

    // Menu spojí produkty s kategoriemi (jako JOIN) a seřadí je.
    final menu = await productService.watchProducts().first;
    expect(menu.map((p) => '${p.category}: ${p.name}'),
        ['Dezerty: Dort', 'Káva: Latte']);
  });

  testWidgets('Profil: nepřihlášený uvidí výzvu k přihlášení',
      (WidgetTester tester) async {
    await pumpApp(tester, await buildTestApp(signedIn: false));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Po přihlášení si tu můžete upravit svůj profil.'),
        findsOneWidget);
  });

  testWidgets('Profil: zákazník změní jméno a avatar',
      (WidgetTester tester) async {
    // Test mění jméno sdíleného testovacího účtu – na konci ho vrátí.
    addTearDown(() => testUser.updateDisplayName('Klára'));
    final db = FakeFirebaseFirestore();
    await pumpApp(tester, await buildTestApp(db: db));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Klára'), findsOneWidget);
    expect(find.textContaining('Zákazník'), findsOneWidget);
    // Bez přihlášení e-mailem (testovací účet) se změna hesla nenabízí.
    expect(find.text('Změnit heslo'), findsNothing);

    // Změna jména.
    await tester.tap(find.text('Změnit jméno'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Klárka');
    await tester.tap(find.text('Uložit'));
    await tester.pumpAndSettle();
    expect(find.text('Klárka'), findsOneWidget);
    var profile = (await db.collection('users').doc(testUser.uid).get()).data()!;
    expect(profile['name'], 'Klárka');

    // Avatar: kočička v modré.
    await tester.tap(find.text('Změnit avatar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.pets));
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((widget) =>
        widget is CircleAvatar &&
        widget.backgroundColor == avatarColors['modra']));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uložit avatar'));
    await tester.pumpAndSettle();
    profile = (await db.collection('users').doc(testUser.uid).get()).data()!;
    expect(profile['avatarIcon'], 'kocka');
    expect(profile['avatarColor'], 'modra');
  });

  testWidgets('Změna hesla kontroluje nová hesla a pak heslo změní',
      (WidgetTester tester) async {
    final auth = AuthService(MockFirebaseAuth(signedIn: true, mockUser: testUser));
    bool? result;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.build(paletteFor('kava').colors),
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async =>
              result = await showChangePasswordDialog(context, auth),
          child: const Text('Otevřít'),
        ),
      ),
    ));
    await tester.tap(find.text('Otevřít'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'stareHeslo');
    await tester.enterText(fields.at(1), 'noveHeslo1');
    await tester.enterText(fields.at(2), 'jineHeslo');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Změnit heslo'));
    await tester.pumpAndSettle();
    expect(find.text('Hesla se neshodují'), findsOneWidget);

    await tester.enterText(fields.at(2), 'noveHeslo1');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Změnit heslo'));
    await tester.pumpAndSettle();
    expect(result, true);
  });

  testWidgets('Profil doplní jméno, když je v něm místo jména e-mail',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    // Jako po registraci: profil vznikl dřív, než se uložilo jméno.
    await db.collection('users').doc(testUser.uid).set({
      'name': testUser.email,
      'email': testUser.email,
      'role': 'zakaznik',
    });

    await pumpApp(tester, await buildTestApp(db: db));
    await tester.tap(find.text('Prohlédnout menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Klára'), findsOneWidget);
    final profile = (await db.collection('users').doc(testUser.uid).get()).data()!;
    expect(profile['name'], 'Klára');
  });
}