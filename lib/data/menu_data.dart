import '../models/product.dart';

// Ukázkové menu kavárny. Používá se v testech a pro první nahrání menu
// do databáze (ProductService.uploadSampleMenu). Aplikace čte menu z databáze.
const List<Product> sampleMenu = [
  Product(
    name: 'Espresso',
    price: 45,
    category: 'Káva',
    description: 'Silná a aromatická káva z čerstvě mletých zrn.',
  ),
  Product(
    name: 'Cappuccino',
    price: 65,
    category: 'Káva',
    description: 'Espresso s napěněným mlékem a jemnou mléčnou pěnou.',
  ),
  Product(
    name: 'Latte',
    price: 70,
    category: 'Káva',
    description: 'Jemná káva s větším množstvím teplého mléka.',
  ),
  Product(
    name: 'Cheesecake',
    price: 85,
    category: 'Dezerty',
    description: 'Krémový tvarohový dort na křupavém sušenkovém základu.',
  ),
  Product(
    name: 'Tiramisu',
    price: 90,
    category: 'Dezerty',
    description: 'Italský dezert s mascarpone, kávou a kakaem.',
  ),
  Product(
    name: 'Domácí limonáda',
    price: 55,
    category: 'Nápoje',
    description: 'Osvěžující limonáda s citronem a mátou.',
  ),
];
