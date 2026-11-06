import 'dart:async';

import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../models/sales_stats.dart';
import '../models/venue_settings.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/bar_chart.dart';
import '../widgets/donut_chart.dart';
import '../widgets/drink_icon.dart';
import '../widgets/empty_state.dart';

// Statistiky prodeje pro admina: tržba, počet objednávek, průměrná útrata,
// graf, nejprodávanější produkty a tržba podle kategorií.
class StatisticsScreen extends StatefulWidget {
  final AppServices services;

  const StatisticsScreen({super.key, required this.services});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatsPeriod period = StatsPeriod.day;
  late Stream<List<Order>> ordersStream;

  // Aktuální menu – kvůli ikonám produktů v žebříčku (podle ID produktu).
  StreamSubscription<List<Product>>? menuSubscription;
  Map<String, Product> menuById = {};

  @override
  void initState() {
    super.initState();
    loadOrders();
    menuSubscription = widget.services.products.watchProducts().listen(
          (menu) => setState(
            () => menuById = {for (final product in menu) product.id: product},
          ),
        );
  }

  @override
  void dispose() {
    menuSubscription?.cancel();
    super.dispose();
  }

  // Načte objednávky od začátku PŘEDCHOZÍHO období (kvůli srovnání).
  void loadOrders() {
    final range = periodRange(period, DateTime.now());
    ordersStream =
        widget.services.orders.watchOrdersSince(range.previousStart);
  }

  void changePeriod(StatsPeriod value) {
    setState(() {
      period = value;
      loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiky')),
      body: StreamBuilder<List<Order>>(
        stream: ordersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.cloud_off,
              title: 'Statistiky se nepodařilo načíst',
              message: 'Zkontrolujte připojení k internetu.',
            );
          }
          final orders = snapshot.data;
          final stats =
              orders == null ? null : computeStats(orders, period, DateTime.now());
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Přepínač období.
                  SegmentedButton<StatsPeriod>(
                    segments: [
                      for (final value in StatsPeriod.values)
                        ButtonSegment(value: value, label: Text(value.label)),
                    ],
                    selected: {period},
                    showSelectedIcon: false,
                    onSelectionChanged: (selected) =>
                        changePeriod(selected.first),
                  ),
                  const SizedBox(height: 16),
                  if (stats == null)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ...buildStats(stats),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Text srovnání pod dlaždicemi podle období.
  String get comparedTo => switch (period) {
        StatsPeriod.day => 'oproti včerejšku',
        StatsPeriod.week => 'oproti min. týdnu',
        StatsPeriod.month => 'oproti min. měsíci',
      };

  List<Widget> buildStats(SalesStats stats) {
    return [
      // Tři dlaždice. Na širší obrazovce vedle sebe, na telefonu je tržba
      // (nejdůležitější číslo) přes celou šířku a pod ní dvě menší.
      LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 480;
          final width = isWide
              ? (constraints.maxWidth - 16) / 3
              : (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: isWide ? width : constraints.maxWidth,
                child: StatTile(
                  icon: Icons.payments_outlined,
                  label: 'Tržba',
                  value: stats.revenue,
                  format: formatPrice,
                  animationKey: period,
                  change: percentChange(stats.revenue, stats.previousRevenue),
                  comparedTo: comparedTo,
                ),
              ),
              SizedBox(
                width: width,
                child: StatTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Objednávky',
                  value: stats.orderCount.toDouble(),
                  format: (value) => '${value.round()}',
                  animationKey: period,
                  change: percentChange(stats.orderCount.toDouble(),
                      stats.previousOrderCount.toDouble()),
                  comparedTo: comparedTo,
                ),
              ),
              SizedBox(
                width: width,
                child: StatTile(
                  icon: Icons.person_outline,
                  label: 'Průměrná útrata',
                  value: stats.average,
                  format: formatPrice,
                  animationKey: period,
                  change: percentChange(stats.average, stats.previousAverage),
                  comparedTo: comparedTo,
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      buildSection(
        period == StatsPeriod.day ? 'Tržba po hodinách' : 'Tržba po dnech',
        stats.revenue == 0
            ? buildNote('Zatím žádná dokončená objednávka.')
            : BarChart(bars: stats.chart, animationKey: period),
      ),
      buildSection(
        'Nejprodávanější produkty',
        stats.topProducts.isEmpty
            ? buildNote('Zatím se nic neprodalo.')
            : buildRanking(
                stats.topProducts,
                value: (item) => item.quantity.toDouble(),
                text: (item) => '${item.quantity} ks',
                leading: (item) =>
                    ProductIcon(product: productOf(item), size: 40),
              ),
      ),
      buildSection(
        'Tržba podle kategorií',
        stats.categories.isEmpty
            ? buildNote('Zatím se nic neprodalo.')
            : buildCategories(stats.categories),
      ),
      if (VenueScope.of(context).hasLoyalty)
        buildSection(
          'Razítková karta',
          Row(
            children: [
              Icon(Icons.card_giftcard, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stats.rewardCount == 0
                      ? 'V tomto období zatím žádná odměna.'
                      : 'Vydáno odměn: ${stats.rewardCount} '
                          '(v hodnotě ${formatPrice(stats.rewardValue)})',
                ),
              ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Počítají se jen dokončené objednávky. Tržba je po odečtení '
          'odměn z razítkové karty.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.muted, fontSize: 12),
        ),
      ),
    ];
  }

  // Bílá karta s nadpisem.
  Widget buildSection(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.colors.dark,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(text, style: TextStyle(color: context.colors.muted)),
      ),
    );
  }

  // Produkt pro ikonu: z menu (admin mohl ikonu vybrat), jinak jen název
  // a kategorie – ikonu pak aplikace odhadne.
  Product productOf(RankItem item) {
    return menuById[item.productId] ??
        Product(
          name: item.name,
          price: 0,
          category: item.category,
          description: '',
        );
  }

  // Kategorie: prstencový graf a vedle legenda se stejnými barvami.
  Widget buildCategories(List<RankItem> categories) {
    final colors = chartColors(context.colors, categories.length);
    final total =
        categories.fold(0.0, (sum, category) => sum + category.revenue);
    return Row(
      children: [
        DonutChart(
          values: [for (final category in categories) category.revenue],
          colors: colors,
          centerText: formatPrice(total),
          centerLabel: 'celkem',
          animationKey: period,
          size: 130,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              for (var index = 0; index < categories.length; index++)
                buildLegendRow(categories[index], colors[index], total),
            ],
          ),
        ),
      ],
    );
  }

