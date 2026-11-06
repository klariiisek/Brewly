import 'order.dart';

// Razítková karta: za každý kus z vybrané kategorie (např. Káva) dostane
// zákazník razítko. „Každá 10. káva zdarma“ = zákazník nasbírá 9 razítek
// a desátou kávu má zdarma (na kartě je 10 políček, poslední je dárek).
//
// Razítka se nikam neukládají – počítají se z objednávek zákazníka
// (jako SUM v SQL). Počítají se jen DOKONČENÉ objednávky a stav
// „dokončena“ smí nastavit jen obsluha, takže si nikdo razítka nepřidá.
class LoyaltyStatus {
  // Kolikátý kus je zdarma (např. 10 = každá 10. káva).
  final int goal;

  // Kolik razítek má zákazník teď (získaná minus spotřebovaná na odměny).
  final int stamps;

  const LoyaltyStatus({required this.goal, required this.stamps});

  // Kolik razítek je potřeba na odměnu (o jedno méně – poslední kus je zdarma).
  int get needed => goal - 1;

  // Má plnou kartu – může si vybrat odměnu?
  bool get hasReward => stamps >= needed;

  // Kolik políček na kartě je orazítkovaných (nejvýš všechna před dárkem).
  int get filled => stamps.clamp(0, needed);

  // Kolik razítek chybí do odměny.
  int get missing => (needed - stamps).clamp(0, needed);
}

// Kolik razítek dala jedna dokončená objednávka (kus zdarma razítko nedává).
int stampsEarned(Order order, String categoryId) {
  if (order.status != OrderStatus.dokoncena) return 0;
  var earned = 0;
  for (final item in order.items) {
    if (item.product.categoryId == categoryId) earned += item.quantity;
  }
  if (order.hasReward && order.rewardItem?.product.categoryId == categoryId) {
    earned--;
  }
  return earned;
}

// Kolik razítek odměna v objednávce spotřebovala. Každá objednávka si
// pamatuje počet platný v době objednání (rewardStamps) – když admin
// později počet změní, staré odměny se tím nepřepočítají.
int stampsSpent(Order order, int goal) {
  if (!order.hasReward) return 0;
  return order.rewardStamps > 0 ? order.rewardStamps : goal - 1;
}

// Spočítá razítka zákazníka z jeho objednávek – postupně podle času,
// jako by obsluha razítkovala skutečnou kartičku.
LoyaltyStatus loyaltyStatus(
  List<Order> orders, {
  required String categoryId,
  required int goal,
}) {
  final sorted = [...orders]..sort((a, b) => a.time.compareTo(b.time));
  var stamps = 0;
  for (final order in sorted) {
    if (order.hasReward) {
      // Starší odměny (z doby před uložením rewardStamps) kartu
      // jen vynulují – nevíme, kolik razítek tehdy stály.
      stamps = order.rewardStamps > 0 ? stamps - order.rewardStamps : 0;
    }
    stamps += stampsEarned(order, categoryId);
  }
  return LoyaltyStatus(goal: goal, stamps: stamps);
}

// Měl zákazník na odměnu v objednávce [order] opravdu plnou kartu?
// Počítají se jen objednávky vytvořené PŘED ní (pozdější nákupy
// neoprávněnou odměnu dodatečně „neomluví“).
bool isRewardValid(
  List<Order> orders,
  Order order, {
  required String categoryId,
  required int goal,
}) {
  final before = orders
      .where((other) => other.id != order.id && other.time.isBefore(order.time))
      .toList();
  final status = loyaltyStatus(before, categoryId: categoryId, goal: goal);
  return status.stamps >= stampsSpent(order, goal);
}
