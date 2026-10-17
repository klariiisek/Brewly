import 'package:flutter/material.dart';

import '../models/venue_settings.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../theme/palettes.dart';
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

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    // Vezmeme současné nastavení a změníme jen to, co je na této obrazovce
    // (pořadí kategorií a otevřeno/zavřeno zůstanou, jak jsou).
    final settings = VenueScope.of(context).copyWith(
      name: nameController.text.trim(),
      slogan: sloganController.text.trim(),
      colorKey: colorKey,
      type: type,
      announcement: announcementController.text.trim(),
      address: addressController.text.trim(),
      openingHours: hoursController.text.trim(),
      wifiName: wifiNameController.text.trim(),
      wifiPassword: wifiPasswordController.text.trim(),
    );

    setState(() => isSaving = true);
    try {
      await widget.services.settings.saveSettings(settings);
      if (!mounted) return;
      showAppMessage(context, 'Nastavení uloženo');
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Nastavení se nepodařilo uložit');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              maxLength: 40,
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
              maxLength: 80,
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
              maxLength: 120,
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
              maxLength: 100,
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
              maxLength: 300,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: wifiNameController,
              decoration: const InputDecoration(
                labelText: 'Název Wi-Fi',
                prefixIcon: Icon(Icons.wifi),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: wifiPasswordController,
              decoration: const InputDecoration(
                labelText: 'Heslo k Wi-Fi',
                prefixIcon: Icon(Icons.key_outlined),
              ),
              maxLength: 50,
            ),
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
}
