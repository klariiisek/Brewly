import 'package:flutter/material.dart';

// Zobrazí krátké hlášení dole na obrazovce (SnackBar).
// Předchozí hlášení nejdřív schová, aby se nehromadila ve frontě.
void showAppMessage(BuildContext context, String text) {
  final messenger = ScaffoldMessenger.of(context);

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(text),
      duration: const Duration(milliseconds: 1500),
    ),
  );
}
