import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models/analytics.dart';

/// A segmented donut chart drawn with a [CustomPainter].
///
/// Using a hand-rolled painter keeps the visual language consistent with the
/// rest of the app and avoids a heavy charting dependency.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    this.size = 168,
    this.strokeWidth = 22,
    this.gap = 0.035,
    this.center,
  });

  final List<DonutSegment> segments;
  final double size;
  final double strokeWidth;
  final double gap;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: Size.square(size),
                painter: _DonutPainter(
                  segments: segments,
                  total: total,
                  strokeWidth: strokeWidth,
                  gap: gap,
                  progress: progress,
                  emptyColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              ?center,
            ],
          );
        },
      ),
    );
  }
}

class DonutSegment {
  const DonutSegment({required this.value, required this.color});

  final double value;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.total,
    required this.strokeWidth,
    required this.gap,
    required this.progress,
    required this.emptyColor,
  });

  final List<DonutSegment> segments;
  final double total;
  final double strokeWidth;
  final double gap;
  final double progress;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    final arcRect = rect.deflate(inset);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = emptyColor;

    if (total <= 0) {
      canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, base);
      return;
    }

    // Faint track behind the data.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = emptyColor.withValues(alpha: 0.5);
    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);

    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = (segment.value / total) * math.pi * 2 * progress;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = segment.color;
      final adjusted = math.max(sweep - gap, 0.001);
      canvas.drawArc(arcRect, start + gap / 2, adjusted, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress ||
      old.segments != segments ||
      old.total != total;
}

/// A grouped bar chart comparing income and expenses per month.
class GroupedBarChart extends StatelessWidget {
  const GroupedBarChart({
    super.key,
    required this.points,
    required this.incomeColor,
    required this.expenseColor,
    required this.labelBuilder,
    this.height = 190,
  });

  final List<MonthlyPoint> points;
  final Color incomeColor;
  final Color expenseColor;
  final String Function(DateTime) labelBuilder;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _BarPainter(
              points: points,
              incomeColor: incomeColor,
              expenseColor: expenseColor,
              progress: progress,
              gridColor: theme.colorScheme.outline.withValues(alpha: 0.5),
              labelColor: theme.colorScheme.onSurfaceVariant,
              labelBuilder: labelBuilder,
            ),
          );
        },
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.points,
    required this.incomeColor,
    required this.expenseColor,
    required this.progress,
    required this.gridColor,
    required this.labelColor,
    required this.labelBuilder,
  });

  final List<MonthlyPoint> points;
  final Color incomeColor;
  final Color expenseColor;
  final double progress;
  final Color gridColor;
  final Color labelColor;
  final String Function(DateTime) labelBuilder;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const labelHeight = 24.0;
    final chartHeight = size.height - labelHeight;

    final maxValue = points.fold<double>(
      1,
      (max, p) => math.max(max, math.max(p.income, p.expense)),
    );
    final roundedMax = _niceMax(maxValue);

    // Horizontal grid lines.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const gridLines = 4;
    for (var i = 0; i <= gridLines; i++) {
      final y = chartHeight * (i / gridLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final slotWidth = size.width / points.length;
    final barWidth = math.min(slotWidth * 0.26, 16.0);
    const barGap = 5.0;

    final incomePaint = Paint()..color = incomeColor;
    final expensePaint = Paint()..color = expenseColor;

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final centerX = slotWidth * i + slotWidth / 2;

      final incomeHeight =
          (point.income / roundedMax) * (chartHeight - 10) * progress;
      final expenseHeight =
          (point.expense / roundedMax) * (chartHeight - 10) * progress;

      final incomeRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          centerX - barWidth - barGap / 2,
          chartHeight - incomeHeight,
          barWidth,
          incomeHeight,
        ),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
      );
      final expenseRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          centerX + barGap / 2,
          chartHeight - expenseHeight,
          barWidth,
          expenseHeight,
        ),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
      );

      canvas.drawRRect(incomeRect, incomePaint);
      canvas.drawRRect(expenseRect, expensePaint);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: labelBuilder(point.month),
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(
          centerX - labelPainter.width / 2,
          chartHeight + 8,
        ),
      );
    }
  }

  double _niceMax(double value) {
    if (value <= 0) return 1;
    final magnitude = math.pow(10, (math.log(value) / math.ln10).floor());
    final normalized = value / magnitude;
    final step = normalized <= 1
        ? 1
        : normalized <= 2
            ? 2
            : normalized <= 5
                ? 5
                : 10;
    return (step * magnitude).toDouble();
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.progress != progress || old.points != points;
}
