import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/cart.dart';
import '../services/table_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';

// Obrazovka pro obsluhu: QR kódy všech stolů k vytištění.
// Každý QR kód obsahuje odkaz s číslem stolu a jeho tajným kódem.
class StaffTablesScreen extends StatefulWidget {
  final TableService tableService;

  const StaffTablesScreen({super.key, required this.tableService});

  @override
  State<StaffTablesScreen> createState() => _StaffTablesScreenState();
}

class _StaffTablesScreenState extends State<StaffTablesScreen> {
  late final Stream<Map<int, String>> codesStream;
  bool isGenerating = false;

  @override
  void initState() {
    super.initState();
    codesStream = widget.tableService.watchCodes();
  }

  Future<void> generateCodes({required bool hasCodes}) async {
    // Když už kódy existují, zeptáme se – staré QR kódy přestanou platit.
    if (hasCodes) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Vygenerovat nové kódy?'),
          content: const Text(
            'Staré QR kódy na stolech přestanou platit '
            'a bude potřeba vytisknout nové.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vygenerovat'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => isGenerating = true);
    try {
      await widget.tableService.regenerateCodes();
      if (!mounted) return;
      showAppMessage(context, 'Nové kódy stolů jsou připravené');
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Kódy se nepodařilo vygenerovat');
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<int, String>>(
      stream: codesStream,
      builder: (context, snapshot) {
        final codes = snapshot.data ?? {};
        final hasCodes = codes.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Stoly a QR kódy'),
            actions: [
              if (hasCodes)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Vygenerovat nové kódy',
                  onPressed: isGenerating
                      ? null
                      : () => generateCodes(hasCodes: true),
                ),
            ],
          ),
          body: buildBody(snapshot, codes),
        );
      },
    );
  }

  Widget buildBody(
    AsyncSnapshot<Map<int, String>> snapshot,
    Map<int, String> codes,
  ) {
    if (snapshot.hasError) {
      return const EmptyState(
        icon: Icons.cloud_off,
        title: 'Kódy stolů se nepodařilo načíst',
        message: 'Zkontrolujte připojení k internetu.',
      );
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (codes.isEmpty) {
      return EmptyState(
        icon: Icons.qr_code_2,
        title: 'Stoly zatím nemají kódy',
        message: 'Vygenerujte kódy a vytiskněte QR kódy na stoly.',
        buttonText: isGenerating ? 'Generuji…' : 'Vygenerovat kódy',
        onPressed: isGenerating ? null : () => generateCodes(hasCodes: false),
      );
    }

    // Mřížka karet: kolik se jich vejde vedle sebe, záleží na šířce obrazovky.
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: Cart.tableCount,
      itemBuilder: (context, index) {
        final number = index + 1;
        return buildTableCard(number, codes[number]);
      },
    );
  }

  Widget buildTableCard(int number, String? code) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              'Stůl $number',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCoffee,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: code == null
                  ? const Center(child: Text('Bez kódu'))
                  // QR kód s odkazem na aplikaci s číslem a kódem stolu.
                  : QrImageView(
                      data: tableLink(number, code),
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.darkCoffee,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.darkCoffee,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            // Krátký kód pro ruční opsání.
            if (code != null)
              SelectableText(
                shortTableCode(number, code),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: AppColors.coffee,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
