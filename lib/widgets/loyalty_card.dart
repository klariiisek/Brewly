import 'package:flutter/material.dart';

import '../models/loyalty.dart';
import '../models/venue_settings.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

// Razítková karta jako papírová kartička: řada políček, orazítkovaná mají
// ikonu podniku, poslední políčko je dárek (odměna).
class LoyaltyCard extends StatelessWidget {
  final LoyaltyStatus status;

  // Název kategorie, za kterou jsou razítka (např. Káva).
  final String categoryName;

  const LoyaltyCard({
    super.key,
    required this.status,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final venue = VenueScope.of(context);
    // Políček je tolik, kolikátý kus je zdarma (10. káva = 10 políček):
    // razítka a na konci dárek.
    final rows = (status.goal / 7).ceil();
    final perRow = (status.goal / rows).ceil();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.loyalty_outlined, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Razítková karta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.dark,
                  ),
                ),
              ),
              Text(
                '${status.filled}/${status.needed}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Za každý kus z kategorie $categoryName jedno razítko. '
              'Každý ${status.goal}. kus máte zdarma.',
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),
          // Políčka karty v pravidelných řadách (nejvýš 7 v řadě,
          // např. 10 razítek = 2 řady po 5).
          for (var row = 0; row < rows; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = row * perRow;
                      index < status.goal && index < (row + 1) * perRow;
                      index++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: index == status.goal - 1
                          // Poslední políčko = dárek. Rozsvítí se, když je
                          // karta plná a odměnu jde uplatnit.
                          ? _Stamp.gift(ready: status.hasReward)
                          : _Stamp(
                              filled: index < status.filled,
                              icon: venue.type.icon,
                            ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Text(
            status.hasReward
                ? '🎉 ${status.goal}. kus máte zdarma! Uplatníte ho v košíku.'
                : 'Ještě ${formatStampCount(status.missing)} '
                    'a ${status.goal}. kus máte zdarma.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: status.hasReward ? AppColors.success : colors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

// Jedno políčko karty: razítko, nebo dárek na konci.
class _Stamp extends StatelessWidget {
  final bool filled;
  final bool isGift;
  final IconData icon;

  const _Stamp({required this.filled, required this.icon}) : isGift = false;

  // Políčko s dárkem: [ready] = karta je plná, dárek svítí zeleně.
  const _Stamp.gift({required bool ready})
      : filled = ready,
        isGift = true,
        icon = Icons.card_giftcard;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isGift ? AppColors.success : colors.primary;
    // Orazítkované políčko se trochu natočí – jako skutečné razítko.
    return Transform.rotate(
      angle: filled && !isGift ? -0.12 : 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : Colors.transparent,
          border: Border.all(
            color: filled
                ? color
                : isGift
                    ? AppColors.success.withValues(alpha: 0.7)
                    : colors.muted.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled
              ? Colors.white
              : isGift
                  ? AppColors.success
                  : colors.muted.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
