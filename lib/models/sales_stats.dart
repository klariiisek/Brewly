import '../utils/format.dart';
import 'order.dart';

// Statistiky prodeje pro admina. Nikam se neukládají – počítají se
// z objednávek, podobně jako SUM, COUNT a GROUP BY v SQL.
// Počítají se jen DOKONČENÉ objednávky (nedokončená nemusí být zaplacená).

// Za jaké období se statistiky ukazují.
enum StatsPeriod {
  day('Dnes'),
  week('Týden'),
  month('Měsíc');

  final String label;
  const StatsPeriod(this.label);
}

// Časový úsek: aktuální období a stejně dlouhý kus předchozího období
// (pro srovnání „oproti minulému týdnu“).
class PeriodRange {
  final DateTime start;
  final DateTime end;
  final DateTime previousStart;
  final DateTime previousEnd;

  const PeriodRange({
    required this.start,
    required this.end,
    required this.previousStart,
    required this.previousEnd,
  });

  bool contains(DateTime time) => !time.isBefore(start) && time.isBefore(end);

  bool previousContains(DateTime time) =>
      !time.isBefore(previousStart) && time.isBefore(previousEnd);
}

// Začátek období a stejně dlouhý úsek předchozího období.
// Srovnáváme férově: dnešek do 14:00 se srovná se včerejškem do 14:00,
// ne s celým včerejším dnem.
PeriodRange periodRange(StatsPeriod period, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final DateTime start;
  final DateTime previousStart;
  switch (period) {
    case StatsPeriod.day:
      start = today;
      previousStart = DateTime(today.year, today.month, today.day - 1);
    case StatsPeriod.week:
      // Týden začíná pondělím (weekday: pondělí = 1).
      start = DateTime(today.year, today.month, today.day - (today.weekday - 1));
      previousStart = DateTime(start.year, start.month, start.day - 7);
    case StatsPeriod.month:
      start = DateTime(today.year, today.month);
      previousStart = DateTime(today.year, today.month - 1);
  }
  var previousEnd = previousStart.add(now.difference(start));
  // Předchozí měsíc může být kratší – srovnání nesmí přetéct do aktuálního.
  if (previousEnd.isAfter(start)) previousEnd = start;
  return PeriodRange(
    start: start,
    end: now.add(const Duration(seconds: 1)),
    previousStart: previousStart,
    previousEnd: previousEnd,
  );
}

// Jeden sloupec grafu (hodina, den v týdnu nebo den v měsíci).
class ChartBar {
  final String label; // krátký popisek pod sloupcem („St“, „9“)
  final double value; // tržba
  final String title; // celý popisek do bubliny („St 4. 11.“, „9:00–10:00“)
  final int count; // počet objednávek

  const ChartBar(this.label, this.value, {this.title = '', this.count = 0});
}

// Jeden řádek žebříčku (produkt nebo kategorie).
class RankItem {
  final String name;
  final int quantity;
  final double revenue;

  // U produktu: jeho kategorie a ID v menu (kvůli ikoně).
  final String category;
  final String productId;

  const RankItem(
    this.name,
    this.quantity,
    this.revenue, {
    this.category = '',
    this.productId = '',
  });
}

class SalesStats {
  final double revenue;
  final int orderCount;
  final double previousRevenue;
  final int previousOrderCount;

  // Sloupce grafu tržeb.
  final List<ChartBar> chart;

  // Nejprodávanější produkty (podle počtu kusů) a tržba po kategoriích.
  final List<RankItem> topProducts;
  final List<RankItem> categories;

  // Razítková karta: kolik odměn se vydalo a kolik stály.
  final int rewardCount;
  final double rewardValue;

  const SalesStats({
    required this.revenue,
    required this.orderCount,
    required this.previousRevenue,
    required this.previousOrderCount,
    required this.chart,
    required this.topProducts,
    required this.categories,
    required this.rewardCount,
    required this.rewardValue,
  });

  // Průměrná útrata za objednávku.
  double get average => orderCount == 0 ? 0 : revenue / orderCount;
  double get previousAverage =>
      previousOrderCount == 0 ? 0 : previousRevenue / previousOrderCount;
}

