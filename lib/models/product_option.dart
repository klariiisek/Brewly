// Možnosti produktu (varianty): např. skupina „Mléko“ s volbami
// kravské (výchozí), ovesné +15 Kč, sójové +15 Kč.
//
// Skupiny si vytváří admin (kolekce "optionGroups") a u každého produktu
// zapne, které se nabízejí. Zákazník si v detailu produktu z každé skupiny
// vybere jednu volbu; první volba ve skupině je výchozí.

// Jedna volba ve skupině, např. „Ovesné“ za příplatek 15 Kč.
class OptionChoice {
  final String name;
  final double price; // příplatek v Kč (0 = zdarma)

  const OptionChoice({required this.name, this.price = 0});

  factory OptionChoice.fromMap(Map<String, dynamic> data) {
    return OptionChoice(
      name: data['name'] as String? ?? '',
      price: (data['price'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'price': price};
}

// Skupina možností, např. „Mléko“ nebo „Sirup“.
class OptionGroup {
  final String id;
  final String name;

  // Volby; první je výchozí (tu dostane zákazník, když nic nezmění).
  final List<OptionChoice> choices;

  const OptionGroup({
    this.id = '',
    required this.name,
    required this.choices,
  });

  factory OptionGroup.fromMap(String id, Map<String, dynamic> data) {
    final choices = data['choices'] as List<dynamic>? ?? [];
    return OptionGroup(
      id: id,
      name: data['name'] as String? ?? '',
      choices: [
        for (final choice in choices)
          OptionChoice.fromMap(Map<String, dynamic>.from(choice as Map)),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'choices': [for (final choice in choices) choice.toMap()],
      };
}

// Co si zákazník vybral, uložené v košíku a v objednávce, např.
// skupina „Mléko“, volba „Ovesné“, příplatek 15 Kč.
// Ukládá se kopie (jako u ceny produktu), aby se objednávka nezměnila,
// když admin později skupinu upraví nebo smaže.
// Výchozí volby zdarma se neukládají – obsluha vidí jen to, co je jinak
// než obvykle („ovesné mléko“, ne „kravské mléko“ u každé kávy).
class ChosenOption {
  final String group;
  final String choice;
  final double price;

  const ChosenOption({
    required this.group,
    required this.choice,
    this.price = 0,
  });

  factory ChosenOption.fromMap(Map<String, dynamic> data) {
    return ChosenOption(
      group: data['group'] as String? ?? '',
      choice: data['choice'] as String? ?? '',
      price: (data['price'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() =>
      {'group': group, 'choice': choice, 'price': price};

  // Pro zákazníka i obsluhu: „Mléko: Ovesné“.
  String get label => '$group: $choice';

  @override
  bool operator ==(Object other) =>
      other is ChosenOption &&
      other.group == group &&
      other.choice == choice &&
      other.price == price;

  @override
  int get hashCode => Object.hash(group, choice, price);
}

// Z vybraných voleb (index volby v každé skupině) udělá seznam pro košík.
// Výchozí volby (index 0) zdarma se vynechají.
List<ChosenOption> chosenOptions(
  List<OptionGroup> groups,
  List<int> selected,
) {
  return [
    for (var i = 0; i < groups.length; i++)
      if (selected[i] > 0 || groups[i].choices[selected[i]].price != 0)
        ChosenOption(
          group: groups[i].name,
          choice: groups[i].choices[selected[i]].name,
          price: groups[i].choices[selected[i]].price,
        ),
  ];
}
