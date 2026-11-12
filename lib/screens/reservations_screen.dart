import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/reservation.dart';
import '../models/venue_settings.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/reservation_card.dart';

// Rezervace zákazníka: seznam jeho rezervací (stav se mění živě, když je
// obsluha potvrdí) a tlačítko Nová rezervace.
class ReservationsScreen extends StatefulWidget {
  final AppServices services;
  final User user;

  const ReservationsScreen({
    super.key,
    required this.services,
    required this.user,
  });

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  late final Stream<List<Reservation>> reservationsStream;

  @override
  void initState() {
    super.initState();
    reservationsStream = widget.services.reservations.watchMyReservations(
      widget.user.uid,
    );
  }

  // Nová rezervace – nejvýš 3 nadcházející najednou, aby si jeden
  // zákazník nezabral půl podniku nebo databázi nezaplnil spamem.
  void openNewReservation(int upcomingCount) {
    if (upcomingCount >= AppConfig.maxActiveReservations) {
      showAppMessage(
        context,
        'Máte už ${AppConfig.maxActiveReservations} rezervace – '
        'nejdřív některou zrušte',
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NewReservationScreen(services: widget.services, user: widget.user),
      ),
    );
  }

  Future<void> cancel(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zrušit rezervaci?'),
        content: Text(
          '${formatRelativeDay(reservation.time)} '
          'v ${formatTime(reservation.time)}, '
          '${formatPeopleCount(reservation.people)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ponechat'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Zrušit rezervaci'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.services.reservations.cancel(reservation.id);
      if (!mounted) return;
      showAppMessage(context, 'Rezervace zrušena');
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Rezervaci se nepodařilo zrušit');
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
          final upcoming = all.where((r) => r.isUpcoming).toList();
          // Starší: proběhlé, zrušené a odmítnuté – nejnovější nahoře.
          final older = all
              .where((r) => !r.isUpcoming)
              .toList()
              .reversed
              .take(10);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Nová rezervace'),
                      onPressed: () => openNewReservation(upcoming.length),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (upcoming.isEmpty)
                    const EmptyState(
                      icon: Icons.event_seat_outlined,
                      title: 'Zatím žádná rezervace',
                      message:
                          'Zarezervujte si stůl a obsluha vám ho '
                          'potvrdí.',
                    ),
                  for (final reservation in upcoming)
                    ReservationCard(
                      reservation: reservation,
                      actions: [
                        if (reservation.canCancel)
                          TextButton(
                            onPressed: () => cancel(reservation),
                            child: const Text('Zrušit'),
                          ),
                      ],
                    ),
                  if (older.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    sectionTitle('Starší'),
                    for (final reservation in older)
                      Opacity(
                        opacity: 0.7,
                        child: ReservationCard(reservation: reservation),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: context.colors.dark,
        ),
      ),
    );
  }
}

// Nová rezervace: den, čas, počet osob a poznámka.
// Dny a časy jsou tlačítka (pohodlné na mobilu, žádné psaní data).
class NewReservationScreen extends StatefulWidget {
  final AppServices services;
  final User user;

  const NewReservationScreen({
    super.key,
    required this.services,
    required this.user,
  });

  @override
  State<NewReservationScreen> createState() => _NewReservationScreenState();
}

class _NewReservationScreenState extends State<NewReservationScreen> {
  final noteController = TextEditingController();
  DateTime? selectedDay;
  DateTime? selectedTime;
  int people = 2;
  bool isSaving = false;

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  // Časy pro jeden den podle časů rezervací, které nastavil admin.
  List<DateTime> slotsFor(DateTime day) {
    return reservationSlots(
      day,
      hours: VenueScope.of(context).reservationHoursOn(day),
      minAdvance: const Duration(
        minutes: AppConfig.reservationMinAdvanceMinutes,
      ),
    );
  }

  // Dny, kdy jde rezervovat: příštích 30 dní kromě dnů bez rezervací
  // (a dneška, když už je pozdě).
  List<DateTime> availableDays() {
    final now = DateTime.now();
    return [
      for (var i = 0; i < AppConfig.reservationDaysAhead; i++)
        DateTime(now.year, now.month, now.day + i),
    ].where((day) => slotsFor(day).isNotEmpty).toList();
  }

  Future<void> submit() async {
    final time = selectedTime;
    if (time == null) return;
    setState(() => isSaving = true);
    try {
      await widget.services.reservations.createReservation(
        userId: widget.user.uid,
        customerName: userDisplayName(widget.user),
        time: time,
        people: people,
        note: noteController.text.trim(),
      );
      if (!mounted) return;
      showAppMessage(context, 'Rezervace odeslána – počkejte na potvrzení');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => isSaving = false);
      showAppMessage(context, 'Rezervaci se nepodařilo odeslat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final days = availableDays();
    if (days.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nová rezervace')),
        body: const EmptyState(
          icon: Icons.event_busy_outlined,
          title: 'Rezervace teď nejdou',
          message: 'Podnik v nejbližších dnech rezervace nepřijímá.',
        ),
      );
    }
    // Když admin mezitím změnil časy, vybraný den už nemusí jít.
    final day = days.contains(selectedDay) ? selectedDay! : days.first;
    final slots = slotsFor(day);
    final time = slots.contains(selectedTime) ? selectedTime : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nová rezervace')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              label('Den'),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final option = days[index];
                    return ChoiceChip(
                      label: Text(formatRelativeDay(option)),
                      selected: option == day,
                      onSelected: (_) => setState(() {
                        selectedDay = option;
                        selectedTime = null;
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              label('Čas'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in slots)
                    ChoiceChip(
                      label: Text(formatTime(slot)),
                      selected: slot == selectedTime,
                      onSelected: (_) => setState(() => selectedTime = slot),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              label('Počet osob'),
              Row(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    tooltip: 'Méně osob',
                    onPressed: people > 1
                        ? () => setState(() => people--)
                        : null,
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      formatPeopleCount(people),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: colors.dark,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    tooltip: 'Více osob',
                    onPressed: people < AppConfig.maxReservationPeople
                        ? () => setState(() => people++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              label('Poznámka (nepovinné)'),
              TextField(
                controller: noteController,
                maxLength: AppConfig.maxReservationNoteLength,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Např. dětská židlička, oslava narozenin…',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: time == null || isSaving ? null : submit,
                  child: Text(
                    time == null
                        ? 'Vyberte čas'
                        : 'Rezervovat ${formatRelativeDay(time)} v ${formatTime(time)}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: context.colors.dark,
        ),
      ),
    );
  }
}
