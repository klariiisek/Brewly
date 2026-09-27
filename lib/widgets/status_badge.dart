import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_theme.dart';

// Barva podle stavu objednávky.
Color orderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.prijata:
      return AppColors.coffee;
    case OrderStatus.pripravujeSe:
      return AppColors.caramel;
    case OrderStatus.pripravena:
      return AppColors.success;
    case OrderStatus.dokoncena:
      return AppColors.muted;
  }
}

// Barevný štítek se stavem objednávky, např. "Připravuje se".
class StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        orderStatusText(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
