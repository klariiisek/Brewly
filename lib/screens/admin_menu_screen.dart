import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';
import 'product_form_screen.dart';

// Správa menu pro admina: seznam všech produktů rozdělený podle kategorií.
// - přepínač u produktu = rychle označit jako vyprodaný / zase dostupný
// - klik na produkt = úprava (nebo smazání)
// - tlačítko dole = nový produkt
class AdminMenuScreen extends StatefulWidget {
  final ProductService productService;

  const AdminMenuScreen({super.key, required this.productService});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  late final Stream<List<Product>> productsStream;

  // Poslední načtené produkty – formulář z nich nabízí existující kategorie.
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    productsStream = widget.productService.watchProducts();
  }

  // Všechny kategorie, které v menu jsou (každá jen jednou).
  List<String> get categories =>
      products.map((product) => product.category).toSet().toList();

  Future<void> toggleAvailable(Product product, bool isAvailable) async {
    try {
      await widget.productService.setAvailable(product.id, isAvailable);
      if (!mounted) return;
      showAppMessage(
        context,
        isAvailable
            ? '${product.name} je zase k dispozici'
            : '${product.name}: vyprodáno',
      );
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Změnu se nepodařilo uložit');
    }
  }

  // Otevře formulář. Bez produktu = nový produkt, s produktem = úprava.
  void openForm([Product? product]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(
          productService: widget.productService,
          product: product,
          categories: categories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Správa menu')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Přidat produkt'),
      ),
      body: StreamBuilder<List<Product>>(
        stream: productsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.cloud_off,
              title: 'Menu se nepodařilo načíst',
              message: 'Zkontrolujte připojení k internetu.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          products = snapshot.data!;
          if (products.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book,
              title: 'Menu je prázdné',
              message: 'Přidejte první produkt.',
              buttonText: 'Přidat produkt',
              onPressed: () => openForm(),
            );
          }
          return buildList();
        },
      ),
    );
  }

  Widget buildList() {
    return ListView.builder(
      // Dole místo navíc, aby poslední produkt nezakrývalo tlačítko.
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        // Nadpis kategorie nad prvním produktem každé kategorie.
        final isFirstInCategory =
            index == 0 || products[index - 1].category != product.category;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFirstInCategory)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  product.category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCoffee,
                  ),
                ),
              ),
            ProductCard(
              product: product,
              onTap: () => openForm(product),
              trailing: Switch(
                value: product.isAvailable,
                onChanged: (value) => toggleAvailable(product, value),
              ),
            ),
          ],
        );
      },
    );
  }
}
