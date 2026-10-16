// Česká písmena s diakritikou a jejich verze bez ní.
const _withAccents = 'áčďéěíňóřšťúůýž';
const _withoutAccents = 'acdeeinorstuuyz';

// Převede text na malá písmena bez diakritiky: "Káva" → "kava".
// Díky tomu najde vyhledávání "kava" i "KÁVA".
String normalizeText(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().trim().split('')) {
    final index = _withAccents.indexOf(char);
    buffer.write(index == -1 ? char : _withoutAccents[index]);
  }
  return buffer.toString();
}
