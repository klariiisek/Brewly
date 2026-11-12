// Rezervace stolů: zákazník rezervuje a ruší, obsluha potvrzuje.
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/models/reservation.dart';
import 'package:brewly/utils/format.dart';
import 'package:brewly/widgets/upcoming_reservations_banner.dart';

import 'helpers.dart';

// Vyšší obrazovka, aby byly vidět všechny časy i tlačítko.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  test('Časy rezervace: po půl hodinách, dnes jen ty dost daleko od teď', () {
    final now = DateTime(2026, 11, 12, 18, 10);
    const hours = DayHours(8 * 60, 20 * 60);
    final today = reservationSlots(
      now,
      hours: hours,
      minAdvance: const Duration(minutes: 30),
      now: now,
    );
    // 18:30 je jen 20 minut od teď → první volný čas je 19:00.
    expect(today.map(formatTime), ['19:00', '19:30', '20:00']);

    final tomorrow = reservationSlots(
      DateTime(2026, 11, 13),
      hours: hours,
      minAdvance: const Duration(minutes: 30),
      now: now,
    );
    expect(tomorrow.length, 25); // 8:00 … 20:00
    // Den bez rezervací nemá žádný čas.
    expect(
      reservationSlots(
        DateTime(2026, 11, 13),
        hours: null,
        minAdvance: Duration.zero,
        now: now,
      ),
      isEmpty,
    );
  });

  test('Časy rezervací v databázi: "08:00-20:30", prázdný text = zavřeno', () {
    expect(DayHours.parse('08:00-20:30'), const DayHours(480, 1230));
    expect(DayHours.parse('08:00-20:30').toString(), '08:00-20:30');
    expect(DayHours.parse(''), isNull);
    expect(DayHours.parse('20:00-08:00'), isNull); // konec před začátkem
  });

  test('Upozornění obsluhy: jen potvrzené rezervace v nejbližší hodině', () {
    final now = DateTime(2026, 11, 12, 17, 0);
    Reservation at(int hour, int minute, ReservationStatus status) =>
        Reservation(
          id: '$hour$minute${status.name}',
          userId: 'u',
          customerName: 'Petr',
          time: DateTime(2026, 11, 12, hour, minute),
          people: 2,
          note: '',
          status: status,
          tableNumber: 4,
        );
    final soon = soonReservations([
      at(16, 30, ReservationStatus.potvrzena), // před půl hodinou – pryč
      at(16, 50, ReservationStatus.potvrzena), // před chvílí – ano
      at(17, 45, ReservationStatus.potvrzena), // za 45 minut – ano
      at(17, 45, ReservationStatus.ceka), // nepotvrzená – ne
      at(18, 30, ReservationStatus.potvrzena), // až za 1,5 h – ne
    ], now);
    expect(soon.map((r) => formatTime(r.time)), ['16:50', '17:45']);
  });

  testWidgets('Zákazník vidí jen dny a časy, které nastavil admin', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    final db = FakeFirebaseFirestore();
    // Rezervace jdou jen zítra (v ten den v týdnu) od 17:00 do 18:00.
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final hours = List.filled(7, '');
    hours[tomorrow.weekday - 1] = '17:00-18:00';
    await db.collection('settings').doc('venue').set({
      'reservationHours': hours,
    });

    await pumpApp(tester, await buildTestApp(db: db));
    await scrollAndTap(tester, find.text('Rezervovat stůl'));
    await tester.tap(find.text('Nová rezervace'));
    await tester.pumpAndSettle();

    expect(find.text('zítra'), findsOneWidget);
    expect(find.text('dnes'), findsNothing);
    expect(find.text('17:00'), findsOneWidget);
    expect(find.text('17:30'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
    expect(find.text('8:00'), findsNothing);
    expect(find.text('18:30'), findsNothing);
  });

  testWidgets('Admin vypne rezervace v neděli a uloží časy', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});

    await pumpApp(tester, await buildTestApp(db: db));
    await scrollAndTap(tester, find.text('Podnik'));
    // Řádek „Ne“ v časech rezervací – jeho přepínač.
    final sundaySwitch = find.descendant(
      of: find.ancestor(of: find.text('Ne'), matching: find.byType(Row)).first,
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(sundaySwitch);
    await tester.tap(sundaySwitch);
    await tester.pumpAndSettle();
    expect(find.text('bez rezervací'), findsOneWidget);
    await scrollAndTap(tester, find.text('Uložit nastavení'));

    final settings = await db.collection('settings').doc('venue').get();
    expect(settings.data()!['reservationHours'], [
      '08:00-20:00',
      '08:00-20:00',
      '08:00-20:00',
      '08:00-20:00',
      '08:00-20:00',
      '08:00-20:00',
      '',
    ]);
  });

  testWidgets('Zákazník zarezervuje stůl a pak rezervaci zruší', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    final db = FakeFirebaseFirestore();
    await pumpApp(tester, await buildTestApp(db: db));

    await scrollAndTap(tester, find.text('Rezervovat stůl'));
    expect(find.text('Zatím žádná rezervace'), findsOneWidget);
    await tester.tap(find.text('Nová rezervace'));
    await tester.pumpAndSettle();

    // Bez času nejde odeslat.
    expect(find.text('Vyberte čas'), findsOneWidget);
    await tester.tap(find.text('zítra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('18:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Více osob'));
    await tester.pumpAndSettle();
    expect(find.text('3 osoby'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Oslava narozenin');
    await tester.tap(find.text('Rezervovat zítra v 18:00'));
    await tester.pumpAndSettle();

    final docs = (await db.collection('reservations').get()).docs;
    final data = docs.single.data();
    expect(data['userId'], testUser.uid);
    expect(data['customerName'], 'Klára');
    expect(data['people'], 3);
    expect(data['note'], 'Oslava narozenin');
    expect(data['status'], 'ceka');
    expect(data['tableNumber'], 0);
    final time = (data['time'] as Timestamp).toDate();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect([time.day, time.hour, time.minute], [tomorrow.day, 18, 0]);

    // V seznamu je rezervace a čeká na potvrzení.
    expect(find.text('zítra v 18:00'), findsOneWidget);
    expect(find.text('Čeká na potvrzení'), findsOneWidget);
    expect(find.text('Oslava narozenin'), findsOneWidget);

    await tester.tap(find.text('Zrušit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zrušit rezervaci'));
    await tester.pumpAndSettle();
    expect((await docs.single.reference.get()).data()!['status'], 'zrusena');
    expect(find.text('Zrušena'), findsOneWidget);
    expect(find.text('Zatím žádná rezervace'), findsOneWidget);
  });

  testWidgets('Obsluha vidí čekající rezervaci a potvrdí ji se stolem', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final reservation = await db.collection('reservations').add({
      'userId': 'petr',
      'customerName': 'Petr',
      'time': Timestamp.fromDate(
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 19, 30),
      ),
      'people': 4,
      'note': '',
      'status': 'ceka',
      'tableNumber': 0,
    });

    await pumpApp(tester, await buildTestApp(db: db));
    // Na dlaždici Rezervace je počet čekajících.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsOneWidget,
    );
    await scrollAndTap(tester, find.text('Rezervace'));

    // Nahoře čekající žádost, potvrzené zatím žádné.
    expect(find.text('Čeká na potvrzení (1)'), findsOneWidget);
    expect(find.text('Zatím žádná potvrzená rezervace.'), findsOneWidget);
    expect(find.text('zítra v 19:30'), findsOneWidget);
    expect(find.text('Petr · 4 osoby'), findsOneWidget);

    await tester.tap(find.text('Potvrdit'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '4'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Potvrdit'),
      ),
    );
    await tester.pumpAndSettle();

    final data = (await reservation.get()).data()!;
    expect(data['status'], 'potvrzena');
    expect(data['tableNumber'], 4);
    expect(find.text('Petr · 4 osoby · stůl 4'), findsOneWidget);
    // Po potvrzení zmizí z čekajících a je mezi potvrzenými pod „Zítra“.
    expect(find.textContaining('Čeká na potvrzení ('), findsNothing);
    expect(find.text('Zítra'), findsOneWidget);
    expect(find.text('Potvrzena'), findsOneWidget);
  });

  testWidgets('Obsluha vidí upozornění na hosty s rezervací za půl hodiny', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});
    final soon = DateTime.now().add(const Duration(minutes: 30));
    await db.collection('reservations').add({
      'userId': 'petr',
      'customerName': 'Petr',
      'time': Timestamp.fromDate(soon),
      'people': 4,
      'note': '',
      'status': 'potvrzena',
      'tableNumber': 4,
    });

    await pumpApp(tester, await buildTestApp(db: db));
    expect(find.text('Brzy přijdou hosté s rezervací'), findsOneWidget);
    expect(
      find.text('Stůl 4 · ${formatTime(soon)} · Petr, 4 osoby'),
      findsOneWidget,
    );

    // Upozornění je vidět i na obrazovce s objednávkami.
    await scrollAndTap(tester, find.text('Objednávky'));
    expect(find.text('Brzy přijdou hosté s rezervací'), findsOneWidget);
  });

  test('Obsazené stoly: potvrzené rezervace do 2 hodin od sebe', () {
    Reservation at(
      String id,
      int hour,
      int table, [
      ReservationStatus status = ReservationStatus.potvrzena,
    ]) => Reservation(
      id: id,
      userId: 'u',
      customerName: id,
      time: DateTime(2026, 11, 13, hour),
      people: 2,
      note: '',
      status: status,
      tableNumber: table,
    );
    final mine = at('nova', 18, 0, ReservationStatus.ceka);
    final occupied = occupiedTables(mine, [
      mine,
      at('Jana', 19, 2), // za hodinu – překrývá se
      at('Petr', 17, 5), // před hodinou – ještě sedí
      at('Eva', 20, 3), // za 2 hodiny – už volno
      at('Adam', 18, 6, ReservationStatus.odmitnuta), // odmítnutá – nevadí
      at('Ola', 18, 0), // bez stolu – nic neblokuje
    ], duration: const Duration(hours: 2));
    expect(occupied.keys.toSet(), {2, 5});
    expect(occupied[2]!.customerName, 'Jana');
  });

  testWidgets('Obsluha nemůže dát jeden stůl dvěma rezervacím najednou', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    DateTime at(int hour) =>
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour);
    await db.collection('reservations').add({
      'userId': 'jana',
      'customerName': 'Jana',
      'time': Timestamp.fromDate(at(18)),
      'people': 2,
      'note': '',
      'status': 'potvrzena',
      'tableNumber': 2,
    });
    await db.collection('reservations').add({
      'userId': 'petr',
      'customerName': 'Petr',
      'time': Timestamp.fromDate(at(19)),
      'people': 4,
      'note': '',
      'status': 'ceka',
      'tableNumber': 0,
    });

    await pumpApp(tester, await buildTestApp(db: db));
    await scrollAndTap(tester, find.text('Rezervace'));
    await tester.tap(find.text('Potvrdit'));
    await tester.pumpAndSettle();

    expect(find.text('Stůl 2 je obsazený: Jana, 18:00'), findsOneWidget);
    final table2 = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '2'),
    );
    expect(table2.onSelected, isNull);
    final table3 = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '3'),
    );
    expect(table3.onSelected, isNotNull);
  });
}
