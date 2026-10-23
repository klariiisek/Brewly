// Přihlášení, registrace, role a profil uživatele.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/models/user_role.dart';
import 'package:brewly/theme/app_theme.dart';
import 'package:brewly/theme/palettes.dart';
import 'package:brewly/services/auth_service.dart';
import 'package:brewly/widgets/change_password_dialog.dart';
import 'package:brewly/widgets/user_avatar.dart';

import 'helpers.dart';

void main() {
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

  test('Role z databáze: neznámý text je zákazník', () {
    expect(userRoleFromText('admin'), UserRole.admin);
    expect(userRoleFromText('obsluha'), UserRole.obsluha);
    expect(userRoleFromText('cokoli'), UserRole.zakaznik);
    expect(UserRole.admin.canServe, true);
    expect(UserRole.obsluha.isAdmin, false);
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
