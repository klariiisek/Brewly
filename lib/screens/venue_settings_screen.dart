import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/menu_category.dart';
import '../models/reservation.dart';
import '../models/venue_settings.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../config/palettes.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import 'categories_screen.dart';

// Nastavení podniku pro admina: název, slogan, typ a barva.
// Nahoře je živý náhled – změny se projeví v aplikaci až po uložení.
class VenueSettingsScreen extends StatefulWidget {
  final AppServices services;

  const VenueSettingsScreen({super.key, required this.services});

  @override
  State<VenueSettingsScreen> createState() => _VenueSettingsScreenState();
}

class _VenueSettingsScreenState extends State<VenueSettingsScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final sloganController = TextEditingController();
  final announcementController = TextEditingController();
  final addressController = TextEditingController();
  final hoursController = TextEditingController();
  final wifiNameController = TextEditingController();
  final wifiPasswordController = TextEditingController();
  late String colorKey;
  late VenueType type;

  // Razítková karta.
  late bool loyaltyEnabled;
  late String loyaltyCategoryId;
  late int loyaltyGoal;
  late final Stream<List<MenuCategory>> categoriesStream;

  // Časy rezervací po dnech (0 = pondělí; null = ten den rezervace nejdou).
  late List<DayHours?> reservationHours;

  @override
  void initState() {
    super.initState();
    categoriesStream = widget.services.products.categories.watchCategories();
  }

  bool isLoaded = false;
  bool isSaving = false;

  // Současné nastavení načteme jen jednou, když je obrazovka poprvé
  // vložená do aplikace (v initState ještě VenueScope.of nejde použít).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isLoaded) return;
    isLoaded = true;
    final settings = VenueScope.of(context);
    nameController.text = settings.name;
    sloganController.text = settings.slogan;
    announcementController.text = settings.announcement;
    addressController.text = settings.address;
    hoursController.text = settings.openingHours;
    wifiNameController.text = settings.wifiName;
    wifiPasswordController.text = settings.wifiPassword;
    colorKey = settings.colorKey;
    type = settings.type;
    loyaltyEnabled = settings.loyaltyEnabled;
    loyaltyCategoryId = settings.loyaltyCategoryId;
    loyaltyGoal = settings.loyaltyGoal;
    reservationHours = List.of(settings.reservationHours);
  }

  @override
  void dispose() {
    nameController.dispose();
    sloganController.dispose();
    announcementController.dispose();
    addressController.dispose();
    hoursController.dispose();
    wifiNameController.dispose();
    wifiPasswordController.dispose();
    super.dispose();
  }

  // Nastavení tak, jak je právě vyplněné na obrazovce. Vezmeme současné
  // nastavení a změníme jen to, co je na této obrazovce (otevřeno/zavřeno
  // zůstane, jak je).
  VenueSettings editedSettings() {
    return VenueScope.of(context).copyWith(
      name: nameController.text.trim(),
      slogan: sloganController.text.trim(),
      colorKey: colorKey,
      type: type,
      announcement: announcementController.text.trim(),
      address: addressController.text.trim(),
      openingHours: hoursController.text.trim(),
      wifiName: wifiNameController.text.trim(),
      wifiPassword: wifiPasswordController.text.trim(),
      loyaltyEnabled: loyaltyEnabled,
      loyaltyCategoryId: loyaltyCategoryId,
      loyaltyGoal: loyaltyGoal,
      reservationHours: reservationHours,
    );
  }

  // Liší se vyplněné nastavení od uloženého? (Porovnáme je jako text.)
  bool get hasChanges =>
      jsonEncode(editedSettings().toMap()) !=
      jsonEncode(VenueScope.of(context).toMap());

  // Uloží nastavení. Vrátí true, když se to povedlo.
  Future<bool> save() async {
    if (!formKey.currentState!.validate()) return false;
    if (loyaltyEnabled && loyaltyCategoryId.isEmpty) {
      showAppMessage(context, 'Vyberte kategorii pro razítkovou kartu');
      return false;
    }

    final settings = editedSettings();
    setState(() => isSaving = true);
    try {
      await widget.services.settings.saveSettings(settings);
      if (!mounted) return false;
      showAppMessage(context, 'Nastavení uloženo');
      return true;
    } catch (error) {
      if (!mounted) return false;
      showAppMessage(context, 'Nastavení se nepodařilo uložit');
      return false;
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // Odchod z obrazovky (šipka zpět, gesto, tlačítko prohlížeče).
  // S neuloženými změnami se nejdřív zeptáme – jinak by se tiše zahodily.
  Future<void> leave() async {
    if (!hasChanges) {
      Navigator.pop(context);
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Máte neuložené změny'),
        content: const Text('Chcete změny v nastavení podniku uložit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'zustat'),
            child: const Text('Zůstat'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'zahodit'),
            child: const Text('Zahodit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'ulozit'),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'zahodit' || (choice == 'ulozit' && await save())) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope zachytí odchod z obrazovky, aby šlo upozornit na
    // neuložené změny (o odchodu rozhoduje leave()).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Nastavení podniku')),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildPreview(),
              const SizedBox(height: 24),
              buildSectionTitle('Název a slogan'),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Název podniku'),
                maxLength: AppConfig.maxVenueNameLength,
                textCapitalization: TextCapitalization.sentences,
                // Při psaní se hned překreslí náhled.
                onChanged: (_) => setState(() {}),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Zadejte název podniku'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: sloganController,
                decoration: const InputDecoration(
                  labelText: 'Slogan',
                  hintText: 'Např. Vítejte v naší kavárně',
                ),
                maxLength: AppConfig.maxSloganLength,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              buildSectionTitle('Typ podniku'),
              buildTypePicker(),
              const SizedBox(height: 24),
              buildSectionTitle('Barva aplikace'),
              buildPalettePicker(),
              const SizedBox(height: 24),
              buildSectionTitle('Oznámení v menu'),
              TextFormField(
                controller: announcementController,
                decoration: const InputDecoration(
                  labelText: 'Oznámení (nepovinné)',
                  hintText: 'Např. Dnes −20 % na všechny dezerty',
                  prefixIcon: Icon(Icons.campaign_outlined),
                ),
                maxLength: AppConfig.maxAnnouncementLength,
                textCapitalization: TextCapitalization.sentences,
              ),
              Text(
                'Zobrazí se zákazníkům nahoře v menu. '
                'Když pole vymažete, oznámení zmizí.',
                style: TextStyle(color: context.colors.muted),
              ),
              const SizedBox(height: 24),
              buildSectionTitle('Informace pro zákazníky'),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresa',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                maxLength: AppConfig.maxAddressLength,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: hoursController,
                decoration: const InputDecoration(
                  labelText: 'Otevírací doba',
                  hintText: 'Po–Pá 8:00–20:00\nSo–Ne 9:00–18:00',
                  prefixIcon: Icon(Icons.schedule),
                ),
                minLines: 2,
                maxLines: 5,
                maxLength: AppConfig.maxOpeningHoursLength,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: wifiNameController,
                decoration: const InputDecoration(
                  labelText: 'Název Wi-Fi',
                  prefixIcon: Icon(Icons.wifi),
                ),
                maxLength: AppConfig.maxWifiLength,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: wifiPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Heslo k Wi-Fi',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
                maxLength: AppConfig.maxWifiLength,
              ),
              const SizedBox(height: 24),
              buildSectionTitle('Časy rezervací'),
              buildReservationHours(),
              const SizedBox(height: 24),
              buildSectionTitle('Razítková karta'),
              buildLoyaltySettings(),
              const SizedBox(height: 24),
              // Kategorie mají vlastní obrazovku (změny se tam ukládají hned).
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    Icons.category_outlined,
                    color: context.colors.primary,
                  ),
                  title: const Text('Kategorie a jejich pořadí'),
                  subtitle: const Text('Přidat, přejmenovat, seřadit'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CategoriesScreen(services: widget.services),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSaving ? null : save,
                child: Text(isSaving ? 'Ukládám…' : 'Uložit nastavení'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: context.colors.dark,
        ),
      ),
    );
  }

  // Náhled úvodu v právě vybrané barvě. Theme(...) = uvnitř náhledu platí
  // jiné téma než ve zbytku obrazovky.
  Widget buildPreview() {
    final colors = paletteFor(colorKey).colors;
    final name = nameController.text.trim();
    final slogan = sloganController.text.trim();

    return Theme(
      data: AppTheme.build(colors),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: colors.muted.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              'NÁHLED',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                color: colors.muted,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(type.icon, size: 34, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              name.isEmpty ? 'Název podniku' : name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colors.dark,
              ),
            ),
            if (slogan.isNotEmpty)
              Text(
                slogan,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted),
              ),
            const SizedBox(height: 16),
            // Ukázka hlavičky menu s přechodem barev.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.accent],
                ),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Text(
                'Dobrý den ${type.emoji}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Prohlédnout menu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTypePicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final venueType in VenueType.values)
          ChoiceChip(
            avatar: Icon(venueType.icon, size: 18),
            label: Text(venueType.label),
            selected: venueType == type,
            showCheckmark: false,
            onSelected: (_) => setState(() => type = venueType),
          ),
      ],
    );
  }

  // Kolečka s barvami palet. Vybraná má fajfku.
  Widget buildPalettePicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final palette in palettes)
          Tooltip(
            message: palette.label,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => setState(() => colorKey = palette.key),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [palette.colors.primary, palette.colors.accent],
                      ),
                      border: Border.all(
                        color: palette.key == colorKey
                            ? context.colors.dark
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: palette.key == colorKey
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 76,
                    child: Text(
                      palette.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Razítková karta: zapnout, vybrat kategorii a počet razítek.
  Widget buildLoyaltySettings() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Zapnout razítkovou kartu'),
              subtitle: Text(
                'Za každý kus z vybrané kategorie dostane zákazník razítko. '
                'Když kartu nasbírá, další kus má zdarma.',
                style: TextStyle(color: context.colors.muted),
              ),
              value: loyaltyEnabled,
              onChanged: (value) => setState(() => loyaltyEnabled = value),
            ),
            if (loyaltyEnabled) ...[
              const SizedBox(height: 8),
              Text('Razítka za kategorii',
                  style: TextStyle(color: context.colors.muted)),
              const SizedBox(height: 8),
              StreamBuilder<List<MenuCategory>>(
                stream: categoriesStream,
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? [];
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in categories)
                        ChoiceChip(
                          label: Text(category.name),
                          selected: category.id == loyaltyCategoryId,
                          onSelected: (_) => setState(
                            () => loyaltyCategoryId = category.id,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Kolikátý kus je zdarma',
                  style: TextStyle(color: context.colors.muted)),
              const SizedBox(height: 8),
              // Velké − a + kolem čísla (povoleno 3 až 20 razítek).
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    tooltip: 'Méně',
                    onPressed: loyaltyGoal > AppConfig.minLoyaltyGoal
                        ? () => setState(() => loyaltyGoal--)
                        : null,
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '$loyaltyGoal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: context.colors.dark,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    tooltip: 'Více',
                    onPressed: loyaltyGoal < AppConfig.maxLoyaltyGoal
                        ? () => setState(() => loyaltyGoal++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Každý $loyaltyGoal. kus zdarma – zákazník nasbírá '
                '${formatStampCount(loyaltyGoal - 1)} '
                '(můžete nastavit ${AppConfig.minLoyaltyGoal}. až '
                '${AppConfig.maxLoyaltyGoal}. kus). '
                'Nezapomeňte nastavení uložit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.muted, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Časy rezervací pro každý den v týdnu: přepínač (jde ten den
  // rezervovat?) a první a poslední čas. Zákazníkům se pak nabídnou jen
  // časy v tomto rozmezí – každý podnik má jinou otevírací dobu.
  Widget buildReservationHours() {
    const dayNames = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
    final colors = context.colors;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'První a poslední čas, na který si zákazník může stůl '
              'zarezervovat. Vypnutý den = ten den rezervace nejdou.',
              style: TextStyle(color: colors.muted),
            ),
            const SizedBox(height: 8),
            for (var day = 0; day < 7; day++)
              Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      dayNames[day],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.dark,
                      ),
                    ),
                  ),
                  Switch(
                    value: reservationHours[day] != null,
                    onChanged: (isOn) => setState(() {
                      reservationHours[day] = isOn
                          ? VenueSettings.defaultReservationHours[day]
                          : null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: buildDayHours(day)),
                ],
              ),
            const SizedBox(height: 4),
            TextButton.icon(
              icon: const Icon(Icons.copy_all_outlined, size: 18),
              label: const Text('Všem dnům nastavit časy jako v pondělí'),
              onPressed: () => setState(() {
                reservationHours = List.filled(7, reservationHours[0]);
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Výběr „od – do“ pro jeden den (nebo text, že ten den rezervace nejdou).
  Widget buildDayHours(int day) {
    final hours = reservationHours[day];
    if (hours == null) {
      return Text(
        'bez rezervací',
        style: TextStyle(color: context.colors.muted),
      );
    }
    // Celý den po půl hodinách: 00:00, 00:30 … 23:30.
    final times = [for (var minute = 0; minute < 24 * 60; minute += 30) minute];
    DropdownButton<int> picker(int value, ValueChanged<int> onChanged) {
      return DropdownButton<int>(
        value: value,
        isDense: true,
        underline: const SizedBox.shrink(),
        menuMaxHeight: 320,
        items: [
          for (final minute in times)
            DropdownMenuItem(value: minute, child: Text(minutesText(minute))),
        ],
        onChanged: (minute) {
          if (minute != null) setState(() => onChanged(minute));
        },
      );
    }

    // Když by začátek byl po konci, posune se i druhý čas.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        picker(
          hours.from,
          (from) => reservationHours[day] =
              DayHours(from, from > hours.to ? from : hours.to),
        ),
        const Text('–'),
        picker(
          hours.to,
          (to) => reservationHours[day] =
              DayHours(to < hours.from ? to : hours.from, to),
        ),
      ],
    );
  }
}
