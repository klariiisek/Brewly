import 'dart:math';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/text.dart';
import 'product_card.dart';

// Vlastní ikony nápojů. Nejsou to obrázky – aplikace je sama kreslí
// (CustomPainter): obrys šálku nebo sklenice a uvnitř barevné vrstvy
// (káva, mléko, pěna…). Obrys má barvu podniku, takže se ikony přebarví
// spolu s aplikací.
enum DrinkIcon {
  espresso('Espresso'),
  doppio('Doppio'),
  macchiato('Macchiato'),
  cappuccino('Cappuccino'),
  flatWhite('Flat white'),
  latte('Latte'),
  americano('Americano'),
  frappe('Frappé'),
  takeaway('S sebou'),
  tea('Čaj'),
  hotChocolate('Čokoláda'),
  lemonade('Limonáda'),
  cake('Dezert');

  final String label;

  const DrinkIcon(this.label);
}

// Když admin ikonu nevybere, odhadneme ji podle názvu (a kategorie).
// Hledá části slov bez diakritiky, např. "Ledové latte" → latte.
DrinkIcon? guessDrinkIcon(String name, String category) {
  final text = normalizeText('$name $category');
  final nameText = normalizeText(name);
  const rules = [
    (['frappe', 'ledov', 'iced', 'cold brew'], DrinkIcon.frappe),
    (['s sebou', 'take away', 'takeaway'], DrinkIcon.takeaway),
    (['doppio', 'double', 'dvojit'], DrinkIcon.doppio),
    (['flat white'], DrinkIcon.flatWhite),
    (['cappuccino', 'kapucin'], DrinkIcon.cappuccino),
    (['latte'], DrinkIcon.latte),
    (['macchiato'], DrinkIcon.macchiato),
    (['americano', 'lungo', 'filtr', 'prekapav'], DrinkIcon.americano),
    (['espresso', 'ristretto', 'kava'], DrinkIcon.espresso),
    (['cokolad', 'chocolate', 'kakao'], DrinkIcon.hotChocolate),
    (['caj', 'tea', 'matcha'], DrinkIcon.tea),
    (['limonad', 'dzus', 'juice', 'fresh', 'voda', 'napoj', 'soda'],
        DrinkIcon.lemonade),
    (['dort', 'cheesecake', 'tiramisu', 'dezert', 'kolac', 'brownie',
      'muffin', 'zakusek', 'sladk'], DrinkIcon.cake),
  ];
  // Nejdřív podle názvu produktu, pak i podle kategorie.
  for (final source in [nameText, text]) {
    for (final (words, icon) in rules) {
      if (words.any(source.contains)) return icon;
    }
  }
  return null;
}

// Najde ikonu produktu: vybranou adminem, nebo odhadnutou podle názvu.
DrinkIcon? drinkIconOf(Product product) {
  for (final icon in DrinkIcon.values) {
    if (icon.name == product.icon) return icon;
  }
  return guessDrinkIcon(product.name, product.category);
}

// Ikona produktu ve čtverečku s kulatými rohy (karta, detail, košík).
// Když se k produktu žádná nakreslená ikona nehodí (např. jídlo),
// použije se obyčejná ikona podle kategorie.
class ProductIcon extends StatelessWidget {
  final Product product;
  final double size;

  const ProductIcon({super.key, required this.product, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final drink = drinkIconOf(product);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: drink != null
          ? DrinkIconView(icon: drink)
          : Icon(
              categoryIcon(product.category),
              color: context.colors.primary,
              size: size * 0.5,
            ),
    );
  }
}

// Samotná nakreslená ikona (bez pozadí) – používá se i ve výběru ikon.
class DrinkIconView extends StatelessWidget {
  final DrinkIcon icon;
  final double? size;

