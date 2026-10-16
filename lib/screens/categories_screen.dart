import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/venue_settings.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/text.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_card.dart';

// Správa kategorií pro admina: pořadí (přetažením), přidání,
// přejmenování a smazání prázdné kategorie. Každá změna se hned uloží.
//
// Kategorie je údaj u produktu ("Káva"). Pořadí kategorií – a kategorie
// založené dopředu, zatím bez produktů – jsou v nastavení podniku.
class CategoriesScreen extends StatefulWidget {
  final AppServices services;

  const CategoriesScreen({super.key, required this.services});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final Stream<List<Product>> productsStream;

  // Poslední načtené produkty (kvůli počtům a přejmenování).
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    productsStream = widget.services.products.watchProducts();
  }

  VenueSettings get settings => VenueScope.of(context);

  // Kategorie v aktuálním pořadí.
  List<String> get categories => settings.allCategories(products);

  int productCount(String category) =>
      products.where((product) => product.category == category).length;

  // Uloží nové pořadí kategorií do nastavení podniku.
  Future<void> saveOrder(List<String> order, String message) async {
    try {
      await widget.services.settings.saveCategoryOrder(settings, order);
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
    saveOrder(order, 'Pořadí uloženo');
  }

  // Okno s textovým polem pro název kategorie. Vrátí název, nebo null.
  // Hlídá, aby název nebyl prázdný a aby taková kategorie ještě nebyla.
  Future<String?> askForName({
    required String title,
    required String buttonText,
    String initialName = '',
  }) {
    final controller = TextEditingController(text: initialName);
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) {
        void submit() {
          if (formKey.currentState!.validate()) {
            Navigator.pop(context, controller.text.trim());
          }
        }

        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Název kategorie'),
              onFieldSubmitted: (_) => submit(),
              validator: (value) {
                final name = (value ?? '').trim();
                if (name.isEmpty) return 'Zadejte název';
                final isTaken = categories.any((category) =>
                    normalizeText(category) == normalizeText(name) &&
                    normalizeText(category) != normalizeText(initialName));
                if (isTaken) return 'Taková kategorie už je';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(onPressed: submit, child: Text(buttonText)),
          ],
        );
      },
    );
  }

  Future<void> addCategory() async {
    final name = await askForName(
      title: 'Nová kategorie',
      buttonText: 'Přidat',
    );
    if (name == null) return;
    await saveOrder(
      [...categories, name],
      'Kategorie $name přidána – teď do ní přidejte produkty',
    );
  }

  Future<void> renameCategory(String oldName) async {
    final newName = await askForName(
      title: 'Přejmenovat kategorii',
      buttonText: 'Přejmenovat',
      initialName: oldName,
    );
    if (newName == null || newName == oldName) return;

    // Nové pořadí: na stejném místě bude nový název.
    final order = [
      for (final category in categories)
        category == oldName ? newName : category,
    ];
    try {
      // Nejdřív produkty, pak pořadí v nastavení.
      await widget.services.products.renameCategory(oldName, newName);
      await widget.services.settings.saveCategoryOrder(settings, order);
      if (!mounted) return;
      showAppMessage(context, 'Přejmenováno na $newName');
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Kategorii se nepodařilo přejmenovat');
    }
  }

  Future<void> deleteCategory(String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Smazat kategorii $category?'),
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
    await saveOrder(
      categories.where((name) => name != category).toList(),
      'Kategorie $category smazána',
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
      body: StreamBuilder<List<Product>>(
        stream: productsStream,
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
          products = snapshot.data!;
          final list = categories;
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              title: 'Zatím žádné kategorie',
              message: 'Přidejte první kategorii tlačítkem dole.',
            );
          }
          return buildList(list);
        },
      ),
    );
  }

  Widget buildList(List<String> list) {
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
            for (var i = 0; i < list.length; i++)
              buildCategoryTile(list[i], i),
          ],
        ),
      ],
    );
  }

  Widget buildCategoryTile(String category, int index) {
    final count = productCount(category);

    return Card(
      key: ValueKey(category),
      child: ListTile(
        leading: Icon(categoryIcon(category), color: context.colors.primary),
        title: Text(
          category,
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
