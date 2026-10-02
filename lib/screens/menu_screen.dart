import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';
import '../widgets/product_sheet.dart';

class MenuScreen extends StatefulWidget {
  final Cart cart;
  final ProductService productService;

  // Zavolá se, když se změní obsah košíku (aby se aktualizovalo číslo v liště).
  final VoidCallback onCartChanged;

  const MenuScreen({
    super.key,
    required this.cart,
    required this.productService,
    required this.onCartChanged,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const String allCategories = 'Vše';

  // Právě vybraná kategorie.
  String selectedCategory = allCategories;

  // Proud produktů z databáze. Vytvoří se jen jednou (v initState),
  // aby se aplikace nepřipojovala k databázi znovu při každém překreslení.
  late final Stream<List<Product>> productsStream;

  @override
  void initState() {
    super.initState();
    productsStream = widget.productService.watchProducts();
  }

  // Seznam kategorií: "Vše" + každá kategorie z menu jen jednou.
  // toSet() odstraní duplicity (Káva je v menu třikrát, ale štítek chceme jeden).
  List<String> categoriesOf(List<Product> products) {
    return [
      allCategories,
      ...products.map((product) => product.category).toSet(),
    ];
  }

  // Produkty podle vybrané kategorie.
  List<Product> filterProducts(List<Product> products) {
    if (selectedCategory == allCategories) {
      return products;
    }
    return products
        .where((product) => product.category == selectedCategory)
        .toList();
  }

  // Pozdrav podle denní doby.
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'Dobré ráno';
    if (hour < 18) return 'Dobrý den';
    return 'Dobrý večer';
  }

  void addToCart(Product product, {int quantity = 1}) {
    widget.cart.addItem(CartItem(product: product, quantity: quantity));
    widget.onCartChanged();
    showAppMessage(context, 'Přidáno: $quantity× ${product.name}');
  }

  // Otevře detail zespodu. Když zákazník vybere množství, přidá ho do košíku.
  Future<void> openDetail(Product product) async {
    final quantity = await showProductSheet(context, product);
    if (quantity != null && mounted) {
      addToCart(product, quantity: quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          buildHeader(),
          // StreamBuilder se překreslí pokaždé, když z databáze přijdou nová data.
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: productsStream,
              builder: (context, snapshot) {
                // 1) Chyba, např. bez internetu.
                if (snapshot.hasError) {
                  return const EmptyState(
                    icon: Icons.cloud_off,
                    title: 'Menu se nepodařilo načíst',
                    message: 'Zkontrolujte připojení k internetu.',
                  );
                }
                // 2) Data ještě nedorazila: točící se kolečko.
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                // 3) Databáze je prázdná.
                final allProducts = snapshot.data!;
                if (allProducts.isEmpty) {
                  return const EmptyState(
                    icon: Icons.menu_book,
                    title: 'Menu je zatím prázdné',
                    message: 'Obsluha ho brzy doplní.',
                  );
                }
                // 4) Máme produkty: štítky kategorií a seznam.
                return buildMenu(allProducts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMenu(List<Product> allProducts) {
    final products = filterProducts(allProducts);

    return Column(
      children: [
        buildCategoryChips(categoriesOf(allProducts)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => openDetail(product),
                onAdd: () => addToCart(product),
              );
            },
          ),
        ),
      ],
    );
  }

  // Hnědá hlavička s přechodem barev a pozdravem.
  Widget buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.coffee, AppColors.caramel],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Šipka zpět na úvodní obrazovku.
              const BackButton(color: Colors.white),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting ☕',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Co si dnes dáte?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Vodorovná řada štítků s kategoriemi.
  Widget buildCategoryChips(List<String> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.coffee,
              backgroundColor: Colors.white,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.darkCoffee,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                setState(() {
                  selectedCategory = category;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
