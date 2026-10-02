import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../services/table_service.dart';
import '../theme/app_theme.dart';

// Zeptá se zákazníka na kód stolu (okno zespodu). Když ho zadá správně,
// uloží stůl do košíku a vrátí true.
// Normálně se stůl nastaví sám po naskenování QR kódu – ruční zadání
// je pro případ, že skenování nejde.
Future<bool> askForTableCode(BuildContext context, Cart cart) async {
  final result = await showModalBottomSheet<({int number, String code})>(
    context: context,
    // Aby okno vyjelo nad klávesnici.
    isScrollControlled: true,
    builder: (context) => const _TableCodeSheet(),
  );
  if (result == null) return false;
  cart.setTable(result.number, result.code);
  return true;
}

class _TableCodeSheet extends StatefulWidget {
  const _TableCodeSheet();

  @override
  State<_TableCodeSheet> createState() => _TableCodeSheetState();
}

class _TableCodeSheetState extends State<_TableCodeSheet> {
  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  void confirm() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(context, parseShortTableCode(codeController.text));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Odsazení zespodu o výšku klávesnice, aby ji okno nepřekrylo.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'U kterého stolu sedíte?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCoffee,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Naskenujte QR kód na stole fotoaparátem, '
                  'nebo opište kód, který je pod ním.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Kód stolu (např. 4-K7P2X9)',
                    prefixIcon: Icon(Icons.qr_code_2),
                  ),
                  validator: (value) =>
                      parseShortTableCode(value ?? '') == null
                          ? 'Kód má tvar číslo stolu, pomlčka a 6 znaků'
                          : null,
                  onFieldSubmitted: (_) => confirm(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: confirm,
                    child: const Text('Potvrdit stůl'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
