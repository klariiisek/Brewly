// Seznam ID objednávek, které byly odeslány z tohoto zařízení.
// Podle něj aplikace pozná, které objednávky v databázi jsou "moje".
// Je jen v paměti – po přihlašování se "moje" objednávky budou poznávat podle účtu.
class OrderHistory {
  final List<String> orderIds = [];

  void addOrderId(String id) {
    orderIds.add(id);
  }
}
