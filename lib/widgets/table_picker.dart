import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../theme/app_theme.dart';

// Otevře zespodu okno s výběrem stolu. Vrátí číslo stolu,
// nebo null, když zákazník okno zavře bez výběru.
Future<int?> showTablePicker(BuildContext context, {int? current}) {
  return showModalBottomSheet<int>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'U kterého stolu sedíte?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCoffee,
              ),
            ),
            const SizedBox(height: 16),
            // Wrap = štítky vedle sebe, a když se nevejdou, pokračují na dalším řádku.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var number = 1; number <= Cart.tableCount; number++)
                  ChoiceChip(
                    label: Text('Stůl $number'),
                    selected: number == current,
                    showCheckmark: false,
                    selectedColor: AppColors.coffee,
                    labelStyle: TextStyle(
                      color: number == current
                          ? Colors.white
                          : AppColors.darkCoffee,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => Navigator.pop(context, number),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
