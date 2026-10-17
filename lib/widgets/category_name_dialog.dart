import 'package:flutter/material.dart';

import '../utils/text.dart';

// Okno s textovým polem pro název kategorie. Vrátí název, nebo null.
// Hlídá, aby název nebyl prázdný a aby taková kategorie ještě nebyla
// (porovnává bez diakritiky: "káva" = "Káva").
Future<String?> askForCategoryName(
  BuildContext context, {
  required String title,
  required String buttonText,
  required List<String> existingNames,
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
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Název kategorie'),
            onFieldSubmitted: (_) => submit(),
            validator: (value) {
              final name = (value ?? '').trim();
              if (name.isEmpty) return 'Zadejte název';
              final isTaken = existingNames.any((existing) =>
                  normalizeText(existing) == normalizeText(name) &&
                  normalizeText(existing) != normalizeText(initialName));
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
