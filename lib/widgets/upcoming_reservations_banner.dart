import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/reservation.dart';
import '../screens/staff_home_screen.dart' show ToolColors;
import '../services/reservation_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

// Vybere potvrzené rezervace, na které hosté přijdou v nejbližší hodině
// (nebo přišli před chvílí – do 15 minut po čase rezervace).
List<Reservation> soonReservations(List<Reservation> all, DateTime now) {
  final from = now.subtract(const Duration(minutes: 15));
  final to = now.add(
    const Duration(minutes: AppConfig.reservationWarningMinutes),
  );
  return all
      .where(
        (r) =>
            r.status == ReservationStatus.potvrzena &&
            r.time.isAfter(from) &&
            r.time.isBefore(to),
      )
      .toList();
}

// Upozornění pro obsluhu: „Brzy přijdou hosté s rezervací“ – který stůl,
// kdy a kolik lidí. Aby obsluha stůl včas uvolnila a nikoho k němu
// neposadila. Když nic nehrozí, není vidět vůbec.
class UpcomingReservationsBanner extends StatefulWidget {
  final ReservationService reservationService;
  final EdgeInsets margin;

  const UpcomingReservationsBanner({
    super.key,
    required this.reservationService,
    this.margin = const EdgeInsets.fromLTRB(12, 12, 12, 0),
  });

  @override
  State<UpcomingReservationsBanner> createState() =>
      _UpcomingReservationsBannerState();
}

class _UpcomingReservationsBannerState
    extends State<UpcomingReservationsBanner> {
  late final Stream<List<Reservation>> reservationsStream;

  // Čas běží i bez změny v databázi – každou minutu přepočítáme,
  // které rezervace už jsou „brzy“.
  Timer? ticker;

  @override
  void initState() {
    super.initState();
    reservationsStream = widget.reservationService.watchUpcomingReservations();
    ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Reservation>>(
      stream: reservationsStream,
      builder: (context, snapshot) {
        final soon = soonReservations(snapshot.data ?? [], DateTime.now());
        if (soon.isEmpty) return const SizedBox.shrink();
        return buildBanner(soon);
      },
    );
  }

  String tableText(Reservation reservation) => reservation.tableNumber > 0
      ? 'Stůl ${reservation.tableNumber}'
      : 'Zatím bez stolu';

  Widget buildBanner(List<Reservation> soon) {
    final colors = context.colors;
    // Stejná barva jako dlaždice Rezervace – obsluha hned pozná, čeho se
    // upozornění týká.
    const color = ToolColors.reservations;
    return Container(
      width: double.infinity,
      margin: widget.margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_seat_outlined, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Brzy přijdou hosté s rezervací',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final reservation in soon)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${tableText(reservation)} · ${formatTime(reservation.time)} · '
                '${reservation.customerName}, '
                '${formatPeopleCount(reservation.people)}',
                style: TextStyle(color: colors.dark),
              ),
            ),
        ],
      ),
    );
  }
}
