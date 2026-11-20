import 'package:flutter/material.dart';

import '../l10n/language.dart';

// Tlačítko „English“ / „Čeština“: přepne jazyk aplikace na ten druhý.
// Je na úvodu a v hlavičce menu – turista, který naskenuje QR kód,
// ho uvidí hned.
class LanguageButton extends StatelessWidget {
  final Color? color;

  const LanguageButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Tooltip(
      message: t.changeLanguage,
      child: TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: color),
        icon: const Icon(Icons.translate, size: 18),
        label: Text(t.otherLanguageName),
        onPressed: () =>
            setLanguage(Locale(t.localeName == 'cs' ? 'en' : 'cs')),
      ),
    );
  }
}
