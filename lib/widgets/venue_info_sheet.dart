import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/venue_settings.dart';
import '../theme/app_theme.dart';
import 'app_message.dart';

// Otevře zespodu okno s informacemi o podniku: adresa, otevírací doba, Wi-Fi.
void showVenueInfo(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const VenueInfoSheet(),
  );
}

class VenueInfoSheet extends StatelessWidget {
  const VenueInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final venue = VenueScope.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(venue.type.icon, color: context.colors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    venue.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.colors.dark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Otevřeno / zavřeno podle přepínače obsluhy.
            Text(
              venue.isOpen ? '● Teď máme otevřeno' : '● Teď máme zavřeno',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: venue.isOpen
                    ? AppColors.success
                    : Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            if (!venue.hasInfo)
              Text(
                'Podnik zatím nevyplnil žádné informace.',
                style: TextStyle(color: context.colors.muted),
              ),
            if (venue.address.isNotEmpty)
              buildRow(context, Icons.place_outlined, 'Adresa', venue.address),
            if (venue.openingHours.isNotEmpty)
              buildRow(
                context,
                Icons.schedule,
                'Otevírací doba',
                venue.openingHours,
              ),
            if (venue.wifiName.isNotEmpty) buildWifi(context, venue),
          ],
        ),
      ),
    );
  }

  Widget buildRow(
    BuildContext context,
    IconData icon,
    String title,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: context.colors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: context.colors.dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Wi-Fi v rámečku, heslo jde jedním klepnutím zkopírovat.
  Widget buildWifi(BuildContext context, VenueSettings venue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi, color: context.colors.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.wifiName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.colors.dark,
                  ),
                ),
                if (venue.wifiPassword.isNotEmpty)
                  SelectableText(
                    'Heslo: ${venue.wifiPassword}',
                    style: TextStyle(color: context.colors.dark),
                  ),
              ],
            ),
          ),
          if (venue.wifiPassword.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Zkopírovat heslo',
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: venue.wifiPassword),
                );
                if (!context.mounted) return;
                showAppMessage(context, 'Heslo zkopírováno');
              },
            ),
        ],
      ),
    );
  }
}
