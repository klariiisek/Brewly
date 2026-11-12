import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/reservation.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/reservation_card.dart';

// Rezervace pro obsluhu a admina: dnešní a budoucí rezervace po dnech.
// Nové (čekající) obsluha potvrdí – případně rovnou s číslem stolu –
// nebo odmítne.
class StaffReservationsScreen extends StatefulWidget {
  final AppServices services;

  const StaffReservationsScreen({super.key, required this.services});

  @override
  State<StaffReservationsScreen> createState() =>
      _StaffReservationsScreenState();
}

class _StaffReservationsScreenState extends State<StaffReservationsScreen> {
  late final Stream<List<Reservation>> reservationsStream;

  @override
  void initState() {
    super.initState();
    reservationsStream = widget.services.reservations
        .watchUpcomingReservations();
  }

  Future<void> confirm(Reservation reservation, List<Reservation> all) async {
    // Vybraný stůl; null = dialog zavřen bez potvrzení, 0 = bez stolu.
    final table = await showDialog<int>(
      context: context,
      builder: (context) => TablePickerDialog(
        reservation: reservation,
        occupied: occupiedTables(
          reservation,
          all,
          duration: const Duration(
            minutes: AppConfig.reservationDurationMinutes,
          ),
        ),
      ),
    );
    if (table == null) return;
    await save(
      () => widget.services.reservations.confirm(reservation.id, table),
      'Rezervace potvrzena',
    );
  }

  Future<void> decline(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odmítnout rezervaci?'),
        content: Text(
          '${reservation.customerName}, ${formatRelativeDay(reservation.time)} '
          'v ${formatTime(reservation.time)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zpět'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Odmítnout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await save(
      () => widget.services.reservations.decline(reservation.id),
      'Rezervace odmítnuta',
    );
  }

  Future<void> save(Future<void> Function() action, String doneText) async {
    try {
      await action();
      if (!mounted) return;
      showAppMessage(context, doneText);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Nepodařilo se uložit, zkuste to znovu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rezervace')),
      body: StreamBuilder<List<Reservation>>(
        stream: reservationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.cloud_off,
              title: 'Rezervace se nepodařilo načíst',
              message: 'Zkontrolujte připojení k internetu.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          // Nahoře žádosti, které čekají na potvrzení (nejbližší první).
          // Potvrzením se přesunou dolů mezi potvrzené. Zrušené
          // a odmítnuté obsluhu nezajímají.
          final pending = all
              .where((r) => r.status == ReservationStatus.ceka)
              .toList();
          final confirmed = all
              .where((r) => r.status == ReservationStatus.potvrzena)
              .toList();
          if (pending.isEmpty && confirmed.isEmpty) {
            return const EmptyState(
              icon: Icons.event_seat_outlined,
              title: 'Žádné rezervace',
              message: 'Až si zákazník zarezervuje stůl, objeví se tady.',
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (pending.isNotEmpty) ...[
                    sectionTitle(
                      'Čeká na potvrzení (${pending.length})',
                      color: context.colors.accent,
                    ),
                    for (final reservation in pending)
                      buildCard(reservation, all),
                    const SizedBox(height: 12),
                  ],
                  sectionTitle('Potvrzené'),
                  if (confirmed.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Zatím žádná potvrzená rezervace.',
                        style: TextStyle(color: context.colors.muted),
                      ),
                    ),
                  ...buildDays(confirmed, all),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget sectionTitle(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color ?? context.colors.dark,
        ),
      ),
    );
  }

  // Karta rezervace s tlačítky: čekající jde potvrdit nebo odmítnout,
  // potvrzenou ještě odmítnout. [all] = všechny rezervace (kvůli
  // obsazeným stolům).
  Widget buildCard(Reservation reservation, List<Reservation> all) {
    return ReservationCard(
      reservation: reservation,
      showName: true,
      actions: [
        TextButton(
          onPressed: () => decline(reservation),
          child: const Text('Odmítnout'),
        ),
        if (reservation.status == ReservationStatus.ceka)
          ElevatedButton(
            onPressed: () => confirm(reservation, all),
            child: const Text('Potvrdit'),
          ),
      ],
    );
  }

  // Potvrzené rezervace rozdělené po dnech s nadpisem „Dnes“, „Čt 13. 11.“…
  List<Widget> buildDays(
    List<Reservation> reservations,
    List<Reservation> all,
  ) {
    final widgets = <Widget>[];
    DateTime? lastDay;
    for (final reservation in reservations) {
      final time = reservation.time;
      final day = DateTime(time.year, time.month, time.day);
      if (day != lastDay) {
        lastDay = day;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              capitalize(formatRelativeDay(day)),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colors.muted,
              ),
            ),
          ),
        );
      }
      widgets.add(buildCard(reservation, all));
    }
    return widgets;
  }
}

String capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

// Potvrzení rezervace s výběrem stolu (nepovinné – stůl jde určit
// i až při příchodu hostů). Stoly obsazené v tu dobu jinou rezervací
// nejde vybrat, aby jeden stůl nedostali dva hosté najednou.
class TablePickerDialog extends StatefulWidget {
  final Reservation reservation;
  // Číslo stolu → rezervace, která ho v tu dobu už má.
  final Map<int, Reservation> occupied;

  const TablePickerDialog({
    super.key,
    required this.reservation,
    this.occupied = const {},
  });

  @override
  State<TablePickerDialog> createState() => _TablePickerDialogState();
}

class _TablePickerDialogState extends State<TablePickerDialog> {
  int table = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Na malém telefonu se obsah dá posunout.
      scrollable: true,
      title: const Text('Potvrdit rezervaci'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.reservation.customerName}, '
            '${formatPeopleCount(widget.reservation.people)}',
          ),
          const SizedBox(height: 16),
          const Text('Stůl (nepovinné):'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('Bez stolu'),
                selected: table == 0,
                onSelected: (_) => setState(() => table = 0),
              ),
              for (var number = 1; number <= AppConfig.tableCount; number++)
                ChoiceChip(
                  label: Text('$number'),
                  selected: table == number,
                  // Obsazený stůl je šedý a nejde vybrat.
                  onSelected: widget.occupied.containsKey(number)
                      ? null
                      : (_) => setState(() => table = number),
                ),
            ],
          ),
          if (widget.occupied.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final entry in widget.occupied.entries)
              Text(
                'Stůl ${entry.key} je obsazený: '
                '${entry.value.customerName}, '
                '${formatTime(entry.value.time)}',
                style: TextStyle(color: context.colors.muted, fontSize: 13),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zpět'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, table),
          child: const Text('Potvrdit'),
        ),
      ],
    );
  }
}
