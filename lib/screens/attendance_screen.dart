import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/shift_widgets.dart';

// Docházka obsluhy: Příchod / Odchod a odpracované hodiny za měsíc.
// (Inspirace: docházka v pokladním systému Dotykačka.)
class AttendanceScreen extends StatefulWidget {
  final AppServices services;
  final User user;

  const AttendanceScreen({
    super.key,
    required this.services,
    required this.user,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final Stream<ActiveShift?> activeStream;
  late final Stream<List<Shift>> shiftsStream;

  // Který měsíc se ukazuje (výchozí = tento).
  DateTime month = monthStart(DateTime.now());

  // Překreslí obrazovku každých 30 s, aby běžel čas „v práci už 2 h 15 min“.
  Timer? ticker;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    activeStream = widget.services.attendance.watchActiveShift(widget.user.uid);
    shiftsStream = widget.services.attendance.watchMyShifts(widget.user.uid);
    ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  // Společné pro Příchod i Odchod: ukáže čekání a případnou chybu.
  Future<void> save(Future<void> Function() action, String doneText) async {
    setState(() => isSaving = true);
    try {
      await action();
      if (!mounted) return;
      showAppMessage(context, doneText);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Nepodařilo se uložit, zkuste to znovu');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void clockIn() {
    save(
      () => widget.services.attendance.clockIn(
        userId: widget.user.uid,
        userName: userDisplayName(widget.user),
      ),
      'Příchod zapsán – hezkou směnu!',
    );
  }

  void clockOut(ActiveShift active) {
    save(
      () => widget.services.attendance.clockOut(active),
      'Odchod zapsán – díky za dnešek!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Docházka')),
      body: StreamBuilder<ActiveShift?>(
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
              if (activeSnapshot.connectionState == ConnectionState.waiting ||
                  !shiftsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final monthShifts = shiftsInMonth(shiftsSnapshot.data!, month);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      buildClockCard(activeSnapshot.data),
                      const SizedBox(height: 20),
                      MonthSwitcher(
                        month: month,
                        onChanged: (value) => setState(() => month = value),
                      ),
                      const SizedBox(height: 8),
                      HoursSummary(shifts: monthShifts),
                      const SizedBox(height: 12),
                      if (monthShifts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'V tomto měsíci zatím žádná směna.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.colors.muted),
                          ),
                        ),
                      for (final shift in monthShifts) ShiftTile(shift: shift),
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

  // Horní karta: buď „Nejste v práci“ + Příchod, nebo „V práci od…“ + Odchod.
  Widget buildClockCard(ActiveShift? active) {
    final colors = context.colors;
    final isWorking = active != null;
    final mainColor = isWorking ? AppColors.success : colors.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: mainColor.withValues(alpha: 0.14),
              child: Icon(
                isWorking ? Icons.work_history_outlined : Icons.home_outlined,
                size: 32,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isWorking
                  ? 'V práci od ${formatTime(active.start)}'
                  : 'Nejste v práci',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isWorking
                  ? 'Zatím ${formatDuration(active.elapsed)}'
                  : 'Na začátku směny dejte Příchod.',
              style: TextStyle(color: colors.muted),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isWorking ? colors.dark : AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(isWorking ? Icons.logout : Icons.login),
                label: Text(isWorking ? 'Odchod' : 'Příchod'),
                // Dokud server nepotvrdí čas příchodu, odchod nejde.
                onPressed: isSaving || (isWorking && active.startStamp == null)
                    ? null
                    : () => isWorking ? clockOut(active) : clockIn(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
