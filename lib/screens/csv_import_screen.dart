import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../utils/csv_import.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';

// Ukázka souboru, která se zobrazí v návodu.
const csvExample = 'název;cena;kategorie;popis\n'
    'Flat white;72;Káva;Espresso s jemným mléčným krémem\n'
    'Brownies;65;Dezerty;Čokoládový řez s ořechy';

// Nejvíc produktů najednou (Firestore zvládne max. 500 zápisů v jednom batchi).
const maxImportProducts = 400;

// Nahrání menu ze souboru CSV: návod → výběr souboru → náhled → nahrání.
class CsvImportScreen extends StatefulWidget {
  final ProductService productService;

  const CsvImportScreen({super.key, required this.productService});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  String? fileName;
  CsvImportResult? result;
  bool isImporting = false;

  Future<void> pickFile() async {
    // Otevře okno pro výběr souboru (jen soubory .csv).
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file == null) return; // admin okno zavřel

    final text = decodeCsvBytes(await file.readAsBytes());
    if (!mounted) return;
    if (text == null) {
      showAppMessage(
        context,
        'Soubor nejde přečíst. V Excelu ho uložte jako „CSV UTF-8“.',
      );
      return;
    }

    setState(() {
      fileName = file.name;
      result = parseProductsCsv(text);
    });
  }

  Future<void> importProducts() async {
    final products = result!.products;
    setState(() => isImporting = true);
    try {
      final counts = await widget.productService.importProducts(products);
      if (!mounted) return;
      showAppMessage(
        context,
        'Hotovo: přidáno ${counts.added}, upraveno ${counts.updated}',
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => isImporting = false);
      showAppMessage(context, 'Produkty se nepodařilo nahrát');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nahrát menu z CSV')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildInstructions(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: Text(fileName == null ? 'Vybrat soubor CSV' : 'Vybrat jiný soubor'),
            onPressed: isImporting ? null : pickFile,
          ),
          if (result != null) ...[
            const SizedBox(height: 24),
            buildPreview(result!),
          ],
        ],
      ),
    );
  }

  // Návod: jak má soubor vypadat a jak ho uložit z Excelu.
  Widget buildInstructions() {
    final textStyle = TextStyle(height: 1.4, color: context.colors.dark);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: context.colors.primary),
                SizedBox(width: 8),
                Text(
                  'Jak má soubor vypadat',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: context.colors.dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Každý řádek = jeden produkt.\n'
              '• Sloupce v tomto pořadí: název, cena, kategorie, popis.\n'
              '• První řádek může být záhlaví (název;cena;kategorie;popis).\n'
              '• Cena je číslo v Kč, např. 72 nebo 72,50.\n'
              '• Popis není povinný.\n'
              '• Kategorie, která v menu ještě není, se sama vytvoří.\n'
              '• Produkt se stejným názvem, jaký už v menu je, se jen '
              'aktualizuje (cena, kategorie, popis).',
              style: textStyle,
            ),
            const SizedBox(height: 12),
            const Text('Příklad:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const SelectableText(
                csvExample,
                style: TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'V Excelu: v řádcích produkty, ve sloupcích A–D název, cena, '
              'kategorie a popis. Pak Soubor → Uložit jako → typ '
              '„CSV UTF-8 (s oddělovači)“.',
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }

  // Náhled: co se v souboru našlo, chyby a tlačítko Nahrát.
  Widget buildPreview(CsvImportResult result) {
    final products = result.products;
    final errorColor = Theme.of(context).colorScheme.error;
    final tooMany = products.length > maxImportProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fileName ?? '',
          style: TextStyle(color: context.colors.muted),
        ),
        const SizedBox(height: 4),
        Text(
          'V pořádku: ${products.length}'
          '${result.errors.isEmpty ? '' : ' • Chyby: ${result.errors.length}'}',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: context.colors.dark,
          ),
        ),

        // Chybné řádky se nenahrají – admin je může opravit a soubor vybrat znovu.
        if (result.errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Tyto řádky se nenahrají:',
            style: TextStyle(color: errorColor, fontWeight: FontWeight.w600),
          ),
          for (final error in result.errors)
            Text('• $error', style: TextStyle(color: errorColor)),
        ],
        if (tooMany)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Najednou jde nahrát nejvýš $maxImportProducts produktů. '
              'Rozdělte soubor na menší části.',
              style: TextStyle(color: errorColor),
            ),
          ),

        const SizedBox(height: 12),
        for (final product in products)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(product.name),
            subtitle: Text(product.category),
            trailing: Text(
              formatPrice(product.price),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.colors.primary,
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: products.isEmpty || tooMany || isImporting
                ? null
                : importProducts,
            child: Text(
              isImporting
                  ? 'Nahrávám…'
                  : 'Nahrát do menu (${products.length})',
            ),
          ),
        ),
      ],
    );
  }
}
