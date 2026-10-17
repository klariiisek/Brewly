import 'package:flutter/material.dart';

import '../models/menu_category.dart';
import '../models/product.dart';
import '../services/app_services.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import '../widgets/category_name_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';

// Správa kategorií pro admina: pořadí (přetažením), přidání,
// přejmenování a smazání prázdné kategorie. Každá změna se hned uloží.
//
// Kategorie jsou samostatná kolekce "categories" (název + pořadí)
// a produkty na ně odkazují přes categoryId.
class CategoriesScreen extends StatefulWidget {
  final AppServices services;

  const CategoriesScreen({super.key, required this.services});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final Stream<List<MenuCategory>> categoriesStream;
  late final Stream<List<Product>> productsStream;

  // Poslední načtené kategorie a produkty (kvůli počtům produktů).
  List<MenuCategory> categories = [];
  List<Product> products = [];

  CategoryService get categoryService => widget.services.products.categories;

  @override
  void initState() {
    super.initState();
    categoriesStream = categoryService.watchCategories();
    productsStream = widget.services.products.watchProducts();
  }

  int productCount(MenuCategory category) =>
      products.where((product) => product.categoryId == category.id).length;

  List<String> get names =>
      categories.map((category) => category.name).toList();

  // Spustí změnu v databázi a ukáže hlášku (nebo chybu).
  Future<void> run(Future<void> Function() action, String message) async {
    try {
      await action();
      if (!mounted) return;
      showAppMessage(context, message);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Změnu se nepodařilo uložit');
    }
  }

  void move(int oldIndex, int newIndex) {
    final order = [...categories];
    final category = order.removeAt(oldIndex);
    order.insert(newIndex, category);
    // Hned překreslíme v novém pořadí, databáze se uloží na pozadí.
    setState(() => categories = order);
    run(() => categoryService.saveOrder(order), 'Pořadí uloženo');
  }

  Future<void> addCategory() async {
    final name = await askForCategoryName(
      context,
      title: 'Nová kategorie',
      buttonText: 'Přidat',
      existingNames: names,
    );
    if (name == null) return;
    await run(
      () => categoryService.addCategory(name, order: categories.length),
      'Kategorie $name přidána – teď do ní přidejte produkty',
    );
  }

  // Přejmenování změní jen jeden dokument kategorie. Produkty se nemění,
  // protože odkazují na ID kategorie – výhoda samostatné kolekce.
  Future<void> renameCategory(MenuCategory category) async {
    final name = await askForCategoryName(
      context,
      title: 'Přejmenovat kategorii',
      buttonText: 'Přejmenovat',
      existingNames: names,
      initialName: category.name,
    );
    if (name == null || name == category.name) return;
    await run(
      () => categoryService.renameCategory(category.id, name),
      'Přejmenováno na $name',
    );
  }

  Future<void> deleteCategory(MenuCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Smazat kategorii ${category.name}?'),
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
    await run(
      () => categoryService.deleteCategory(category.id),
      'Kategorie ${category.name} smazána',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategorie')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addCategory,
        icon: const Icon(Icons.add),
        label: const Text('Přidat kategorii'),
      ),
      // Dva proudy: produkty (kvůli počtům) a kategorie.
      body: StreamBuilder<List<Product>>(
        stream: productsStream,
        builder: (context, productSnapshot) {
          products = productSnapshot.data ?? products;
          return StreamBuilder<List<MenuCategory>>(
            stream: categoriesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const EmptyState(
                  icon: Icons.cloud_off,
                  title: 'Kategorie se nepodařilo načíst',
                  message: 'Zkontrolujte připojení k internetu.',
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              categories = snapshot.data!;
              if (categories.isEmpty) {
                return const EmptyState(
                  icon: Icons.category_outlined,
                  title: 'Zatím žádné kategorie',
                  message: 'Přidejte první kategorii tlačítkem dole.',
                );
              }
              return buildList();
            },
          );
        },
      ),
    );
  }

  Widget buildList() {
    return ListView(
      // Dole místo navíc, aby poslední kategorii nezakrývalo tlačítko.
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'V tomto pořadí uvidí zákazníci kategorie v menu. '
            'Přetáhněte kategorii za úchyt vpravo. Prázdné kategorie '
            'zákazníci nevidí.',
            style: TextStyle(color: context.colors.muted),
          ),
        ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: move,
          children: [
            for (var i = 0; i < categories.length; i++)
              buildCategoryTile(categories[i], i),
          ],
        ),
      ],
    );
  }

  Widget buildCategoryTile(MenuCategory category, int index) {
    final count = productCount(category);

    return Card(
      key: ValueKey(category.id),
      child: ListTile(
        leading:
            Icon(categoryIcon(category.name), color: context.colors.primary),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.colors.dark,
          ),
        ),
        subtitle: Text(formatProductCount(count)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Přejmenovat',
              onPressed: () => renameCategory(category),
            ),
            // Smazat jde jen prázdnou kategorii, aby nezůstaly produkty
            // bez kategorie.
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: count == 0
                  ? 'Smazat'
                  : 'Smazat jde jen prázdnou kategorii',
              onPressed: count == 0 ? () => deleteCategory(category) : null,
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
