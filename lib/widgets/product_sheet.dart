import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/product_option.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'drink_icon.dart';
import '../l10n/language.dart';

// Otevře detail produktu jako okno vysunuté zespodu.
// [allGroups] = všechny skupiny možností z databáze; nabídnou se jen ty,
// které má produkt zapnuté. Vrátí položku do košíku (množství + vybrané
// možnosti), nebo null, když zákazník okno zavře bez přidání.
Future<CartItem?> showProductSheet(
  BuildContext context,
  Product product, {
  List<OptionGroup> allGroups = const [],
}) {
  return showModalBottomSheet<CartItem>(
    context: context,
    isScrollControlled: true,
    builder: (context) => ProductSheet(
      product: product,
      groups: groupsForProduct(product, allGroups),
    ),
  );
}

// Skupiny možností, které má produkt zapnuté (v pořadí, jak je admin
// zapnul). Smazané nebo prázdné skupiny se přeskočí.
List<OptionGroup> groupsForProduct(
  Product product,
  List<OptionGroup> allGroups,
) {
  final byId = {for (final group in allGroups) group.id: group};
  return [
    for (final id in product.optionGroupIds)
      if (byId[id] != null && byId[id]!.choices.isNotEmpty) byId[id]!,
  ];
}

class ProductSheet extends StatefulWidget {
  final Product product;
  final List<OptionGroup> groups;

  const ProductSheet({
    super.key,
    required this.product,
    this.groups = const [],
  });

  @override
  State<ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<ProductSheet> {
  int quantity = 1;

  // Vybraná volba v každé skupině (index; 0 = výchozí).
  late final List<int> selected = List.filled(widget.groups.length, 0);

  // Položka tak, jak ji zákazník právě nastavil.
  CartItem get item => CartItem(
        product: widget.product,
        quantity: quantity,
        options: chosenOptions(widget.groups, selected),
      );

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
            // Popis a možnosti se dají posunout, kdyby jich bylo hodně;
            // cena a tlačítko zůstanou vždy dole.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildHeader(product),
                    const SizedBox(height: 16),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: context.colors.dark,
                      ),
                    ),
                    for (var i = 0; i < widget.groups.length; i++)
                      buildGroup(i),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Cena (i s příplatky) a výběr množství.
            Row(
              children: [
                Text(
                  formatPrice(item.unitPrice),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
                const Spacer(),
                IconButton.outlined(
                  icon: const Icon(Icons.remove),
                  tooltip: context.t.decreaseQuantity,
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
                  tooltip: context.t.increaseQuantity,
                  onPressed: () => setState(() => quantity++),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Přidání do košíku: okno se zavře a vrátí položku.
            SizedBox(
              width: double.infinity,
              // Vyprodaný produkt nejde přidat – tlačítko je zešedlé.
              child: ElevatedButton(
                onPressed: product.isAvailable
                    ? () => Navigator.pop(context, item)
                    : null,
                child: Text(
                  product.isAvailable
                      ? context.t.addToCartPrice(formatPrice(item.totalPrice))
                      : context.t.currentlySoldOut,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(Product product) {
    return Row(
      children: [
        // Velká nakreslená ikona nápoje.
        ProductIcon(product: product, size: 88),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.colors.dark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.category,
                style: TextStyle(color: context.colors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Jedna skupina možností: nadpis („Mléko“) a volby jako štítky,
  // u placených i příplatek („Ovesné +15 Kč“).
  Widget buildGroup(int index) {
    final group = widget.groups[index];
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.colors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < group.choices.length; i++)
                ChoiceChip(
                  label: Text(
                    group.choices[i].price > 0
                        ? '${group.choices[i].name} '
                            '+${formatPrice(group.choices[i].price)}'
                        : group.choices[i].name,
                  ),
                  selected: selected[index] == i,
                  onSelected: (_) => setState(() => selected[index] = i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