  // Řádek legendy: barevná tečka, název, procenta a tržba.
  Widget buildLegendRow(RankItem category, Color color, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.colors.dark,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(category.revenue / total * 100).round()} %',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                formatPrice(category.revenue),
                style: TextStyle(fontSize: 12, color: context.colors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Žebříček s vodorovnými proužky (nejvyšší hodnota = plný proužek).
  // Proužky se při načtení plynule „naplní“.
  Widget buildRanking(
    List<RankItem> items, {
    required double Function(RankItem) value,
    required String Function(RankItem) text,
    Widget Function(RankItem)? leading,
  }) {
    final maxValue = value(items.first);
    final colors = context.colors;
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading(item),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.dark,
                              ),
                            ),
                          ),
                          Text(
                            text(item),
                            style: TextStyle(color: colors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        key: ValueKey(period),
                        tween: Tween(
                          begin: 0,
                          end: maxValue == 0 ? 0 : value(item) / maxValue,
                        ),
                        duration: chartAnimation(context),
                        curve: Curves.easeOutCubic,
                        builder: (context, fill, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: fill,
                            minHeight: 8,
                            color: colors.primary,
                            backgroundColor:
                                colors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Dlaždice s jedním číslem a změnou oproti předchozímu období.
// Číslo se při načtení rychle „napočítá“ od nuly (0 → 3 890 Kč).
class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String Function(double) format;
  final int? change;
  final String comparedTo;
  final Object animationKey;

  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.format,
    required this.change,
    required this.comparedTo,
    required this.animationKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final change = this.change;
    final isUp = change != null && change >= 0;
    final changeColor = change == null
        ? colors.muted
        : isUp
            ? AppColors.success
            : Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: colors.muted, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            key: ValueKey(animationKey),
            tween: Tween(begin: 0, end: value),
            duration: chartAnimation(context),
            curve: Curves.easeOutCubic,
            builder: (context, shown, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                format(shown),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.dark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (change != null)
                Icon(
                  isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: changeColor,
                ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  change == null
                      ? '– $comparedTo'
                      : '${change.abs()} % $comparedTo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
