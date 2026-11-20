import 'dart:async';

import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/product_option.dart';
import '../models/venue_settings.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';
import '../widgets/product_sheet.dart';
import '../widgets/venue_info_sheet.dart';
import '../l10n/language.dart';
import '../widgets/language_button.dart';

class MenuScreen extends StatefulWidget {
  final Cart cart;
  final ProductService productService;

  // Zavolá se, když se změní obsah košíku (aby se aktualizovalo číslo v liště).
  final VoidCallback onCartChanged;

  // Zavolá se z plovoucí lišty košíku (přepne na záložku Košík).
  final VoidCallback onOpenCart;

  // Oblíbené produkty přihlášeného zákazníka (ID) a přepnutí srdíčka.
  final Set<String> favorites;
  final ValueChanged<Product>? onToggleFavorite;

  const MenuScreen({
    super.key,
    required this.cart,
    required this.productService,
    required this.onCartChanged,
    required this.onOpenCart,
    this.favorites = const {},
    this.onToggleFavorite,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const String allCategories = 'Vše';
  static const String favoriteCategory = 'Oblíbené';

  // Právě vybraná kategorie.
  String selectedCategory = allCategories;

  // Proud produktů z databáze. Vytvoří se jen jednou (v initState),
  // aby se aplikace nepřipojovala k databázi znovu při každém překreslení.
  late final Stream<List<Product>> productsStream;

  // Skupiny možností (mléko, sirup…) – načtené živě, aby se v detailu
  // produktu hned ukázaly změny od admina (např. nový sezónní sirup).
  StreamSubscription<List<OptionGroup>>? groupsSubscription;
  List<OptionGroup> optionGroups = [];

  @override
  void initState() {
    super.initState();
    productsStream = widget.productService.watchProducts();
    groupsSubscription = widget.productService.options.watchGroups().listen(
      (groups) {
        if (mounted) setState(() => optionGroups = groups);
      },
      // Bez možností jde produkty objednat i tak (s výchozími volbami).
      onError: (Object error) {},
    );
  }

  @override
  void dispose() {
    groupsSubscription?.cancel();
    super.dispose();
  }

  // Seznam kategorií: "Vše" + každá kategorie z menu jen jednou.
  // toSet() odstraní duplicity (Káva je v menu třikrát, ale štítek chceme jeden).
  // Když má zákazník oblíbené produkty, je hned za „Vše“ štítek Oblíbené.
  List<String> categoriesOf(List<Product> products) {
    final hasFavorites =
        products.any((product) => widget.favorites.contains(product.id));
    return [
      allCategories,
      if (hasFavorites) favoriteCategory,
      ...products.map((product) => product.category).toSet(),
    ];
  }

  // Produkty podle vybrané kategorie. Vyprodané jsou až na konci,
  // aby nepřekážely. Když se zase prodávají, vrátí se na své místo.
  List<Product> filterProducts(List<Product> products) {
    final filtered = selectedCategory == allCategories
        ? products
        : selectedCategory == favoriteCategory
            ? products
                .where((product) => widget.favorites.contains(product.id))
                .toList()
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
    if (hour < 10) return context.t.goodMorning;
    if (hour < 18) return context.t.goodDay;
    return context.t.goodEvening;
  }

  void addToCart(CartItem item) {
    widget.cart.addItem(item);
    // Hlášku „Přidáno“ už nepotřebujeme – zákazník změnu vidí
    // na plovoucí liště košíku dole.
    setState(() {});
    widget.onCartChanged();
  }

  // Otevře detail zespodu. Když zákazník vybere množství (a možnosti),
  // přidá položku do košíku.
  Future<void> openDetail(Product product) async {
    final item = await showProductSheet(
      context,
      product,
      allGroups: optionGroups,
    );
    if (item != null && mounted) addToCart(item);
  }

  // Tlačítko + u produktu: bez možností přidá rovnou jeden kus,
  // s možnostmi (mléko, sirup…) otevře detail, aby si zákazník vybral.
  void quickAdd(Product product) {
    if (groupsForProduct(product, optionGroups).isEmpty) {
      addToCart(CartItem(product: product));
    } else {
      openDetail(product);
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
                  return EmptyState(
                    icon: Icons.cloud_off,
                    title: context.t.menuLoadFailed,
                    message: context.t.checkConnection,
                  );
                }
                // 2) Data ještě nedorazila: točící se kolečko.
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                // 3) Databáze je prázdná.
                final allProducts = snapshot.data!;
                if (allProducts.isEmpty) {
                  return EmptyState(
                    icon: Icons.menu_book,
                    title: context.t.menuEmpty,
                    message: context.t.menuEmptyHint,
                  );
                }
                // 4) Máme produkty: štítky kategorií a seznam.
                return buildMenu(allProducts);
              },
            ),
          ),
          buildCartBar(),
        ],
      ),
    );
  }

  // Plovoucí lišta košíku: jakmile je v košíku něco, ukáže se dole
  // „🛍 2 položky · 135 Kč → Do košíku“. Zákazník tak nemusí hledat
  // záložku Košík – stačí jedno klepnutí.
  Widget buildCartBar() {
    final cart = widget.cart;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: cart.itemCount == 0
          ? const SizedBox(width: double.infinity)
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Material(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    onTap: widget.onOpenCart,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_bag, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            // Počet a cena se při změně plynule vymění.
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                '${context.t.itemCount(cart.itemCount)} · '
                                '${formatPrice(cart.totalPrice)}',
                                key: ValueKey(cart.itemCount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            context.t.toCart,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // Šipka zpět – jen když je kam se vrátit (při otevření z QR kódu
  // je menu první obrazovka, úvod se přeskočí).
  Widget buildBackButton() {
    if (!Navigator.of(context).canPop()) return const SizedBox(width: 8);
    return const BackButton(color: Colors.white);
  }

  Widget buildMenu(List<Product> menuProducts) {
    // Produkty už jsou seřazené podle pořadí kategorií (určuje admin).
    final allProducts = menuProducts;
    // Vybraná kategorie zmizela (např. zákazník odebral poslední oblíbený
    // produkt) → zpět na „Vše“.
    final categories = categoriesOf(allProducts);
    if (!categories.contains(selectedCategory)) {
      selectedCategory = allCategories;
    }
    final products = filterProducts(allProducts);

    final venue = VenueScope.of(context);

    return Column(
      children: [
        // Když má podnik zavřeno, zákazník to uvidí hned nahoře.
        if (!venue.isOpen)
          buildBanner(
            icon: Icons.door_front_door_outlined,
            text: context.t.closedBanner,
            color: Theme.of(context).colorScheme.error,
          ),
        // Oznámení od podniku (např. akce dne).
        if (venue.announcement.isNotEmpty)
          buildBanner(
            icon: Icons.campaign_outlined,
            text: venue.announcement,
            color: context.colors.accent,
          ),
        buildCategoryChips(categories),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => openDetail(product),
                onAdd: () => quickAdd(product),
                isFavorite: widget.favorites.contains(product.id),
                onFavorite: widget.onToggleFavorite == null
                    ? null
                    : () => widget.onToggleFavorite!(product),
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
      tooltip: context.t.venueInfo,
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
              buildBackButton(),
              const Spacer(),
              const LanguageButton(color: Colors.white),
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
                  // Zákazník od stolu (z QR kódu) hned vidí, že ho aplikace
                  // pozná: "Stůl 4 · Co si dnes dáte?"
                  widget.cart.hasTable
                      ? context.t.tableWhatWillYouHave(widget.cart.tableNumber!)
                      : context.t.whatWillYouHave,
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
          buildBackButton(),
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
          const LanguageButton(color: Colors.white),
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
              // Štítek Oblíbené má srdíčko.
              avatar: category == favoriteCategory
                  ? Icon(
                      Icons.favorite,
                      size: 16,
                      color: isSelected ? Colors.white : const Color(0xFFE0526B),
                    )
                  : null,
              // „Vše“ a „Oblíbené“ přeložíme, kategorie z menu zůstanou,
              // jak je napsal admin.
              label: Text(
                category == allCategories
                    ? context.t.categoryAll
                    : category == favoriteCategory
                        ? context.t.categoryFavorites
                        : category,
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: context.colors.primary,
              backgroundColor: context.colors.surface,
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
