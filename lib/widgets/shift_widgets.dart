import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

// Přepínač měsíce: ‹ říjen 2026 ›. Do budoucnosti listovat nejde.
class MonthSwitcher extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  const MonthSwitcher({super.key, required this.month, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isCurrent = monthStart(month) == monthStart(DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Předchozí měsíc',
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
        ),
        SizedBox(
          width: 150,
          child: Text(
            formatMonth(month),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: context.colors.dark,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Další měsíc',
          onPressed: isCurrent
              ? null
              : () => onChanged(DateTime(month.year, month.month + 1)),
        ),
      ],
    );
  }
}

// Velké číslo „odpracováno“ a počet směn.
class HoursSummary extends StatelessWidget {
  final List<Shift> shifts;

  const HoursSummary({super.key, required this.shifts});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        children: [
          Text('Odpracováno', style: TextStyle(color: colors.muted)),
          const SizedBox(height: 4),
          Text(
            formatDuration(totalDuration(shifts)),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: colors.dark,
            ),
          ),
          Text(
            formatShiftCount(shifts.length),
            style: TextStyle(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

// Jeden řádek směny: den, od–do, délka (+ poznámka, když ji ukončil admin).
class ShiftTile extends StatelessWidget {
  final Shift shift;

  const ShiftTile({super.key, required this.shift});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.schedule, color: colors.primary),
        title: Text(
          '${formatDay(shift.start)}  ·  '
          '${formatTime(shift.start)} – ${formatTime(shift.end)}',
        ),
        subtitle: shift.edited ? const Text('Odchod doplnil admin') : null,
        trailing: Text(
          formatDuration(shift.duration),
          style: TextStyle(fontWeight: FontWeight.w600, color: colors.dark),
        ),
      ),
    );
  }
}
