import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'product_card.dart';

// Otevře detail produktu jako okno vysunuté zespodu.
// Vrátí vybrané množství, nebo null, když zákazník okno zavře bez přidání.
Future<int?> showProductSheet(BuildContext context, Product product) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) => ProductSheet(product: product),
  );
}

class ProductSheet extends StatefulWidget {
  final Product product;

  const ProductSheet({super.key, required this.product});

  @override
  State<ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<ProductSheet> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          // Okno bude jen tak vysoké, kolik potřebuje obsah.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Velká ikona kategorie.
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.coffee.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  child: Icon(
                    categoryIcon(product.category),
                    color: AppColors.coffee,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkCoffee,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              product.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.darkCoffee,
              ),
            ),
            const SizedBox(height: 24),

            // Cena a výběr množství.
            Row(
              children: [
                Text(
                  formatPrice(product.price),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.coffee,
                  ),
                ),
                const Spacer(),
                IconButton.outlined(
                  icon: const Icon(Icons.remove),
                  tooltip: 'Snížit množství',
                  // Méně než 1 kus nejde, tlačítko pak zešedne.
                  onPressed: quantity > 1
                      ? () => setState(() => quantity--)
                      : null,
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.outlined(
                  icon: const Icon(Icons.add),
                  tooltip: 'Zvýšit množství',
                  onPressed: () => setState(() => quantity++),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Přidání do košíku: okno se zavře a vrátí vybrané množství.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, quantity),
                child: Text(
                  'Přidat do košíku · ${formatPrice(product.price * quantity)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