// Změna v procentech oproti předchozímu období (null = nemáme s čím srovnat).
int? percentChange(double current, double previous) {
  if (previous == 0) return null;
  return ((current - previous) / previous * 100).round();
}

const _weekdays = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];

// Spočítá statistiky za období z objednávek.
SalesStats computeStats(List<Order> orders, StatsPeriod period, DateTime now) {
  final range = periodRange(period, now);
  final done =
      orders.where((order) => order.status == OrderStatus.dokoncena).toList();
  final current = done.where((order) => range.contains(order.time)).toList();
  final previous =
      done.where((order) => range.previousContains(order.time)).toList();

  double sum(List<Order> list) =>
      list.fold(0.0, (total, order) => total + order.totalPrice);

  // Produkty a kategorie – seskupení podle názvu (jako GROUP BY).
  final products = <String, RankItem>{};
  final categories = <String, RankItem>{};
  void add(
    Map<String, RankItem> map,
    String name,
    int quantity,
    double revenue, {
    String category = '',
    String productId = '',
  }) {
    final old = map[name];
    map[name] = RankItem(
      name,
      (old?.quantity ?? 0) + quantity,
      (old?.revenue ?? 0) + revenue,
      category: category,
      productId: productId,
    );
  }

  var rewardCount = 0;
  var rewardValue = 0.0;
  for (final order in current) {
    for (final item in order.items) {
      final revenue = item.product.price * item.quantity;
      add(products, item.product.name, item.quantity, revenue,
          category: item.product.category, productId: item.product.id);
      add(categories, item.product.category, item.quantity, revenue);
    }
    if (order.hasReward) {
      rewardCount++;
      rewardValue += order.rewardDiscount;
    }
  }
  final topProducts = products.values.toList()
    ..sort((a, b) => b.quantity.compareTo(a.quantity));
  final categoryList = categories.values.toList()
    ..sort((a, b) => b.revenue.compareTo(a.revenue));

  return SalesStats(
    revenue: sum(current),
    orderCount: current.length,
    previousRevenue: sum(previous),
    previousOrderCount: previous.length,
    chart: _chart(current, period, range),
    topProducts: topProducts.take(5).toList(),
    categories: categoryList,
    rewardCount: rewardCount,
    rewardValue: rewardValue,
  );
}

// Sloupce grafu: dnes po hodinách, týden po dnech (Po–Ne),
// měsíc po dnech (1.–31.). Každý sloupec má tržbu a počet objednávek.
List<ChartBar> _chart(List<Order> orders, StatsPeriod period, PeriodRange range) {
  // Do kterého sloupce objednávka patří a kolik je sloupců.
  final int Function(DateTime) slotOf;
  final int slots;
  switch (period) {
    case StatsPeriod.day:
      slotOf = (time) => time.hour;
      slots = 24;
    case StatsPeriod.week:
      slotOf = (time) => time.weekday - 1;
      slots = 7;
    case StatsPeriod.month:
      slotOf = (time) => time.day - 1;
      slots = DateTime(range.start.year, range.start.month + 1, 0).day;
  }
  final revenue = List<double>.filled(slots, 0);
  final counts = List<int>.filled(slots, 0);
  for (final order in orders) {
    revenue[slotOf(order.time)] += order.totalPrice;
    counts[slotOf(order.time)]++;
  }

  if (period == StatsPeriod.day) {
    // Ukážeme aspoň 8–20 h, a když se objednávalo dřív nebo později, i to.
    var first = 8;
    var last = 20;
    for (var hour = 0; hour < 24; hour++) {
      if (counts[hour] > 0) {
        if (hour < first) first = hour;
        if (hour > last) last = hour;
      }
    }
    return [
      for (var hour = first; hour <= last; hour++)
        ChartBar('$hour', revenue[hour],
            title: '$hour:00–${hour + 1}:00', count: counts[hour]),
    ];
  }

  // Týden a měsíc: den = začátek období + pořadí sloupce.
  return [
    for (var index = 0; index < slots; index++)
      ChartBar(
        period == StatsPeriod.week ? _weekdays[index] : '${index + 1}',
        revenue[index],
        title: formatDay(DateTime(
            range.start.year, range.start.month, range.start.day + index)),
        count: counts[index],
      ),
  ];
}
