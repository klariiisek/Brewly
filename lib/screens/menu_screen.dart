import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  final Cart cart;

  // Zavolá se, když se změní obsah košíku (aby se aktualizovalo číslo v liště).
  final VoidCallback onCartChanged;

  const MenuScreen({
    super.key,
    required this.cart,
    required this.onCartChanged,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const String allCategories = 'Vše';

  // Právě vybraná kategorie.
  String selectedCategory = allCategories;

  // Seznam kategorií: "Vše" + každá kategorie z menu jen jednou.
  // toSet() odstraní duplicity (Káva je v menu třikrát, ale štítek chceme jeden).
  List<String> get categories {
    return [
      allCategories,
      ...menuProducts.map((product) => product.category).toSet(),
    ];
  }

  // Produkty podle vybrané kategorie.
  List<Product> get visibleProducts {
    if (selectedCategory == allCategories) {
      return menuProducts;
    }
    return menuProducts
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

  void addToCart(Product product) {
    widget.cart.addItem(CartItem(product: product));
    widget.onCartChanged();
    showAppMessage(context, 'Přidáno: ${product.name}');
  }

  Future<void> openDetail(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailScreen(product: product, cart: widget.cart),
      ),
    );
    // V detailu se mohl produkt přidat do košíku.
    widget.onCartChanged();
  }

  @override
  Widget build(BuildContext context) {
    final products = visibleProducts;

    return Scaffold(
      body: Column(
        children: [
          buildHeader(),
          buildCategoryChips(),
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
      ),
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
  Widget buildCategoryChips() {
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
