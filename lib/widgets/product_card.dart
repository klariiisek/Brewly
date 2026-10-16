import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/text.dart';

// Vrátí ikonu podle kategorie produktu. Hledá části slov bez diakritiky,
// takže "Káva", "Kávy s sebou" i "Pivo točené" dostanou správnou ikonu.
// Hodí se pro kavárnu, bar i restauraci.
IconData categoryIcon(String category) {
  final text = normalizeText(category);
  const icons = {
    'kav': Icons.coffee,
    'caj': Icons.emoji_food_beverage,
    'dezert': Icons.cake,
    'dort': Icons.cake,
    'zakusk': Icons.cake,
    'snidan': Icons.egg_alt,
    'piv': Icons.sports_bar,
    'vin': Icons.wine_bar,
    'koktej': Icons.local_bar,
    'drink': Icons.local_bar,
    'polevk': Icons.soup_kitchen,
    'salat': Icons.eco,
    'pizz': Icons.local_pizza,
    'burger': Icons.lunch_dining,
    'napoj': Icons.local_drink,
    'limonad': Icons.local_drink,
  };
  for (final entry in icons.entries) {
    if (text.contains(entry.key)) return entry.value;
  }
  return Icons.restaurant;
}

// Karta jednoho produktu v menu: ikona, název, popis, cena a tlačítko +.
// Vyprodaný produkt je zešedlý a tlačítko + nejde zmáčknout.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  // Volitelně něco jiného místo tlačítka + (ve správě menu přepínač).
  final Widget? trailing;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAdd,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = product.isAvailable;

    return Card(
      // Aby efekt po kliknutí (InkWell) nepřečníval přes kulaté rohy.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Vyprodaný produkt je poloprůhledný.
              Expanded(
                child: Opacity(
                  opacity: isAvailable ? 1 : 0.45,
                  child: buildInfo(context),
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    tooltip: 'Přidat do košíku',
                    onPressed: isAvailable ? onAdd : null,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // Čtvereček s ikonou kategorie, název, popis a cena (případně "Vyprodáno").
  Widget buildInfo(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Icon(
            categoryIcon(product.category),
            color: context.colors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.colors.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                product.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.isAvailable
                    ? formatPrice(product.price)
                    : '${formatPrice(product.price)} • Vyprodáno',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
