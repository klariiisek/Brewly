import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_theme.dart';

// Velká věta pro zákazníka podle stavu objednávky.
String orderProgressMessage(OrderStatus status) {
  switch (status) {
    case OrderStatus.prijata:
      return 'Objednávku jsme přijali';
    case OrderStatus.pripravujeSe:
      return 'Připravujeme vaši objednávku…';
    case OrderStatus.pripravena:
      return 'Hotovo! Za chvíli ji máte na stole 🎉';
    case OrderStatus.dokoncena:
      return 'Dobrou chuť! 🙌';
  }
}

// Ukazatel průběhu objednávky: 4 kroky s ikonami spojené čarou.
// Hotové kroky jsou barevné, aktuální krok je zvýrazněný.
class OrderProgress extends StatelessWidget {
  final OrderStatus status;

  const OrderProgress({super.key, required this.status});

  static const List<IconData> _icons = [
    Icons.receipt_long,
    Icons.local_fire_department,
    Icons.check_circle,
    Icons.sentiment_very_satisfied,
  ];

  @override
  Widget build(BuildContext context) {
    final current = status.index; // 0 = přijata … 3 = dokončena
    final colors = context.colors;

    return Column(
      children: [
        // AnimatedSwitcher = text se při změně stavu plynule vymění.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            orderProgressMessage(status),
            key: ValueKey(status),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.dark,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 0; i < OrderStatus.values.length; i++) ...[
              // Čára mezi kroky (před každým krokem kromě prvního).
              if (i > 0)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= current
                          ? colors.primary
                          : colors.muted.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              buildStep(context, i, current),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final step in OrderStatus.values)
              Expanded(
                child: Text(
                  orderStatusText(step),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        step == status ? FontWeight.bold : FontWeight.normal,
                    color: step.index <= current ? colors.dark : colors.muted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget buildStep(BuildContext context, int index, int current) {
    final colors = context.colors;
    final isDone = index <= current;
    final isCurrent = index == current;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: isCurrent ? 48 : 36,
      height: isCurrent ? 48 : 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? colors.primary : colors.muted.withValues(alpha: 0.15),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Icon(
        _icons[index],
        size: isCurrent ? 26 : 20,
        color: isDone ? Colors.white : colors.muted,
      ),
    );
  }
}
