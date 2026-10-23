import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/menu_category.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/category_name_dialog.dart';
import '../widgets/drink_icon.dart';

// Formulář pro admina: nový produkt, nebo úprava existujícího.
class ProductFormScreen extends StatefulWidget {
  final ProductService productService;

  // null = přidáváme nový produkt.
  final Product? product;

  const ProductFormScreen({
    super.key,
    required this.productService,
    this.product,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController descriptionController;
  bool isAvailable = true;
  bool isSaving = false;

  // Vybraná kategorie (ID z kolekce kategorií) a seznam všech kategorií.
  String? categoryId;

  // Vybraná ikona (klíč, např. "latte"). Prázdná = automaticky podle názvu.
  String iconKey = '';
  late final Stream<List<MenuCategory>> categoriesStream;
  List<MenuCategory> categories = [];

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    // Při úpravě předvyplníme pole současnými údaji produktu.
    final product = widget.product;
    nameController = TextEditingController(text: product?.name ?? '');
    priceController = TextEditingController(
      text: product == null ? '' : formatPriceInput(product.price),
    );
    descriptionController =
        TextEditingController(text: product?.description ?? '');
    isAvailable = product?.isAvailable ?? true;
    final currentCategory = product?.categoryId ?? '';
    categoryId = currentCategory.isEmpty ? null : currentCategory;
    iconKey = product?.icon ?? '';
    categoriesStream = widget.productService.categories.watchCategories();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // 45.0 → "45", 45.5 → "45,5" (jak jsou zvyklí Češi).
  String formatPriceInput(double price) {
    if (price == price.roundToDouble()) return price.toInt().toString();
    return price.toString().replaceAll('.', ',');
  }

  // Přečte cenu z textu. Funguje s desetinnou čárkou i tečkou.
  double? parsePrice(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  String? validatePrice(String? value) {
    final price = parsePrice(value ?? '');
    if (price == null) return 'Zadejte cenu číslem';
    if (price <= 0) return 'Cena musí být větší než 0';
    if (price > AppConfig.maxProductPrice) return 'Tak drahé to snad nebude 🙂';
    return null;
  }

  String? validateRequired(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  // Založí novou kategorii (na konec pořadí) a rovnou ji vybere.
  Future<void> addCategory() async {
    final name = await askForCategoryName(
      context,
      title: 'Nová kategorie',
      buttonText: 'Přidat',
      existingNames: categories.map((category) => category.name).toList(),
    );
    if (name == null) return;
    try {
      final id = await widget.productService.categories
          .addCategory(name, order: categories.length);
      if (!mounted) return;
      setState(() => categoryId = id);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Kategorii se nepodařilo přidat');
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.product?.id ?? '',
      name: nameController.text.trim(),
      price: parsePrice(priceController.text)!,
      categoryId: categoryId!,
      category: categories
          .firstWhere((category) => category.id == categoryId,
              orElse: () =>
                  MenuCategory(id: categoryId!, name: '', order: 0))
          .name,
      description: descriptionController.text.trim(),
      icon: iconKey,
      isAvailable: isAvailable,
    );

    setState(() => isSaving = true);
    try {
      if (isEditing) {
        await widget.productService.updateProduct(product);
      } else {
        await widget.productService.addProduct(product);
      }
      if (!mounted) return;
      showAppMessage(
        context,
        isEditing ? 'Uloženo: ${product.name}' : 'Přidáno do menu: ${product.name}',
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => isSaving = false);
      showAppMessage(context, 'Produkt se nepodařilo uložit');
    }
  }

  Future<void> delete() async {
    final product = widget.product!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Smazat ${product.name}?'),
        content: const Text(
          'Produkt zmizí z menu. Staré objednávky zůstanou beze změny.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.productService.deleteProduct(product.id);
      if (!mounted) return;
      showAppMessage(context, 'Smazáno: ${product.name}');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Produkt se nepodařilo smazat');
    }
  }

  // Výběr kategorie: štítky se všemi kategoriemi + "Nová kategorie".
  // FormField = vlastní pole formuláře, aby šlo zkontrolovat, že je vybráno.
  // Výběr ikony: "Automaticky" (podle názvu) nebo konkrétní ikona.
  Widget buildIconPicker() {
    String categoryName = '';
    for (final category in categories) {
      if (category.id == categoryId) categoryName = category.name;
    }
    final guessed = guessDrinkIcon(nameController.text, categoryName);

    Widget option({
      required bool selected,
      required String label,
      required Widget icon,
      required VoidCallback onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: Container(
          width: 82,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: selected ? context.colors.primary : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Column(
            children: [
              SizedBox(width: 44, height: 44, child: icon),
              const SizedBox(height: 4),
              // Název na jeden řádek – dlouhý (Cappuccino) se jen trochu
              // zmenší, místo aby se rozdělil uprostřed slova.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(fontSize: 11, color: context.colors.dark),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ikona', style: TextStyle(color: context.colors.muted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // Automaticky: ukáže, jakou ikonu by aplikace podle názvu vybrala.
            option(
              selected: iconKey.isEmpty,
              label: 'Automaticky',
              icon: guessed == null
                  ? Icon(Icons.auto_awesome, color: context.colors.primary)
                  : DrinkIconView(icon: guessed),
              onTap: () => setState(() => iconKey = ''),
            ),
            for (final drink in DrinkIcon.values)
              option(
                selected: iconKey == drink.name,
                label: drink.label,
                icon: DrinkIconView(icon: drink),
                onTap: () => setState(() => iconKey = drink.name),
              ),
          ],
        ),
      ],
    );
  }

  Widget buildCategoryPicker() {
    return StreamBuilder<List<MenuCategory>>(
      stream: categoriesStream,
      builder: (context, snapshot) {
        categories = snapshot.data ?? categories;
        return FormField<String>(
          validator: (_) => categoryId == null ? 'Vyberte kategorii' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategorie',
                style: TextStyle(color: context.colors.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final category in categories)
                    ChoiceChip(
                      label: Text(category.name),
                      selected: category.id == categoryId,
                      onSelected: (_) {
                        setState(() => categoryId = category.id);
                        field.didChange(category.id);
                      },
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Nová kategorie'),
                    onPressed: addCategory,
                  ),
                ],
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Upravit produkt' : 'Nový produkt'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Smazat produkt',
              onPressed: isSaving ? null : delete,
            ),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Název'),
              // Při psaní se aktualizuje automaticky odhadnutá ikona.
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => validateRequired(value, 'Zadejte název'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Cena',
                suffixText: 'Kč',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: validatePrice,
            ),
            const SizedBox(height: 16),
            buildCategoryPicker(),
            const SizedBox(height: 16),
            buildIconPicker(),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Popis'),
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('K dispozici'),
              subtitle: Text(
                isAvailable
                    ? 'Zákazníci si ho mohou objednat'
                    : 'V menu bude označený jako vyprodaný',
                style: TextStyle(color: context.colors.muted),
              ),
              value: isAvailable,
              onChanged: (value) => setState(() => isAvailable = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSaving ? null : save,
              child: Text(isSaving ? 'Ukládám…' : 'Uložit'),
            ),
          ],
        ),
      ),
    );
  }
}
