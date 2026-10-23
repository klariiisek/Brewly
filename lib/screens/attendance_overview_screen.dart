import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/shift.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/shift_widgets.dart';

// Čas odchodu z textu "16:30". Odchod je v den příchodu – a když by byl
// dřív než příchod, je to noční směna a odchod byl až další den.
// Vrátí null, když text není platný čas.
DateTime? parseShiftEnd(String text, DateTime start) {
  final match = RegExp(r'^(\d{1,2})[:.](\d{2})$').firstMatch(text.trim());
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  var end = DateTime(start.year, start.month, start.day, hour, minute);
  if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
  return end;
}

// Přehled docházky pro admina: kdo je právě v práci, kolik kdo odpracoval
// za měsíc. Admin tu ukončí směnu, když se někdo zapomněl odhlásit.
class AttendanceOverviewScreen extends StatefulWidget {
  final AppServices services;

  const AttendanceOverviewScreen({super.key, required this.services});

  @override
  State<AttendanceOverviewScreen> createState() =>
      _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState extends State<AttendanceOverviewScreen> {
  late final Stream<List<ActiveShift>> activeStream;
  late Stream<List<Shift>> shiftsStream;
  DateTime month = monthStart(DateTime.now());
  Timer? ticker;

  @override
  void initState() {
    super.initState();
    activeStream = widget.services.attendance.watchActiveShifts();
    shiftsStream = widget.services.attendance.watchShiftsInMonth(month);
    // Čas „v práci už…“ se posouvá každých 30 s.
    ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  void changeMonth(DateTime value) {
    setState(() {
      month = value;
      shiftsStream = widget.services.attendance.watchShiftsInMonth(month);
    });
  }

  // Okno, kde admin zadá čas odchodu zapomenuté směny.
  Future<void> closeShift(ActiveShift active) async {
    final suggested = active.start.add(const Duration(hours: 8));
    final end = await showDialog<DateTime>(
      context: context,
      builder: (context) => CloseShiftDialog(
        active: active,
        suggested: suggested.isAfter(DateTime.now()) ? DateTime.now() : suggested,
      ),
    );
    if (end == null) return;
    try {
      await widget.services.attendance.closeForgottenShift(active, end);
      if (!mounted) return;
      showAppMessage(context, 'Směna ${active.userName} ukončena');
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Směnu se nepodařilo ukončit');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Docházka zaměstnanců')),
      body: StreamBuilder<List<ActiveShift>>(
        stream: activeStream,
        builder: (context, activeSnapshot) {
          return StreamBuilder<List<Shift>>(
            stream: shiftsStream,
            builder: (context, shiftsSnapshot) {
              if (activeSnapshot.hasError || shiftsSnapshot.hasError) {
                return const EmptyState(
                  icon: Icons.cloud_off,
                  title: 'Docházku se nepodařilo načíst',
                  message: 'Zkontrolujte připojení k internetu.',
                );
              }
              if (!activeSnapshot.hasData || !shiftsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      buildTitle('Právě v práci'),
                      if (activeSnapshot.data!.isEmpty)
                        buildNote('Nikdo nemá zapsaný příchod.'),
                      for (final active in activeSnapshot.data!)
                        buildActiveCard(active),
                      const SizedBox(height: 20),
                      MonthSwitcher(month: month, onChanged: changeMonth),
                      const SizedBox(height: 8),
                      HoursSummary(shifts: shiftsSnapshot.data!),
                      const SizedBox(height: 12),
                      ...buildPeople(shiftsSnapshot.data!),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget buildTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: context.colors.dark,
        ),
      ),
    );
  }

  Widget buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.colors.muted),
      ),
    );
  }

  // Karta zaměstnance v práci. Po dlouhé době upozorní na zapomenutý odchod.
  Widget buildActiveCard(ActiveShift active) {
    final colors = context.colors;
    final forgotten =
        active.elapsed.inHours >= AppConfig.forgottenShiftHours;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          forgotten ? Icons.warning_amber_rounded : Icons.work_history_outlined,
          color: forgotten ? Colors.orange.shade800 : AppColors.success,
        ),
        title: Text(active.userName),
        subtitle: Text(
          '${formatDay(active.start)} od ${formatTime(active.start)} · '
          '${formatDuration(active.elapsed)}'
          '${forgotten ? '\nMožná zapomenutý odchod' : ''}',
        ),
        isThreeLine: forgotten,
        trailing: TextButton(
          onPressed: active.startStamp == null ? null : () => closeShift(active),
          style: TextButton.styleFrom(foregroundColor: colors.primary),
          child: const Text('Ukončit'),
        ),
      ),
    );
  }

  // Odpracované hodiny po zaměstnancích; po rozkliknutí jejich směny.
  List<Widget> buildPeople(List<Shift> shifts) {
    if (shifts.isEmpty) {
      return [buildNote('V tomto měsíci zatím žádná směna.')];
    }
    // Seskupení směn podle zaměstnance (jako GROUP BY v SQL).
    final byPerson = <String, List<Shift>>{};
    for (final shift in shifts) {
      byPerson.putIfAbsent(shift.userId, () => []).add(shift);
    }
    // Nejvíc hodin nahoře.
    final people = byPerson.values.toList()
      ..sort((a, b) => totalDuration(b).compareTo(totalDuration(a)));

    return [
      for (final personShifts in people)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: Icon(Icons.person_outline, color: context.colors.primary),
            title: Text(personShifts.first.userName),
            subtitle: Text(formatShiftCount(personShifts.length)),
            trailing: Text(
              formatDuration(totalDuration(personShifts)),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.colors.dark,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            children: [
              for (final shift in personShifts) ShiftTile(shift: shift),
            ],
          ),
        ),
    ];
  }
}

// Okno „Ukončit směnu“: admin napíše čas odchodu (např. 16:30).
class CloseShiftDialog extends StatefulWidget {
  final ActiveShift active;
  final DateTime suggested;

  const CloseShiftDialog({
    super.key,
    required this.active,
    required this.suggested,
  });

  @override
  State<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<CloseShiftDialog> {
  late final TextEditingController controller =
      TextEditingController(text: formatTime(widget.suggested));
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void confirm() {
    final end = parseShiftEnd(controller.text, widget.active.start);
    if (end == null) {
      setState(() => error = 'Zadejte čas, např. 16:30');
      return;
    }
    if (end.isAfter(DateTime.now())) {
      setState(() => error = 'Odchod nemůže být v budoucnosti');
      return;
    }
    Navigator.pop(context, end);
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.active.start;
    return AlertDialog(
      title: Text('Ukončit směnu – ${widget.active.userName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Příchod: ${formatDay(start)} ${formatTime(start)}'),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(
              labelText: 'Čas odchodu',
              hintText: '16:30',
              errorText: error,
            ),
            onSubmitted: (_) => confirm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zrušit'),
        ),
        ElevatedButton(onPressed: confirm, child: const Text('Uložit odchod')),
      ],
    );
  }
}
