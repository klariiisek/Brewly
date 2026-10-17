import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/venue_settings.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';
import '../widgets/product_sheet.dart';
import '../widgets/venue_info_sheet.dart';

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

  // Produkty podle vybrané kategorie. Vyprodané jsou až na konci,
  // aby nepřekážely. Když se zase prodávají, vrátí se na své místo.
  List<Product> filterProducts(List<Product> products) {
    final filtered = selectedCategory == allCategories
        ? products
        : products
            .where((product) => product.category == selectedCategory)
            .toList();

    // Nejdřív dostupné, pak vyprodané – v obou skupinách zůstane
    // původní pořadí (podle kategorie a názvu).
    return [
      ...filtered.where((product) => product.isAvailable),
      ...filtered.where((product) => !product.isAvailable),
    ];
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

  Widget buildMenu(List<Product> menuProducts) {
    // Produkty už jsou seřazené podle pořadí kategorií (určuje admin).
    final allProducts = menuProducts;
    final products = filterProducts(allProducts);

    final venue = VenueScope.of(context);

    return Column(
      children: [
        // Když má podnik zavřeno, zákazník to uvidí hned nahoře.
        if (!venue.isOpen)
          buildBanner(
            icon: Icons.door_front_door_outlined,
            text: 'Teď máme zavřeno. Menu si můžete prohlédnout, '
                'objednat ale zatím nejde.',
            color: Theme.of(context).colorScheme.error,
          ),
        // Oznámení od podniku (např. akce dne).
        if (venue.announcement.isNotEmpty)
          buildBanner(
            icon: Icons.campaign_outlined,
            text: venue.announcement,
            color: context.colors.accent,
          ),
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

  // Barevný pruh s ikonou a textem (zavřeno, oznámení).
  Widget buildBanner({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.colors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tlačítko ⓘ v hlavičce: informace o podniku (adresa, Wi-Fi...).
  Widget buildInfoButton() {
    return IconButton(
      icon: const Icon(Icons.info_outline, color: Colors.white),
      tooltip: 'Informace o podniku',
      onPressed: () => showVenueInfo(context),
    );
  }

  // Hlavička s přechodem barev a pozdravem.
  // Jakmile má zákazník něco v košíku, hlavička se zmenší na úzký pruh,
  // aby zbylo víc místa pro menu.
  Widget buildHeader() {
    final isCompact = widget.cart.itemCount > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.primary, context.colors.accent],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        // AnimatedSize plynule změní výšku hlavičky, aby neposkočila.
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: isCompact ? buildCompactHeader() : buildFullHeader(),
        ),
      ),
    );
  }

  // Velká hlavička: šipka zpět, pozdrav a otázka.
  Widget buildFullHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Šipka zpět na úvodní obrazovku a vpravo informace o podniku.
          Row(
            children: [
              const BackButton(color: Colors.white),
              const Spacer(),
              buildInfoButton(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting ${VenueScope.of(context).type.emoji}',
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
    );
  }

  // Úzká hlavička: šipka zpět a nadpis vedle sebe v jednom řádku.
  Widget buildCompactHeader() {
    // Emoji podle typu podniku (☕ kavárna, 🍸 bar...).
    final emoji = VenueScope.of(context).type.emoji;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          const BackButton(color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Menu $emoji',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          buildInfoButton(),
        ],
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
              selectedColor: context.colors.primary,
              backgroundColor: Colors.white,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : context.colors.dark,
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
