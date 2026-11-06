import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'bar_chart.dart' show chartAnimation;

// Barvy pro kategorie v grafu. První dvě jsou barvy podniku (primary,
// accent), další vzniknou „otočením“ odstínu barvy podniku po barevném kruhu
// (HSL). Díky tomu ladí s paletou a po přebarvení podniku se změní i ony.
List<Color> chartColors(AppColors colors, int count) {
  final base = HSLColor.fromColor(colors.primary);
  final result = <Color>[colors.primary, colors.accent];
  for (var index = 1; result.length < count; index++) {
    result.add(base
        .withHue((base.hue + index * 67) % 360)
        .withSaturation(base.saturation.clamp(0.35, 0.6))
        .withLightness(0.55)
        .toColor());
  }
  return result.take(count).toList();
}

// Prstencový („koláčový“) graf: každý díl = jedna kategorie.
// Při načtení se prstenec dokreslí dokola. Uprostřed je text (celková tržba).
class DonutChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final String centerText;
  final String centerLabel;
  final Object animationKey;
  final double size;

  const DonutChart({
    super.key,
    required this.values,
    required this.colors,
    required this.centerText,
    required this.centerLabel,
    required this.animationKey,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(animationKey),
      tween: Tween(begin: 0, end: 1),
      duration: chartAnimation(context),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => CustomPaint(
        size: Size.square(size),
        painter: DonutPainter(
          values: values,
          colors: colors,
          progress: progress,
        ),
        child: child,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                child: Text(
                  centerText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colors.dark,
                  ),
                ),
              ),
              Text(
                centerLabel,
                style: TextStyle(fontSize: 11, color: context.colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double progress;

  DonutPainter({
    required this.values,
    required this.colors,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (sum, value) => sum + value);
    if (total == 0) return;
    const stroke = 20.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - stroke / 2,
    );
    // Malá mezera mezi díly (jen když je dílů víc).
    final gap = values.length > 1 ? 0.04 : 0.0;
    // Začínáme nahoře (−90°) a jdeme po směru hodinových ručiček.
    var start = -math.pi / 2;
    final fullSweep = 2 * math.pi * progress;
    for (var index = 0; index < values.length; index++) {
      final sweep = fullSweep * values[index] / total;
      if (sweep > gap) {
        canvas.drawArc(
          rect,
          start + gap / 2,
          sweep - gap,
          false,
          Paint()
            ..color = colors[index % colors.length]
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.butt,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(DonutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.values != values ||
      oldDelegate.colors != colors;
}
