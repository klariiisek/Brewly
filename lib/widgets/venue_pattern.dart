import 'package:flutter/material.dart';

import '../models/venue_settings.dart';
import '../theme/app_theme.dart';

// Jemný vzor v pozadí celé aplikace. Motiv podle typu podniku:
// kavárna = kávová zrnka, cukrárna = posypky, bar = hvězdičky,
// pivnice = bublinky, restaurace = lístky bylinek.
// Barva podniku, skoro průhledná – aby obrazovky nebyly prázdné, ale nerušily.
class VenuePatternPainter extends CustomPainter {
  final VenueType type;
  final Color color;

  VenuePatternPainter({required this.type, required this.color});

  static const double _step = 64;

  @override
  void paint(Canvas canvas, Size size) {
    var row = 0;
    for (var y = _step / 2; y < size.height + _step; y += _step) {
      // Každý druhý řádek posunutý o půl kroku – vzor nepůsobí jako mřížka.
      final offset = row.isEven ? 0.0 : _step / 2;
      var column = 0;
      for (var x = offset; x < size.width + _step; x += _step) {
        // "Náhodné" natočení, které je ale pokaždé stejné (podle pozice),
        // takže vzor při překreslení neposkakuje.
        final seed = (row * 31 + column * 17) % 7;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate((seed - 3) * 0.35);
        _motif(canvas);
        canvas.restore();
        column++;
      }
      row++;
    }
  }

  Paint get _fill => Paint()..color = color;

  Paint _line(double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  void _motif(Canvas canvas) {
    switch (type) {
      case VenueType.kavarna:
        // Kávové zrnko s rýhou uprostřed.
        canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: 13, height: 19),
            _fill);
        final groove = Path()
          ..moveTo(0, -8)
          ..cubicTo(-4, -3, 4, 3, 0, 8);
        canvas.drawPath(
          groove,
          _line(1.6)..color = Colors.white.withValues(alpha: 0.5),
        );
      case VenueType.cukrarna:
        // Posypky: dvě tyčinky a tečka.
        canvas.drawLine(const Offset(-7, -4), const Offset(3, -9), _line(4));
        canvas.drawLine(const Offset(-2, 8), const Offset(9, 5), _line(4));
        canvas.drawCircle(const Offset(8, -2), 2.6, _fill);
      case VenueType.bar:
        // Třpytivá hvězdička se čtyřmi cípy a malá tečka.
        final star = Path()
          ..moveTo(0, -11)
          ..quadraticBezierTo(2, -2, 11, 0)
          ..quadraticBezierTo(2, 2, 0, 11)
          ..quadraticBezierTo(-2, 2, -11, 0)
          ..quadraticBezierTo(-2, -2, 0, -11)
          ..close();
        canvas.drawPath(star, _fill);
        canvas.drawCircle(const Offset(13, -11), 2.2, _fill);
      case VenueType.pivnice:
        // Bublinky různé velikosti.
        canvas.drawCircle(Offset.zero, 7, _line(2));
        canvas.drawCircle(const Offset(11, -9), 3.5, _line(1.8));
        canvas.drawCircle(const Offset(-9, 9), 2.2, _fill);
      case VenueType.restaurace:
        // Lístek bylinky se žilkou.
        final leaf = Path()
          ..moveTo(0, -11)
          ..quadraticBezierTo(9, 0, 0, 11)
          ..quadraticBezierTo(-9, 0, 0, -11)
          ..close();
        canvas.drawPath(leaf, _fill);
        canvas.drawLine(const Offset(0, -8), const Offset(0, 13),
            _line(1.4)..color = Colors.white.withValues(alpha: 0.5));
    }
  }

  @override
  bool shouldRepaint(VenuePatternPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}

// Pozadí stránky: barva pozadí podniku + vzor podle typu podniku.
class PatternedBackground extends StatelessWidget {
  final Widget child;

  const PatternedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.background,
      child: CustomPaint(
        // RepaintBoundary = vzor se nepřekresluje při každé změně obsahu.
        painter: VenuePatternPainter(
          type: VenueScope.of(context).type,
          color: colors.primary.withValues(alpha: 0.06),
        ),
        child: RepaintBoundary(child: child),
      ),
    );
  }
}

// Přechod mezi stránkami, který každé stránce dá vzorované pozadí.
// Díky tomu má vzor celá aplikace – i obrazovky, které přibudou později –
// a nemusí se přidávat do každé obrazovky zvlášť.
class PatternedPageTransitionsBuilder extends PageTransitionsBuilder {
  const PatternedPageTransitionsBuilder();

  static const _inner = ZoomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _inner.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      PatternedBackground(child: child),
    );
  }
}
