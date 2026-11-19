// Otevírací doba podniku po dnech v týdnu.
//
// V databázi je to seznam 7 textů (pondělí … neděle), např.
// ["08:00-20:00", …, ""] – prázdný text = ten den je zavřeno.

// Otevírací doba v jeden den: otevírá se [from], zavírá se [to]
// (v minutách od půlnoci, např. 8:00 = 480, půlnoc = 1440).
class DayHours {
  final int from;
  final int to;

  const DayHours(this.from, this.to);

  // Z textu "08:00-20:00". Prázdný nebo chybný text = zavřeno (null).
  static DayHours? parse(String text) {
    final match = RegExp(r'^(\d\d):(\d\d)-(\d\d):(\d\d)$').firstMatch(text);
    if (match == null) return null;
    int part(int index) => int.parse(match.group(index)!);
    final from = part(1) * 60 + part(2);
    final to = part(3) * 60 + part(4);
    if (from > to || to > 24 * 60) return null;
    return DayHours(from, to);
  }

  @override
  String toString() => '${minutesText(from)}-${minutesText(to)}';

  @override
  bool operator ==(Object other) =>
      other is DayHours && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

// Minuty od půlnoci jako čas "08:30" (pro databázi a výběr v nastavení).
String minutesText(int minutes) {
  final hours = (minutes ~/ 60).toString().padLeft(2, '0');
  final rest = (minutes % 60).toString().padLeft(2, '0');
  return '$hours:$rest';
}

// Čas pro zákazníka bez nuly na začátku: "8:00", "20:30".
String shortTime(int minutes) =>
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

// Otevírací doba jednoho dne pro zákazníka: "8:00–20:00".
String hoursText(DayHours hours) =>
    '${shortTime(hours.from)}–${shortTime(hours.to)}';

// Skupina po sobě jdoucích dnů se stejnou otevírací dobou,
// např. pondělí až pátek 8:00–20:00. Dny jsou 0 = pondělí … 6 = neděle,
// hours == null = zavřeno.
class OpeningGroup {
  final int firstDay;
  final int lastDay;
  final DayHours? hours;

  const OpeningGroup(this.firstDay, this.lastDay, this.hours);
}

// Spojí stejné sousední dny, aby se otevírací doba dala vypsat krátce:
// "Po–Pá 8:00–20:00, So 10:00–22:00, Ne zavřeno".
List<OpeningGroup> groupOpeningDays(List<DayHours?> days) {
  final groups = <OpeningGroup>[];
  var start = 0;
  for (var day = 1; day <= days.length; day++) {
    if (day == days.length || days[day] != days[start]) {
      groups.add(OpeningGroup(start, day - 1, days[start]));
      start = day;
    }
  }
  return groups;
}
