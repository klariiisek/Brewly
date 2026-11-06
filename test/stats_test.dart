// Statistiky pro admina: období, součty, srovnání, žebříčky, graf.
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewly/models/order.dart';
import 'package:brewly/models/sales_stats.dart';
import 'package:brewly/widgets/bar_chart.dart';

import 'helpers.dart';

// Dokončená objednávka s položkami (název, kategorie, cena, kusy).
Map<String, dynamic> statsOrder(
  DateTime time,
  List<(String, String, double, int)> items, {
  String status = 'dokoncena',
  double rewardDiscount = 0,
}) {
  var total = 0.0;
  for (final item in items) {
    total += item.$3 * item.$4;
  }
  return {
    'number': 1,
    'items': [
      for (final item in items)
        {
          'productId': item.$1,
          'name': item.$1,
          'category': item.$2,
          'price': item.$3,
          'description': '',
          'quantity': item.$4,
        },
    ],
    'totalPrice': total - rewardDiscount,
    'tableNumber': 1,
    'tableCode': 'ABCDEF',
    'status': status,
    'userId': 'u',
    'customerName': 'Host',
    'createdAt': Timestamp.fromDate(time),
    if (rewardDiscount > 0) ...{
      'rewardProductId': items.first.$1,
      'rewardDiscount': rewardDiscount,
      'rewardStamps': 9,
    },
  };
}

void main() {
  test('Období: týden od pondělí, srovnání se stejně dlouhým úsekem', () {
    // Čtvrtek 12. 11. 2026, 14:00.
    final now = DateTime(2026, 11, 12, 14);
    final week = periodRange(StatsPeriod.week, now);
    expect(week.start, DateTime(2026, 11, 9));
    expect(week.previousStart, DateTime(2026, 11, 2));
    expect(week.previousEnd, DateTime(2026, 11, 5, 14));

    final day = periodRange(StatsPeriod.day, now);
    expect(day.previousStart, DateTime(2026, 11, 11));
    expect(day.previousEnd, DateTime(2026, 11, 11, 14));

    // 31. 3.: předchozí (únor) je kratší – srovnání nepřeteče do března.
    final month = periodRange(StatsPeriod.month, DateTime(2026, 3, 31, 12));
    expect(month.previousStart, DateTime(2026, 2, 1));
    expect(month.previousEnd, DateTime(2026, 3, 1));
  });

  test('Součty, srovnání, nejprodávanější a kategorie', () {
    final now = DateTime(2026, 11, 12, 14);
    Order order(Map<String, dynamic> data) => Order.fromMap('id', data);
    final orders = [
      // Dnes: 2 dokončené objednávky.
      order(statsOrder(DateTime(2026, 11, 12, 9), [
        ('Latte', 'Káva', 70, 2),
        ('Dort', 'Dezerty', 90, 1),
      ])),
      order(statsOrder(DateTime(2026, 11, 12, 10), [('Espresso', 'Káva', 45, 3)],
          rewardDiscount: 45)),
      // Dnes, ale nedokončená → nepočítá se.
      order(statsOrder(DateTime(2026, 11, 12, 11), [('Latte', 'Káva', 70, 5)],
          status: 'prijata')),
      // Včera do 14:00 → srovnání.
      order(statsOrder(DateTime(2026, 11, 11, 9), [('Latte', 'Káva', 70, 2)])),
      // Včera po 14:00 → do srovnání nepatří.
      order(statsOrder(DateTime(2026, 11, 11, 18), [('Latte', 'Káva', 70, 9)])),
    ];
    final stats = computeStats(orders, StatsPeriod.day, now);

    expect(stats.orderCount, 2);
    expect(stats.revenue, 230 + 90); // 230 + (135 − 45)
    expect(stats.average, 160);
    expect(stats.previousRevenue, 140);
    expect(percentChange(stats.revenue, stats.previousRevenue), 129);

    expect(stats.topProducts.first.name, 'Espresso'); // 3 ks
    expect(stats.topProducts[1].name, 'Latte'); // 2 ks
    expect(stats.categories.first.name, 'Káva');
    expect(stats.rewardCount, 1);
    expect(stats.rewardValue, 45);

    // Graf po hodinách: v 9 h tržba 230 Kč.
    final nine = stats.chart.firstWhere((bar) => bar.label == '9');
    expect(nine.value, 230);
  });

  testWidgets('Admin otevře statistiky z úvodu', (WidgetTester tester) async {
    // Vyšší „telefon“, aby se dlaždice, graf i žebříček vešly na obrazovku.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = FakeFirebaseFirestore();
    final app = await buildTestApp(db: db);
    await db.collection('users').doc(testUser.uid).set({'role': 'admin'});
    final now = DateTime.now();
    await db.collection('orders').add(statsOrder(
          DateTime(now.year, now.month, now.day),
          [('Latte', 'Káva', 70, 2)],
        ));

    await pumpApp(tester, app);
    await scrollAndTap(tester, find.text('Statistiky'));

    expect(find.text('Tržba'), findsOneWidget);
    expect(find.text('140 Kč'), findsWidgets);
    expect(find.text('Latte'), findsOneWidget);
    expect(find.text('2 ks'), findsOneWidget);

    // Klepnutí na první sloupec (objednávka je o půlnoci = sloupec 0 h)
    // ukáže bublinu s detailem.
    final chart = tester.getTopLeft(find.byType(BarChart));
    await tester.tapAt(chart + const Offset(4, 150));
    await tester.pumpAndSettle();
    expect(find.text('0:00–1:00'), findsOneWidget);
    expect(find.text('1 objednávka'), findsOneWidget);

    // Níže je prstencový graf kategorií s celkovou tržbou uprostřed.
    await tester.dragUntilVisible(
        find.text('celkem'), find.byType(ListView), const Offset(0, -300));
    expect(find.text('celkem'), findsOneWidget);

    // Zpět nahoru a přepnutí na měsíc.
    await tester.dragUntilVisible(
        find.text('Měsíc'), find.byType(ListView), const Offset(0, 300));
    await tester.tap(find.text('Měsíc'));
    await tester.pumpAndSettle();
    expect(find.text('Tržba po dnech'), findsOneWidget);
  });
}
