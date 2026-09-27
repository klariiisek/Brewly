import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

// Vrátí ikonu podle kategorie produktu.
IconData categoryIcon(String category) {
  switch (category) {
    case 'Káva':
      return Icons.coffee;
    case 'Dezerty':
      return Icons.cake;
    case 'Nápoje':
      return Icons.local_drink;
    default:
      return Icons.restaurant;
  }
}

// Karta jednoho produktu v menu: ikona, název, popis, cena a tlačítko +.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Aby efekt po kliknutí (InkWell) nepřečníval přes kulaté rohy.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Čtvereček s ikonou kategorie.
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.coffee.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(
                  categoryIcon(product.category),
                  color: AppColors.coffee,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),

              // Název, popis a cena.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkCoffee,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatPrice(product.price),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.coffee,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton.filled(
                icon: const Icon(Icons.add),
                tooltip: 'Přidat do košíku',
                onPressed: onAdd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
