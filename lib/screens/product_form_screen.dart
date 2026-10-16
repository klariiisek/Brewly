import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';

// Formulář pro admina: nový produkt, nebo úprava existujícího.
class ProductFormScreen extends StatefulWidget {
  final ProductService productService;

  // null = přidáváme nový produkt.
  final Product? product;

  // Kategorie, které už v menu jsou (nabídnou se jako štítky).
  final List<String> categories;

  const ProductFormScreen({
    super.key,
    required this.productService,
    this.product,
    this.categories = const [],
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController categoryController;
  late final TextEditingController descriptionController;
  bool isAvailable = true;
  bool isSaving = false;

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
    categoryController = TextEditingController(text: product?.category ?? '');
    descriptionController =
        TextEditingController(text: product?.description ?? '');
    isAvailable = product?.isAvailable ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    categoryController.dispose();
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
    if (price > 10000) return 'Tak drahé to snad nebude 🙂';
    return null;
  }

  String? validateRequired(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.product?.id ?? '',
      name: nameController.text.trim(),
      price: parsePrice(priceController.text)!,
      category: categoryController.text.trim(),
      description: descriptionController.text.trim(),
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
            TextFormField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Kategorie'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  validateRequired(value, 'Zadejte kategorii'),
            ),
            // Štítky s existujícími kategoriemi – stačí kliknout.
            if (widget.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final category in widget.categories)
                    ActionChip(
                      label: Text(category),
                      onPressed: () => setState(() {
                        categoryController.text = category;
                      }),
                    ),
                ],
              ),
            ],
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
                style: const TextStyle(color: AppColors.muted),
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
