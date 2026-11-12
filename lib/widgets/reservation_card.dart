import 'package:flutter/material.dart';

import '../models/reservation.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

// Barva podle stavu rezervace.
Color reservationStatusColor(BuildContext context, ReservationStatus status) {
  switch (status) {
    case ReservationStatus.ceka:
      return context.colors.accent;
    case ReservationStatus.potvrzena:
      return AppColors.success;
    case ReservationStatus.odmitnuta:
      return Theme.of(context).colorScheme.error;
    case ReservationStatus.zrusena:
      return context.colors.muted;
  }
}

// Karta rezervace: kdy, kolik lidí, poznámka, stav. Zákazník i obsluha
// vidí stejnou kartu, liší se jen tlačítky dole ([actions]).
class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  // Ukázat jméno zákazníka (pro obsluhu).
  final bool showName;
  final List<Widget> actions;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.showName = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = reservationStatusColor(context, reservation.status);
    final time = reservation.time;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.14),
                  child: Icon(Icons.event_seat_outlined, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatRelativeDay(time)} v ${formatTime(time)}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colors.dark,
                        ),
                      ),
                      Text(
                        [
                          if (showName) reservation.customerName,
                          formatPeopleCount(reservation.people),
                          if (reservation.tableNumber > 0)
                            'stůl ${reservation.tableNumber}',
                        ].join(' · '),
                        style: TextStyle(color: colors.muted),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          reservationStatusText(reservation.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (reservation.note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 18, color: colors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reservation.note,
                      style: TextStyle(color: colors.dark),
                    ),
                  ),
                ],
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
