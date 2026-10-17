import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/app_services.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';
import '../utils/text.dart';
import 'categories_screen.dart';
import 'csv_import_screen.dart';
import 'product_form_screen.dart';

// Správa menu pro admina: seznam všech produktů rozdělený podle kategorií.
// - přepínač u produktu = rychle označit jako vyprodaný / zase dostupný
// - klik na produkt = úprava (nebo smazání)
// - tlačítko dole = nový produkt
class AdminMenuScreen extends StatefulWidget {
  final AppServices services;

  const AdminMenuScreen({super.key, required this.services});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  late final Stream<List<Product>> productsStream;

  // Poslední načtené produkty.
  List<Product> products = [];
  bool isMigrating = false;

  // Text z vyhledávacího pole.
  final searchController = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    super.initState();
    productsStream = widget.services.products.watchProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Produkty, jejichž název nebo kategorie obsahuje hledaný text.
  // Nezáleží na velkých písmenech ani diakritice ("kava" najde "Káva").
  List<Product> get filteredProducts {
    final query = normalizeText(searchText);
    if (query.isEmpty) return products;
    return products
        .where((product) =>
            normalizeText(product.name).contains(query) ||
            normalizeText(product.category).contains(query))
        .toList();
  }

  void openCsvImport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CsvImportScreen(productService: widget.services.products),
      ),
    );
  }

  // Převod starých produktů (kategorie jako text) na odkazy do kolekce
  // kategorií. Stačí jednou – pak upozornění zmizí.
  Future<void> migrateCategories() async {
    setState(() => isMigrating = true);
    try {
      final count = await widget.services.products.migrateCategories();
      if (!mounted) return;
      showAppMessage(context, 'Převedeno produktů: $count');
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Převod se nepodařil');
    } finally {
      if (mounted) setState(() => isMigrating = false);
    }
  }

  Future<void> toggleAvailable(Product product, bool isAvailable) async {
    try {
      await widget.services.products.setAvailable(product.id, isAvailable);
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
          productService: widget.services.products,
          product: product,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Správa menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Kategorie',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CategoriesScreen(services: widget.services),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Nahrát z CSV',
            onPressed: openCsvImport,
          ),
        ],
      ),
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
          // Už seřazené podle pořadí kategorií (z kolekce kategorií).
          products = snapshot.data!;
          if (products.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book,
              title: 'Menu je prázdné',
              message: 'Přidejte první produkt, nebo nahrajte celé menu '
                  'ze souboru CSV.',
              buttonText: 'Nahrát z CSV',
              onPressed: openCsvImport,
            );
          }
          return Column(
            children: [
              if (ProductService.needsCategoryMigration(products))
                buildMigrationBanner(),
              buildSearchField(),
              Expanded(child: buildList(filteredProducts)),
            ],
          );
        },
      ),
    );
  }

  // Upozornění: produkty mají ještě starý formát kategorií (text).
  Widget buildMigrationBanner() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategorie mají nový formát',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Některé produkty mají kategorii uloženou postaru jako text. '
              'Převeďte je, aby šly upravovat.',
              style: TextStyle(color: context.colors.muted),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isMigrating ? null : migrateCategories,
              child: Text(isMigrating ? 'Převádím…' : 'Převést kategorie'),
            ),
          ],
        ),
      ),
    );
  }

  // Vyhledávací pole nahoře. Křížek vpravo hledání smaže.
  Widget buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Hledat produkt nebo kategorii',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchText.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Zrušit hledání',
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchText = '');
                  },
                ),
        ),
        onChanged: (value) => setState(() => searchText = value),
      ),
    );
  }

  Widget buildList(List<Product> products) {
    if (products.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Nic nenalezeno',
        message: 'Zkuste hledat jinak.',
      );
    }
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colors.dark,
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
