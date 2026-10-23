// Docházka obsluhy: Příchod, Odchod, přehled hodin a zapomenuté směny.
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/models/shift.dart';
import 'package:brewly/screens/attendance_overview_screen.dart';
import 'package:brewly/utils/format.dart';

import 'helpers.dart';

void main() {
  testWidgets('Obsluha dá Příchod a Odchod – směna se zapíše',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'obsluha'});

    await pumpApp(tester, await buildTestApp(db: db));
    // Obsluha nevidí přehled všech zaměstnanců – ten je pro admina.
    expect(find.text('Docházka zaměstnanců'), findsNothing);
    await scrollAndTap(tester, find.text('Docházka'));

    expect(find.text('Nejste v práci'), findsOneWidget);
    expect(find.text('V tomto měsíci zatím žádná směna.'), findsOneWidget);

    // Příchod → v databázi je záznam „v práci“ s časem serveru.
    await tester.tap(find.text('Příchod'));
    await tester.pumpAndSettle();
    expect(find.textContaining('V práci od'), findsOneWidget);
    final active = await db.collection('activeShifts').doc(testUser.uid).get();
    expect(active.data()!['userName'], 'Klára');
    expect(active.data()!['start'], isA<Timestamp>());

    // Odchod → hotová směna, záznam „v práci“ zmizí.
    await tester.tap(find.text('Odchod'));
    await tester.pumpAndSettle();
    expect(find.text('Nejste v práci'), findsOneWidget);
    expect(
      (await db.collection('activeShifts').doc(testUser.uid).get()).exists,
      false,
    );
    final shifts = await db.collection('shifts').get();
    expect(shifts.docs.single.data()['userId'], testUser.uid);
    expect(shifts.docs.single.data()['edited'], false);
    expect(shifts.docs.single.data()['start'], active.data()!['start']);
    expect(find.text('1 směna'), findsOneWidget);
  });

  testWidgets('Admin vidí hodiny všech a ukončí zapomenutou směnu',
      (WidgetTester tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});

    // Tomáš má tento měsíc hotovou směnu 2 h 30 min.
    final month = monthStart(DateTime.now());
    await db.collection('shifts').add({
      'userId': 'tomas',
      'userName': 'Tomáš',
      'start': Timestamp.fromDate(month),
      'end': Timestamp.fromDate(month.add(const Duration(hours: 2, minutes: 30))),
      'edited': false,
    });
    // Petra dala Příchod před 13 hodinami a zapomněla na Odchod.
    final now = DateTime.now();
    final petraStart = DateTime(now.year, now.month, now.day, now.hour, now.minute)
        .subtract(const Duration(hours: 13));
    await db.collection('activeShifts').doc('petra').set({
      'userId': 'petra',
      'userName': 'Petra',
      'start': Timestamp.fromDate(petraStart),
    });

    await pumpApp(tester, await buildTestApp(db: db));
    await scrollAndTap(tester, find.text('Docházka zaměstnanců'));

    expect(find.text('Tomáš'), findsOneWidget);
    expect(find.text('2 h 30 min'), findsWidgets);
    expect(find.text('Petra'), findsOneWidget);
    expect(find.textContaining('Možná zapomenutý odchod'), findsOneWidget);

    // Ukončí Petřinu směnu – navržený odchod je 8 h po příchodu.
    await tester.tap(find.text('Ukončit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uložit odchod'));
    await tester.pumpAndSettle();

    expect(find.text('Nikdo nemá zapsaný příchod.'), findsOneWidget);
    final saved = await db
        .collection('shifts')
        .where('userId', isEqualTo: 'petra')
        .get();
    final shift = Shift.fromMap(saved.docs.single.id, saved.docs.single.data());
    expect(shift.edited, true);
    expect(shift.duration, const Duration(hours: 8));
  });

  test('Čas odchodu: noční směna končí až další den', () {
    final start = DateTime(2026, 10, 23, 18, 0);
    expect(parseShiftEnd('23:30', start), DateTime(2026, 10, 23, 23, 30));
    expect(parseShiftEnd('2:15', start), DateTime(2026, 10, 24, 2, 15));
    expect(parseShiftEnd('16.30', start), DateTime(2026, 10, 24, 16, 30));
    expect(parseShiftEnd('25:00', start), isNull);
    expect(parseShiftEnd('odpoledne', start), isNull);
  });

  test('Hodiny za měsíc a české formáty', () {
    Shift shift(DateTime start, int minutes) => Shift(
          id: '',
          userId: 'u',
          userName: 'U',
          start: start,
          end: start.add(Duration(minutes: minutes)),
        );
    final shifts = [
      shift(DateTime(2026, 10, 1, 8), 480),
      shift(DateTime(2026, 10, 31, 22), 300), // noční přes konec měsíce
      shift(DateTime(2026, 11, 1, 8), 60),
    ];
    final october = shiftsInMonth(shifts, DateTime(2026, 10, 15));
    expect(october.length, 2);
    expect(formatDuration(totalDuration(october)), '13 h 00 min');
    expect(formatDuration(const Duration(minutes: 45)), '45 min');
    expect(formatMonth(DateTime(2026, 10)), 'říjen 2026');
    expect(formatDay(DateTime(2026, 10, 23)), 'pá 23. 10.');
    expect(formatShiftCount(3), '3 směny');
  });
}
