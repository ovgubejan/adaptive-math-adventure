import 'package:flutter/material.dart';

import '../../style/palette.dart';
import '../application/parent_progress.dart';
import 'family_widgets.dart';

/// Son oturumların doğruluk yüzdesini gösteren basit çizgi grafik.
/// Ek paket kullanmaz; doğrudan çizilir.
class AccuracyChart extends StatelessWidget {
  final List<SessionPoint> points;

  const AccuracyChart({required this.points, super.key});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Grafik, ilk oturum tamamlandığında görünecek.',
          textAlign: TextAlign.center,
        ),
      );
    }
    final palette = Palette();
    final first = points.first;
    final last = points.last;
    return Semantics(
      label:
          'Son ${points.length} oturumun doğruluk grafiği. '
          'İlk oturum yüzde ${first.accuracyPercent.round()}, '
          'son oturum yüzde ${last.accuracyPercent.round()}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 180,
            child: CustomPaint(
              key: const ValueKey('accuracy-chart'),
              painter: _AccuracyChartPainter(
                values: [for (final point in points) point.accuracyPercent],
                lineColor: palette.darkPen,
                gridColor: palette.ink.withValues(alpha: 0.2),
                labelColor: palette.inkFullOpacity,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDate(first.completedAt),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                formatDate(last.completedAt),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccuracyChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  _AccuracyChartPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });

  static const double _leftPadding = 44;
  static const double _verticalPadding = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = _leftPadding;
    final chartRight = size.width - 8;
    final chartTop = _verticalPadding;
    final chartBottom = size.height - _verticalPadding;
    final chartHeight = chartBottom - chartTop;
    final chartWidth = chartRight - chartLeft;
    if (chartHeight <= 0 || chartWidth <= 0) return;

    double yFor(double percent) =>
        chartBottom - (percent.clamp(0, 100) / 100) * chartHeight;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final percent in const [0.0, 50.0, 100.0]) {
      final y = yFor(percent);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      final label = TextPainter(
        text: TextSpan(
          text: '%${percent.round()}',
          style: TextStyle(color: labelColor, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(chartLeft - label.width - 6, y - label.height / 2),
      );
    }

    double xFor(int index) => values.length == 1
        ? chartLeft + chartWidth / 2
        : chartLeft + chartWidth * index / (values.length - 1);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final point = Offset(xFor(index), yFor(values[index]));
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = lineColor;
    for (var index = 0; index < values.length; index++) {
      canvas.drawCircle(Offset(xFor(index), yFor(values[index])), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_AccuracyChartPainter oldDelegate) =>
      oldDelegate.values.length != values.length ||
      !_sameValues(oldDelegate.values) ||
      oldDelegate.lineColor != lineColor;

  bool _sameValues(List<double> other) {
    for (var index = 0; index < values.length; index++) {
      if (other[index] != values[index]) return false;
    }
    return true;
  }
}
