import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/product_option.dart';
import '../services/option_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';

// Správa skupin možností pro admina: např. „Mléko“ (kravské, ovesné
// +15 Kč…) nebo sezónní „Sirup“ (vanilka, pumpkin spice…).
// Které skupiny se nabízejí u kterého produktu, se zapíná ve formuláři
// produktu.
class OptionGroupsScreen extends StatefulWidget {
  final OptionService optionService;

  const OptionGroupsScreen({super.key, required this.optionService});

  @override
  State<OptionGroupsScreen> createState() => _OptionGroupsScreenState();
}

class _OptionGroupsScreenState extends State<OptionGroupsScreen> {
  late final Stream<List<OptionGroup>> groupsStream;

  @override
  void initState() {
    super.initState();
    groupsStream = widget.optionService.watchGroups();
  }

  void openForm([OptionGroup? group]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OptionGroupFormScreen(
          optionService: widget.optionService,
          group: group,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Možnosti produktů')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Přidat skupinu'),
      ),
      body: StreamBuilder<List<OptionGroup>>(
        stream: groupsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.cloud_off,
              title: 'Možnosti se nepodařilo načíst',
              message: 'Zkontrolujte připojení k internetu.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return const EmptyState(
              icon: Icons.tune,
              title: 'Zatím žádné možnosti',
              message: 'Přidejte třeba skupinu „Mléko“ s volbami kravské, '
                  'ovesné a sójové. U produktu ji pak zapnete ve formuláři.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              for (final group in groups)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.tune, color: context.colors.primary),
                    title: Text(
                      group.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(choicesText(group)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openForm(group),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Volby skupiny v jednom řádku: „Kravské · Ovesné +15 Kč · Sójové +15 Kč“.
String choicesText(OptionGroup group) {
  return group.choices
      .map((choice) => choice.price > 0
          ? '${choice.name} +${formatPrice(choice.price)}'
          : choice.name)
      .join(' · ');
}

// Formulář jedné skupiny: název a volby s příplatky.
// První volba je výchozí – tu dostane zákazník, když nic nezmění.
class OptionGroupFormScreen extends StatefulWidget {
  final OptionService optionService;
  final OptionGroup? group; // null = nová skupina

  const OptionGroupFormScreen({
    super.key,
    required this.optionService,
    this.group,
  });

  @override
  State<OptionGroupFormScreen> createState() => _OptionGroupFormScreenState();
}

// Jeden řádek volby ve formuláři (název a příplatek).
class _ChoiceRow {
  final TextEditingController name;
  final TextEditingController price;

  _ChoiceRow(String name, String price)
      : name = TextEditingController(text: name),
        price = TextEditingController(text: price);

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _OptionGroupFormScreenState extends State<OptionGroupFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final List<_ChoiceRow> rows;
  bool isSaving = false;

  bool get isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    nameController = TextEditingController(text: group?.name ?? '');
    rows = group == null
        // Nová skupina: dva prázdné řádky (výchozí volba + jedna další).
        ? [_ChoiceRow('', '0'), _ChoiceRow('', '')]
        : [
            for (final choice in group.choices)
              _ChoiceRow(choice.name, priceText(choice.price)),
          ];
  }

  @override
  void dispose() {
    nameController.dispose();
    for (final row in rows) {
      row.dispose();
    }
    super.dispose();
  }

  // 15.0 → "15", 7.5 → "7,5".
  static String priceText(double price) {
    if (price == price.roundToDouble()) return price.toInt().toString();
    return price.toString().replaceAll('.', ',');
  }

  // Prázdný příplatek = zdarma.
  static double? parsePrice(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  String? validatePrice(String? value) {
    final price = parsePrice(value ?? '');
    if (price == null) return 'Číslo';
    if (price < 0 || price > AppConfig.maxOptionPrice) return 'Nesmysl';
    return null;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    final group = OptionGroup(
      id: widget.group?.id ?? '',
      name: nameController.text.trim(),
      choices: [
        for (final row in rows)
          OptionChoice(
            name: row.name.text.trim(),
            price: parsePrice(row.price.text) ?? 0,
          ),
      ],
    );
    setState(() => isSaving = true);
    try {
      await widget.optionService.saveGroup(group);
      if (!mounted) return;
      showAppMessage(context, 'Uloženo: ${group.name}');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => isSaving = false);
      showAppMessage(context, 'Skupinu se nepodařilo uložit');
    }
  }

  Future<void> delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Smazat „${widget.group!.name}“?'),
        content: const Text(
          'Produkty tuto možnost přestanou nabízet. '
          'Starých objednávek se to nedotkne.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zpět'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.optionService.deleteGroup(widget.group!.id);
      if (!mounted) return;
      showAppMessage(context, 'Skupina smazána');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Skupinu se nepodařilo smazat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Upravit možnosti' : 'Nové možnosti'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Smazat skupinu',
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
              decoration: const InputDecoration(
                labelText: 'Název skupiny',
                hintText: 'Např. Mléko, Sirup, Velikost',
              ),
              maxLength: AppConfig.maxOptionNameLength,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Zadejte název skupiny'
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Volby',
              style: TextStyle(fontWeight: FontWeight.bold, color: colors.dark),
            ),
            const SizedBox(height: 4),
            Text(
              'První volba je výchozí – tu dostane zákazník, když nic '
              'nezmění (např. kravské mléko, bez sirupu). Příplatek 0 = zdarma.',
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++) buildChoiceRow(i),
            if (rows.length < AppConfig.maxOptionChoices)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Přidat volbu'),
                  onPressed: () => setState(() => rows.add(_ChoiceRow('', ''))),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSaving ? null : save,
              child: Text(isSaving ? 'Ukládám…' : 'Uložit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildChoiceRow(int index) {
    final row = rows[index];
    return Padding(
      // ObjectKey: když se řádek smaže, ostatní si nechají svůj text.
      key: ObjectKey(row),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: row.name,
              decoration: InputDecoration(
                labelText: index == 0 ? 'Výchozí volba' : 'Volba ${index + 1}',
                hintText: index == 0 ? 'Např. Kravské' : 'Např. Ovesné',
              ),
              maxLength: AppConfig.maxOptionNameLength,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Zadejte název' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row.price,
              decoration: const InputDecoration(
                labelText: 'Příplatek',
                suffixText: 'Kč',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: validatePrice,
            ),
          ),
          // Aspoň jedna volba musí zůstat.
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Odebrat volbu',
            onPressed: rows.length > 1
                ? () {
                    setState(() => rows.removeAt(index));
                    // Uvolnit až po překreslení (pole ho do té doby používá).
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => row.dispose());
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
