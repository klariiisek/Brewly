import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/opening_hours.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

// Jazyky aplikace. Přeložená je zákaznická část (menu, košík, objednávky,
// rezervace, profil, přihlášení). Obsluha a admin jsou čeští zaměstnanci,
// jejich obrazovky zůstávají česky.
//
// Jazyk, který si zákazník vybral tlačítkem (null = podle telefonu).
// ValueNotifier = hodnota, při jejíž změně se aplikace sama překreslí.
final appLanguage = ValueNotifier<Locale?>(null);

// Pod tímto klíčem si zařízení pamatuje zvolený jazyk ("cs" / "en").
const _languageKey = 'language';

// Načte jazyk, který si zákazník na tomto zařízení vybral dřív.
// Ukládá se v telefonu / prohlížeči (shared_preferences), ne k účtu –
// funguje tak i pro nepřihlášeného turistu z QR kódu.
Future<void> loadSavedLanguage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_languageKey);
    if (code == 'cs' || code == 'en') appLanguage.value = Locale(code!);
  } catch (error) {
    // Když se uložená volba nedá přečíst, jazyk se vybere podle telefonu.
  }
}

// Přepne jazyk aplikace a zapamatuje si ho i po zavření.
Future<void> setLanguage(Locale language) async {
  appLanguage.value = language;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.languageCode);
  } catch (error) {
    // Neuložilo se – jazyk platí aspoň do zavření aplikace.
  }
}

// Jazyk podle telefonu: česky pro češtinu a slovenštinu (Slováci češtině
// rozumí), anglicky pro všechny ostatní – turista z Německa nebo Itálie
// spíš rozumí angličtině než češtině.
Locale resolveLanguage(Locale? device) {
  if (device == null) return const Locale('cs');
  return ['cs', 'sk'].contains(device.languageCode)
      ? const Locale('cs')
      : const Locale('en');
}

// Zkratka: context.t.objednat místo AppLocalizations.of(context).objednat.
extension Translations on BuildContext {
  AppLocalizations get t => AppLocalizations.of(this);
}

const _enWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _enMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _csWeekdays = ['po', 'út', 'st', 'čt', 'pá', 'so', 'ne'];

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

// Datum bez roku: česky "14. 11.", anglicky "14 Nov".
String shortDate(AppLocalizations t, DateTime date) => t.localeName == 'cs'
    ? '${date.day}. ${date.month}.'
    : '${date.day} ${_enMonths[date.month - 1]}';

// Den s názvem: česky "so 14. 11.", anglicky "Sat 14 Nov".
String dayName(AppLocalizations t, DateTime date) {
  final weekdays = t.localeName == 'cs' ? _csWeekdays : _enWeekdays;
  return '${weekdays[date.weekday - 1]} ${shortDate(t, date)}';
}

// "dnes", "zítra", jinak den s názvem.
String relativeDay(AppLocalizations t, DateTime date) {
  if (_isToday(date)) return t.today;
  // Den předem jako datum (ne „před 24 hodinami“ – kvůli posunu času).
  if (_isToday(DateTime(date.year, date.month, date.day - 1))) {
    return t.tomorrow;
  }
  return dayName(t, date);
}

// Kdy byla objednávka vytvořena: "dnes 14:05", nebo "14. 10. 14:05".
String orderDate(AppLocalizations t, DateTime time) {
  final day = _isToday(time) ? t.today : shortDate(t, time);
  final minutes = time.minute.toString().padLeft(2, '0');
  return '$day ${time.hour}:$minutes';
}

const _csDayNames = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
const _enDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// Otevírací doba po řádcích, stejné sousední dny spojené:
// "Po–Pá 8:00–20:00", "So 10:00–22:00", "Ne zavřeno".
List<String> openingDaysText(AppLocalizations t, List<DayHours?> days) {
  final names = t.localeName == 'cs' ? _csDayNames : _enDayNames;
  return [
    for (final group in groupOpeningDays(days))
      '${names[group.firstDay]}'
          '${group.lastDay > group.firstDay ? '–${names[group.lastDay]}' : ''} '
          '${group.hours == null ? t.closedDay : hoursText(group.hours!)}',
  ];
}

// Dnešní otevírací doba: "Dnes 8:00–20:00", nebo "Dnes zavřeno".
String todayHoursText(AppLocalizations t, DayHours? hours) =>
    hours == null ? t.closedToday : t.todayHours(hoursText(hours));
