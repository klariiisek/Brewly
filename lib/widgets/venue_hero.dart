import 'dart:math';

import 'package:flutter/material.dart';

import '../models/venue_settings.dart';
import '../theme/app_theme.dart';

// Velká ilustrace na úvodní obrazovce podle typu podniku:
// kavárna = šálek cappuccina s latte art srdíčkem a párou, cukrárna =
// cupcake, bar = koktejl, pivnice = půllitr, restaurace = talíř s poklopem.
// Aplikace ji kreslí sama (CustomPainter), obrys má tmavou barvu podniku.
class VenueHero extends StatefulWidget {
  final VenueType type;
  final double size;

  const VenueHero({super.key, required this.type, this.size = 180});

  @override
  State<VenueHero> createState() => _VenueHeroState();
}

class _VenueHeroState extends State<VenueHero>
    with SingleTickerProviderStateMixin {
  // Pára se jemně vlní dokola (3,2 sekundy jedno „nadechnutí“).
  late final AnimationController steam = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kdo má v telefonu vypnuté animace, uvidí páru v klidu.
    if (MediaQuery.disableAnimationsOf(context)) {
      steam.stop();
    } else if (!steam.isAnimating) {
      steam.repeat();
    }
  }

  @override
  void dispose() {
    steam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: widget.size,
      height: widget.size * 200 / 220,
      child: AnimatedBuilder(
        animation: steam,
        builder: (context, _) => CustomPaint(
          painter: VenueHeroPainter(
            type: widget.type,
            outline: colors.dark,
            steamColor: colors.muted.withValues(alpha: 0.7),
            phase: steam.value,
          ),
        ),
      ),
    );
  }
}

// Kreslí ilustraci. Souřadnice jsou v „plátně“ 220 × 200 bodů
// a přepočítají se na skutečnou velikost (scale).
class VenueHeroPainter extends CustomPainter {
  final VenueType type;
  final Color outline;
  final Color steamColor;
  final double phase; // 0–1, fáze animace páry

  VenueHeroPainter({
    required this.type,
    required this.outline,
    required this.steamColor,
    required this.phase,
  });

