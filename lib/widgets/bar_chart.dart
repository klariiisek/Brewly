import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sales_stats.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

// Délka animace grafů. Když má uživatel v systému vypnuté animace,
// grafy se ukážou hned (stejně jako pára nad šálkem na úvodu).
Duration chartAnimation(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 800);

// Sloupcový graf tržeb, kreslený vlastním CustomPainterem (bez balíčku).
// - sloupce při načtení „vyrostou“ ze země,
// - klepnutím na sloupec se ukáže bublina s detailem (den, tržba, objednávky),
// - bez výběru má nejvyšší sloupec nad sebou částku.
class BarChart extends StatefulWidget {
  final List<ChartBar> bars;

  // Když se změní (např. jiné období), animace proběhne znovu.
  final Object animationKey;

  const BarChart({super.key, required this.bars, required this.animationKey});

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> {
  // Vybraný sloupec (null = žádný).
  int? selected;

  static const double chartHeight = 230;

  @override
  void didUpdateWidget(BarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jiné období = jiné sloupce → výběr zrušíme.
    if (oldWidget.animationKey != widget.animationKey) selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final slot = width / widget.bars.length;

        return GestureDetector(
          // Klepnutí: podle polohy prstu zjistíme, na který sloupec to bylo.
          onTapDown: (details) {
            final index = (details.localPosition.dx / slot)
                .floor()
                .clamp(0, widget.bars.length - 1);
            setState(() => selected = selected == index ? null : index);
          },
          child: TweenAnimationBuilder<double>(
            key: ValueKey(widget.animationKey),
            tween: Tween(begin: 0, end: 1),
            duration: chartAnimation(context),
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) {
              return SizedBox(
                height: chartHeight,
                width: width,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BarChartPainter(
                          bars: widget.bars,
                          progress: progress,
                          selected: selected,
                          barColor: colors.primary.withValues(alpha: 0.35),
                          highlightColor: colors.primary,
                          textColor: colors.muted,
                          valueColor: colors.dark,
                        ),
                      ),
                    ),
                    if (selected != null) buildBubble(selected!, slot, width),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Bublina nad vybraným sloupcem. Nevyleze přes okraj grafu.
  Widget buildBubble(int index, double slot, double width) {
    const bubbleWidth = 150.0;
    final bar = widget.bars[index];
    final centerX = slot * index + slot / 2;
    final left = (centerX - bubbleWidth / 2).clamp(0.0, width - bubbleWidth);

    return Positioned(
      left: left,
      top: 0,
      width: bubbleWidth,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.strong,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bar.title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                formatPrice(bar.value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                formatOrderCount(bar.count),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<ChartBar> bars;
  final double progress; // 0 = sloupce nulové, 1 = plná výška (animace)
  final int? selected;
  final Color barColor;
  final Color highlightColor;
  final Color textColor;
  final Color valueColor;

  BarChartPainter({
    required this.bars,
    required this.progress,
    required this.selected,
    required this.barColor,
    required this.highlightColor,
    required this.textColor,
    required this.valueColor,
  });

  // Napíše krátký text tak, aby jeho střed byl na [center] – ale nevyleze
  // přes levý ani pravý okraj grafu.
  void _text(Canvas canvas, Size size, String text, Offset center, Color color,
      {double fontSize = 11, FontWeight weight = FontWeight.w400}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: appFont,
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final left = (center.dx - painter.width / 2)
        .clamp(0.0, math.max(0.0, size.width - painter.width))
        .toDouble();
    painter.paint(canvas, Offset(left, center.dy - painter.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const labelHeight = 18.0; // místo pro popisky dole
    const topSpace = 86.0; // místo pro bublinu nad sloupci
    final chartHeight = size.height - labelHeight - topSpace;
    final slot = size.width / bars.length;
    final barWidth = math.min(slot * 0.65, 28.0);
    final maxValue = bars.map((bar) => bar.value).reduce(math.max);
    final baseline = topSpace + chartHeight;

    // Základní čára.
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      Paint()
        ..color = textColor.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // U mnoha sloupců (měsíc) popíšeme jen každý pátý, aby se texty nepřekrývaly.
    final labelEvery = bars.length > 16 ? 5 : 1;

    for (var index = 0; index < bars.length; index++) {
      final bar = bars[index];
      final centerX = slot * index + slot / 2;
      final isMax = maxValue > 0 && bar.value == maxValue;
      // Zvýrazněný je vybraný sloupec; bez výběru ten nejvyšší.
      final isHighlighted = selected == null ? isMax : selected == index;

      // Vybraný sloupec má jemné pozadí přes celou výšku.
      if (selected == index) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(centerX - slot / 2 + 1, topSpace - 6, slot - 2,
                chartHeight + 6),
            const Radius.circular(6),
          ),
          Paint()..color = highlightColor.withValues(alpha: 0.08),
        );
      }

      if (bar.value > 0) {
        // Výška podle poměru k nejvyšší hodnotě (aspoň 3 px) × průběh animace.
        final height =
            math.max(chartHeight * bar.value / maxValue, 3.0) * progress;
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(centerX - barWidth / 2, baseline - height, barWidth,
              height),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(
          rect,
          Paint()..color = isHighlighted ? highlightColor : barColor,
        );
        if (isMax && selected == null && progress == 1) {
          _text(canvas, size, formatPrice(bar.value),
              Offset(centerX, baseline - height - 10), valueColor,
              weight: FontWeight.w600);
        }
      }

      if (index % labelEvery == 0 || index == bars.length - 1) {
        _text(canvas, size, bar.label,
            Offset(centerX, size.height - labelHeight / 2),
            selected == index ? valueColor : textColor,
            fontSize: 10,
            weight: selected == index ? FontWeight.w700 : FontWeight.w400);
      }
    }
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) =>
      oldDelegate.bars != bars ||
      oldDelegate.progress != progress ||
      oldDelegate.selected != selected ||
      oldDelegate.highlightColor != highlightColor;
}