  const DrinkIconView({super.key, required this.icon, this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: DrinkPainter(
          icon: icon,
          outline: context.colors.dark,
          accent: context.colors.primary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kreslení. Všechny souřadnice jsou v rozsahu 0–1 (0 = levý/horní okraj,
// 1 = pravý/dolní), takže ikona vypadá stejně v jakékoli velikosti.
// ---------------------------------------------------------------------------

// Barvy náplní – stejné ve všech paletách, aby káva vypadala jako káva.
const _coffee = Color(0xFF5B3418);
const _crema = Color(0xFFB57A43);
const _milkCoffee = Color(0xFFC89A6A);
const _milk = Color(0xFFF6E9D7);
const _foam = Color(0xFFFFFBF4);
const _water = Color(0xFFD9EEF6);
const _tea = Color(0xFFD99432);
const _chocolate = Color(0xFF6E3B22);
const _lemonade = Color(0xFFFFF0A8);
const _lemon = Color(0xFFF4D03F);
const _sponge = Color(0xFFE6BC78);
const _cherry = Color(0xFFC0392B);

// Vrstva nápoje: barva a výška (podíl výšky nádoby, odspodu).
typedef _Layer = (Color color, double height);

class DrinkPainter extends CustomPainter {
  final DrinkIcon icon;
  final Color outline; // barva obrysu (tmavá barva podniku)
  final Color accent; // hlavní barva podniku (brčko, kelímek, čajová visačka)

  DrinkPainter({
    required this.icon,
    required this.outline,
    required this.accent,
  });

  late double _s; // velikost plátna

  Offset _p(double x, double y) => Offset(x * _s, y * _s);

  Paint get _stroke => Paint()
    ..color = outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = _s * 0.045
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _fill(Color color) => Paint()..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    _s = size.shortestSide;
    switch (icon) {
      case DrinkIcon.espresso:
        _smallCup(canvas, [(_coffee, 0.62), (_crema, 0.12)]);
      case DrinkIcon.doppio:
        _cup(canvas, [(_coffee, 0.7), (_crema, 0.12)], steam: true);
      case DrinkIcon.macchiato:
        _smallCup(canvas, [(_coffee, 0.5), (_foam, 0.28)]);
      case DrinkIcon.cappuccino:
        _cup(canvas, [(_coffee, 0.4), (_milkCoffee, 0.25), (_foam, 0.27)],
            steam: true);
      case DrinkIcon.hotChocolate:
        _cup(canvas, [(_chocolate, 0.85)], steam: false, whipped: true);
      case DrinkIcon.tea:
        _cup(canvas, [(_tea, 0.8)], steam: true, teaTag: true);
      case DrinkIcon.flatWhite:
        _glass(canvas, [(_coffee, 0.22), (_milkCoffee, 0.38), (_foam, 0.06)],
            steam: true);
      case DrinkIcon.latte:
        _glass(canvas, [(_milk, 0.42), (_coffee, 0.2), (_foam, 0.24)]);
      case DrinkIcon.americano:
        _glass(canvas, [(_coffee, 0.36), (_water, 0.4)], steam: true);
      case DrinkIcon.frappe:
        _glass(canvas, [(_coffee, 0.38), (_milkCoffee, 0.48)],
            whipped: true, straw: true);
      case DrinkIcon.lemonade:
        _glass(canvas, [(_lemonade, 0.78)], straw: true, lemon: true);
      case DrinkIcon.takeaway:
        _takeaway(canvas);
      case DrinkIcon.cake:
        _cake(canvas);
    }
  }

  // Vybarví vrstvy uvnitř nádoby (ořezané jejím tvarem), odspodu nahoru.
  void _layers(Canvas canvas, Path vessel, double top, double bottom,
      List<_Layer> layers) {
    canvas.save();
    canvas.clipPath(vessel);
    var y = bottom;
    final height = bottom - top;
    for (final (color, part) in layers) {
      final layerTop = y - height * part;
      canvas.drawRect(
        Rect.fromLTRB(0, layerTop * _s, _s, y * _s),
        _fill(color),
      );
      y = layerTop;
    }
    canvas.restore();
  }

  // Pára nad horkým nápojem: tři vlnky.
  void _steam(Canvas canvas, double centerX, double bottomY) {
    final paint = _stroke
      ..color = outline.withValues(alpha: 0.45)
      ..strokeWidth = _s * 0.035;
    for (final dx in [-0.09, 0.0, 0.09]) {
      final x = centerX + dx;
      final path = Path()
        ..moveTo(x * _s, bottomY * _s)
        ..cubicTo((x - 0.04) * _s, (bottomY - 0.05) * _s, (x + 0.04) * _s,
            (bottomY - 0.09) * _s, x * _s, (bottomY - 0.14) * _s);
      canvas.drawPath(path, paint);
    }
  }

  // Šálek s ouškem a podšálkem.
  void _cup(Canvas canvas, List<_Layer> layers,
      {bool steam = false, bool whipped = false, bool teaTag = false}) {
    const left = 0.16, right = 0.70, top = 0.42, bottom = 0.80;
    final vessel = Path()
      ..moveTo(left * _s, top * _s)
      ..lineTo(left * _s, 0.52 * _s)
      ..cubicTo(left * _s, 0.74 * _s, 0.30 * _s, bottom * _s, 0.43 * _s,
          bottom * _s)
      ..cubicTo(0.56 * _s, bottom * _s, right * _s, 0.74 * _s, right * _s,
          0.52 * _s)
      ..lineTo(right * _s, top * _s)
      ..close();

    if (steam) _steam(canvas, 0.43, 0.36);
    // Podšálek.
    final saucer = Rect.fromLTRB(0.06 * _s, 0.80 * _s, 0.80 * _s, 0.90 * _s);
    canvas.drawOval(saucer, _fill(Colors.white));
    canvas.drawOval(saucer, _stroke);
    // Ouško.
    final handle = Path()
      ..moveTo(right * _s, 0.48 * _s)
      ..cubicTo(0.88 * _s, 0.44 * _s, 0.90 * _s, 0.68 * _s, 0.66 * _s,
          0.68 * _s);
    canvas.drawPath(handle, _stroke);

    canvas.drawPath(vessel, _fill(Colors.white));
    _layers(canvas, vessel, top, bottom, layers);
    if (whipped) {
      // Šlehačka nad okrajem.
      final cream = Path()
        ..moveTo(left * _s, top * _s)
        ..cubicTo(left * _s, 0.26 * _s, right * _s, 0.26 * _s, right * _s,
            top * _s)
        ..close();
      canvas.drawPath(cream, _fill(_foam));
      canvas.drawPath(cream, _stroke);
    }
    canvas.drawPath(vessel, _stroke);
    if (teaTag) {
      // Provázek a visačka čajového sáčku přes levý okraj.
      final string = Path()
        ..moveTo(0.36 * _s, 0.50 * _s)
        ..lineTo(0.22 * _s, 0.36 * _s)
        ..lineTo(0.08 * _s, 0.42 * _s)
        ..lineTo(0.08 * _s, 0.56 * _s);
      canvas.drawPath(string, _stroke..strokeWidth = _s * 0.025);
      final tag = RRect.fromLTRBR(0.02 * _s, 0.56 * _s, 0.14 * _s,
          0.70 * _s, Radius.circular(0.02 * _s));
      canvas.drawRRect(tag, _fill(accent));
    }
  }

  // Menší šálek (espresso, macchiato) – stejný tvar, jen zmenšený.
  void _smallCup(Canvas canvas, List<_Layer> layers) {
    canvas.save();
    canvas.translate(0.08 * _s, 0.14 * _s);
    canvas.scale(0.84);
    _cup(canvas, layers, steam: true);
    canvas.restore();
  }

  // Vysoká sklenice (latte, frappé, limonáda…).
  void _glass(Canvas canvas, List<_Layer> layers,
      {bool steam = false,
      bool whipped = false,
      bool straw = false,
      bool lemon = false}) {
    const top = 0.20, bottom = 0.90;
    final vessel = Path()
      ..moveTo(0.28 * _s, top * _s)
      ..lineTo(0.72 * _s, top * _s)
      ..lineTo(0.67 * _s, 0.86 * _s)
      ..quadraticBezierTo(0.665 * _s, bottom * _s, 0.62 * _s, bottom * _s)
      ..lineTo(0.38 * _s, bottom * _s)
      ..quadraticBezierTo(0.335 * _s, bottom * _s, 0.33 * _s, 0.86 * _s)
      ..close();

    if (steam) _steam(canvas, 0.50, 0.15);
    if (straw) {
      canvas.drawLine(_p(0.58, 0.40), _p(0.70, 0.02),
          _stroke..color = accent..strokeWidth = _s * 0.06);
    }
    canvas.drawPath(vessel, _fill(Colors.white));
    _layers(canvas, vessel, top, bottom, layers);
    if (whipped) {
      final cream = Path()
        ..moveTo(0.26 * _s, top * _s)
        ..cubicTo(0.26 * _s, 0.02 * _s, 0.74 * _s, 0.02 * _s, 0.74 * _s,
            top * _s)
        ..close();
      canvas.drawPath(cream, _fill(_foam));
      canvas.drawPath(cream, _stroke);
    }
    canvas.drawPath(vessel, _stroke);
    if (lemon) {
      // Plátek citronu na okraji sklenice.
      final center = _p(0.30, 0.22);
      canvas.drawCircle(center, 0.10 * _s, _fill(_lemon));
      canvas.drawCircle(center, 0.10 * _s, _stroke..strokeWidth = _s * 0.03);
      for (final angle in [0.0, 1.05, 2.1]) {
        final dx = 0.07 * _s * cos(angle), dy = 0.07 * _s * sin(angle);
        canvas.drawLine(center.translate(-dx, -dy), center.translate(dx, dy),
            _stroke..strokeWidth = _s * 0.02);
      }
    }
  }

  // Papírový kelímek s víčkem a barevným páskem.
  void _takeaway(Canvas canvas) {
    final body = Path()
      ..moveTo(0.28 * _s, 0.30 * _s)
      ..lineTo(0.72 * _s, 0.30 * _s)
      ..lineTo(0.66 * _s, 0.92 * _s)
      ..lineTo(0.34 * _s, 0.92 * _s)
      ..close();
    canvas.drawPath(body, _fill(Colors.white));
    // Pásek uprostřed v barvě podniku.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(Rect.fromLTRB(0, 0.50 * _s, _s, 0.70 * _s), _fill(accent));
    canvas.restore();
    canvas.drawPath(body, _stroke);
    // Víčko.
    final lid = RRect.fromLTRBR(0.22 * _s, 0.20 * _s, 0.78 * _s, 0.31 * _s,
        Radius.circular(0.03 * _s));
    canvas.drawRRect(lid, _fill(outline));
    final lidTop = RRect.fromLTRBR(0.34 * _s, 0.13 * _s, 0.66 * _s,
        0.21 * _s, Radius.circular(0.03 * _s));
    canvas.drawRRect(lidTop, _fill(outline));
  }

  // Kousek dortu na talířku s třešničkou.
  void _cake(Canvas canvas) {
    const left = 0.16, right = 0.84;
    final slice = RRect.fromLTRBR(left * _s, 0.40 * _s, right * _s,
        0.84 * _s, Radius.circular(0.05 * _s));
    final slicePath = Path()..addRRect(slice);
    canvas.drawPath(slicePath, _fill(_sponge));
    _layers(canvas, slicePath, 0.40, 0.84, [
      (_sponge, 0.36),
      (_foam, 0.12),
      (_sponge, 0.30),
      (_chocolate, 0.22),
    ]);
    canvas.drawPath(slicePath, _stroke);
    // Talířek.
    canvas.drawLine(_p(0.06, 0.90), _p(0.94, 0.90), _stroke);
    // Třešnička se stopkou.
    canvas.drawLine(_p(0.52, 0.30), _p(0.60, 0.18),
        _stroke..strokeWidth = _s * 0.03);
    canvas.drawCircle(_p(0.50, 0.33), 0.075 * _s, _fill(_cherry));
    canvas.drawCircle(_p(0.50, 0.33), 0.075 * _s,
        _stroke..strokeWidth = _s * 0.03);
  }

  @override
  bool shouldRepaint(DrinkPainter oldDelegate) =>
      oldDelegate.icon != icon ||
      oldDelegate.outline != outline ||
      oldDelegate.accent != accent;
}