  Paint _stroke(double width, [Color? color]) => Paint()
    ..color = color ?? outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _fill(Color color) => Paint()..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 220);
    switch (type) {
      case VenueType.kavarna:
        _coffeeCup(canvas);
      case VenueType.cukrarna:
        _cupcake(canvas);
      case VenueType.bar:
        _cocktail(canvas);
      case VenueType.pivnice:
        _beer(canvas);
      case VenueType.restaurace:
        _plate(canvas);
    }
    canvas.restore();
  }

  // Tři obláčky páry. Každý stoupá, vlní se do stran a nahoře se rozplyne,
  // pak začne znovu dole – s posunem, aby nešly všechny najednou.
  // phase = 0–1 (jedna perioda animace). Když jsou animace vypnuté,
  // phase je 0 a pára je vidět v klidu.
  void _steam(Canvas canvas, List<double> xs, double bottom) {
    final animated = phase > 0;
    for (var i = 0; i < xs.length; i++) {
      // t = kde v životě obláčku jsme (0 = vznik dole, 1 = rozplynutí nahoře).
      final t = animated ? (phase + i / xs.length) % 1 : 0.5;
      final lift = t * 18; // stoupá o 18 bodů
      final sway = sin((t + i * 0.3) * 2 * pi) * 4; // vlnění do stran
      // Průhlednost: rychle se objeví, pomalu zmizí.
      final opacity = t < 0.2 ? t / 0.2 : 1 - (t - 0.2) / 0.8;
      final paint = _stroke(
          5, steamColor.withValues(alpha: steamColor.a * opacity.clamp(0, 1)));
      final x = xs[i] + sway;
      final y = bottom - lift;
      final path = Path()
        ..moveTo(x, y)
        ..cubicTo(x - 10, y - 14, x + 10, y - 22, x, y - 36);
      canvas.drawPath(path, paint);
    }
  }

  void _bean(Canvas canvas, Offset center, double angle, double scale) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(scale);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 18, height: 13),
        _fill(const Color(0xFF5B3418)));
    final groove = Path()
      ..moveTo(-7, 0)
      ..cubicTo(-2, -3, 2, 3, 7, 0);
    canvas.drawPath(groove, _stroke(1.8, const Color(0xFF8A5530)));
    canvas.restore();
  }

  // ---------- Kavárna: šálek cappuccina ----------
  void _coffeeCup(Canvas canvas) {
    _steam(canvas, [86, 110, 134], 60);

    // Stín a podšálek.
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(110, 172), width: 184, height: 40),
        _fill(outline.withValues(alpha: 0.12)));
    final saucer =
        Rect.fromCenter(center: const Offset(110, 164), width: 180, height: 40);
    canvas.drawOval(
      saucer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFEADFD3)],
        ).createShader(saucer),
    );
    canvas.drawOval(saucer, _stroke(4));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(110, 160), width: 112, height: 20),
        _fill(const Color(0xFFEFE3D6)));

    // Ouško (tmavý obrys a světlý vnitřek).
    final handle = Path()
      ..moveTo(168, 98)
      ..cubicTo(200, 92, 204, 138, 162, 140);
    canvas.drawPath(handle, _stroke(13));
    canvas.drawPath(handle, _stroke(5, const Color(0xFFF6EFE7)));

    // Tělo šálku se stínováním zleva doprava.
    final body = Path()
      ..moveTo(46, 86)
      ..cubicTo(46, 136, 72, 162, 110, 162)
      ..cubicTo(148, 162, 174, 136, 174, 86)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Color(0xFFFBF7F2), Color(0xFFE8DCCF)],
          stops: [0, 0.55, 1],
        ).createShader(const Rect.fromLTRB(46, 86, 174, 162)),
    );
    canvas.drawPath(body, _stroke(4.5));
    // Odlesk.
    final shine = Path()
      ..moveTo(60, 100)
      ..cubicTo(62, 124, 72, 140, 86, 148);
    canvas.drawPath(shine, _stroke(6, Colors.white.withValues(alpha: 0.9)));

    // Okraj šálku a pěna s kávovým okrajem.
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(110, 86), width: 128, height: 30),
        _fill(const Color(0xFFFBF6EF)));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(110, 86), width: 128, height: 30),
        _stroke(4.5));
    final foam =
        Rect.fromCenter(center: const Offset(110, 87), width: 110, height: 22);
    canvas.drawOval(
      foam,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF8EE), Color(0xFFF3DFC3), Color(0xFFC58D55)],
          stops: [0, 0.62, 1],
        ).createShader(foam),
    );

    // Latte art srdíčko (hnědé a uvnitř světlé).
    final heart = Path()
      ..moveTo(110, 95)
      ..cubicTo(99, 89, 92, 85, 95, 80.5)
      ..cubicTo(97.5, 77, 104, 77.5, 110, 81.5)
      ..cubicTo(116, 77.5, 122.5, 77, 125, 80.5)
      ..cubicTo(128, 85, 121, 89, 110, 95)
      ..close();
    canvas.drawPath(heart, _fill(const Color(0xFFB97F4A)));
    final innerHeart = Path()
      ..moveTo(110, 92)
      ..cubicTo(103, 88, 99.5, 85.5, 101, 83)
      ..cubicTo(102.5, 81, 106, 81.5, 110, 84)
      ..cubicTo(114, 81.5, 117.5, 81, 119, 83)
      ..cubicTo(120.5, 85.5, 117, 88, 110, 92)
      ..close();
    canvas.drawPath(innerHeart, _fill(const Color(0xFFFFF8EE)));

    // Kávová zrnka vedle podšálku.
    _bean(canvas, const Offset(26, 176), -0.49, 1);
    _bean(canvas, const Offset(196, 178), 0.38, 0.9);
  }

  // ---------- Cukrárna: cupcake ----------
  void _cupcake(Canvas canvas) {
    canvas.translate(10, 4);
    canvas.scale(1.67);
    final wrapper = Path()
      ..moveTo(30, 58)
      ..lineTo(90, 58)
      ..lineTo(82, 98)
      ..lineTo(38, 98)
      ..close();
    canvas.drawPath(wrapper, _fill(const Color(0xFFF6D2A6)));
    for (final x in [48.0, 60.0, 72.0]) {
      canvas.drawLine(
          Offset(x - 2 + (x - 60) * 0.1, 60), Offset(x, 98),
          _stroke(3, const Color(0xFFE2AE78)));
    }
    canvas.drawPath(wrapper, _stroke(4));
    final frosting = Path()
      ..moveTo(26, 60)
      ..cubicTo(20, 46, 34, 36, 44, 40)
      ..cubicTo(46, 24, 74, 24, 76, 40)
      ..cubicTo(86, 36, 100, 46, 94, 60)
      ..close();
    canvas.drawPath(frosting, _fill(const Color(0xFFFBE1EC)));
    canvas.drawPath(frosting, _stroke(4));
    for (final (dx, dy, color) in [
      (46.0, 50.0, const Color(0xFF6B5B95)),
      (62.0, 44.0, const Color(0xFFE6A57E)),
      (76.0, 52.0, const Color(0xFF6B5B95)),
    ]) {
      canvas.drawCircle(Offset(dx, dy), 2.6, _fill(color));
    }
    canvas.drawCircle(const Offset(60, 24), 8, _fill(const Color(0xFFC0392B)));
    canvas.drawCircle(const Offset(60, 24), 8, _stroke(3));
  }

  // ---------- Bar: koktejl ----------
  void _cocktail(Canvas canvas) {
    canvas.translate(10, 4);
    canvas.scale(1.67);
    canvas.drawLine(const Offset(70, 6), const Offset(56, 40), _stroke(3));
    final glass = Path()
      ..moveTo(22, 22)
      ..lineTo(98, 22)
      ..lineTo(60, 64)
      ..close();
    canvas.drawPath(glass, _fill(const Color(0xFFFDE7EF)));
    final drink = Path()
      ..moveTo(33, 34)
      ..lineTo(87, 34)
      ..lineTo(60, 64)
      ..close();
    canvas.drawPath(drink, _fill(const Color(0xFFE8577E)));
    canvas.drawPath(glass, _stroke(4));
    canvas.drawLine(const Offset(60, 64), const Offset(60, 94), _stroke(4));
    canvas.drawLine(const Offset(42, 96), const Offset(78, 96), _stroke(5));
    canvas.drawCircle(const Offset(84, 22), 11, _fill(const Color(0xFF9ACD4A)));
    canvas.drawCircle(const Offset(84, 22), 11, _stroke(3));
    canvas.drawCircle(const Offset(58, 36), 6, _fill(const Color(0xFFC0392B)));
  }

  // ---------- Pivnice: půllitr ----------
  void _beer(Canvas canvas) {
    canvas.translate(10, 4);
    canvas.scale(1.67);
    final handle = Path()
      ..moveTo(82, 44)
      ..cubicTo(100, 44, 100, 82, 82, 82);
    canvas.drawPath(handle, _stroke(7));
    final mug = RRect.fromLTRBAndCorners(30, 30, 82, 102,
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6));
    canvas.drawRRect(mug, _fill(const Color(0xFFF2B84B)));
    canvas.drawRRect(mug, _stroke(4));
    for (final (dx, dy, r) in [(44.0, 62.0, 3.0), (58.0, 78.0, 2.5), (66.0, 54.0, 2.0)]) {
      canvas.drawCircle(Offset(dx, dy), r, _fill(const Color(0xFFFFF3CF)));
    }
    final foam = Path()
      ..moveTo(26, 32)
      ..cubicTo(22, 18, 38, 12, 44, 20)
      ..cubicTo(48, 8, 66, 8, 70, 20)
      ..cubicTo(78, 12, 92, 18, 86, 32)
      ..close();
    canvas.drawPath(foam, _fill(const Color(0xFFFFFAF0)));
    canvas.drawPath(foam, _stroke(4));
  }

  // ---------- Restaurace: talíř s poklopem a příbor ----------
  void _plate(Canvas canvas) {
    canvas.translate(10, 4);
    canvas.scale(1.67);
    canvas.drawOval(Rect.fromCenter(center: const Offset(60, 74), width: 88, height: 32),
        _fill(Colors.white));
    canvas.drawOval(Rect.fromCenter(center: const Offset(60, 74), width: 88, height: 32),
        _stroke(4));
    final cloche = Path()
      ..moveTo(28, 70)
      ..cubicTo(28, 44, 92, 44, 92, 70)
      ..close();
    canvas.drawPath(cloche, _fill(const Color(0xFFE9EEF4)));
    canvas.drawPath(cloche, _stroke(4));
    canvas.drawCircle(const Offset(60, 42), 5, _fill(outline));
    // Vidlička a nůž.
    final fork = Path()
      ..moveTo(12, 30)
      ..lineTo(12, 98)
      ..moveTo(7, 30)
      ..lineTo(7, 42)
      ..quadraticBezierTo(7, 48, 12, 48)
      ..quadraticBezierTo(17, 48, 17, 42)
      ..lineTo(17, 30);
    canvas.drawPath(fork, _stroke(3));
    final knife = Path()
      ..moveTo(108, 30)
      ..cubicTo(100, 34, 100, 50, 108, 52)
      ..lineTo(108, 98);
    canvas.drawPath(knife, _stroke(3));
  }

  @override
  bool shouldRepaint(VenueHeroPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.type != type ||
      oldDelegate.outline != outline;
}
