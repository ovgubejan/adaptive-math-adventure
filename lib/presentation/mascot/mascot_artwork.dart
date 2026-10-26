import 'package:flutter/material.dart';

import 'mascot_state.dart';

class MascotArtwork extends StatelessWidget {
  const MascotArtwork({super.key, required this.state});

  final MascotState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CustomPaint(
      size: const Size(190, 190),
      painter: _MascotPainter(
        state: state,
        bodyColor: colors.primary,
        detailColor: colors.onPrimary,
        cheekColor: colors.tertiary,
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  const _MascotPainter({
    required this.state,
    required this.bodyColor,
    required this.detailColor,
    required this.cheekColor,
  });

  final MascotState state;
  final Color bodyColor;
  final Color detailColor;
  final Color cheekColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 190;
    final bodyPaint = Paint()..color = bodyColor;
    final detailPaint = Paint()..color = detailColor;
    final cheekPaint = Paint()..color = cheekColor.withValues(alpha: 0.8);
    final strokePaint = Paint()
      ..color = detailColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, 72 * scale, bodyPaint);
    canvas.drawCircle(
      center.translate(-49 * scale, -48 * scale),
      25 * scale,
      bodyPaint,
    );
    canvas.drawCircle(
      center.translate(49 * scale, -48 * scale),
      25 * scale,
      bodyPaint,
    );

    if (state == MascotState.sleeping) {
      _drawClosedEye(
        canvas,
        center.translate(-27 * scale, -7 * scale),
        scale,
        strokePaint,
      );
      _drawClosedEye(
        canvas,
        center.translate(27 * scale, -7 * scale),
        scale,
        strokePaint,
      );
    } else {
      canvas.drawCircle(
        center.translate(-27 * scale, -7 * scale),
        7 * scale,
        detailPaint,
      );
      canvas.drawCircle(
        center.translate(27 * scale, -7 * scale),
        7 * scale,
        detailPaint,
      );
    }

    if (state != MascotState.sleeping) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(-43 * scale, 19 * scale),
          width: 17 * scale,
          height: 9 * scale,
        ),
        cheekPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(43 * scale, 19 * scale),
          width: 17 * scale,
          height: 9 * scale,
        ),
        cheekPaint,
      );
    }

    final mouthCenter = center.translate(0, 23 * scale);
    final mouthPath = Path();
    switch (state) {
      case MascotState.idle:
        mouthPath.moveTo(mouthCenter.dx - 11 * scale, mouthCenter.dy);
        mouthPath.quadraticBezierTo(
          mouthCenter.dx,
          mouthCenter.dy + 12 * scale,
          mouthCenter.dx + 11 * scale,
          mouthCenter.dy,
        );
      case MascotState.happy:
        mouthPath.moveTo(
          mouthCenter.dx - 17 * scale,
          mouthCenter.dy - 2 * scale,
        );
        mouthPath.quadraticBezierTo(
          mouthCenter.dx,
          mouthCenter.dy + 24 * scale,
          mouthCenter.dx + 17 * scale,
          mouthCenter.dy - 2 * scale,
        );
      case MascotState.encouraging:
        mouthPath.moveTo(
          mouthCenter.dx - 13 * scale,
          mouthCenter.dy + 2 * scale,
        );
        mouthPath.quadraticBezierTo(
          mouthCenter.dx,
          mouthCenter.dy + 17 * scale,
          mouthCenter.dx + 13 * scale,
          mouthCenter.dy + 2 * scale,
        );
      case MascotState.sleeping:
        mouthPath.moveTo(
          mouthCenter.dx - 7 * scale,
          mouthCenter.dy + 5 * scale,
        );
        mouthPath.quadraticBezierTo(
          mouthCenter.dx,
          mouthCenter.dy - 3 * scale,
          mouthCenter.dx + 7 * scale,
          mouthCenter.dy + 5 * scale,
        );
    }
    canvas.drawPath(mouthPath, strokePaint);
  }

  void _drawClosedEye(Canvas canvas, Offset center, double scale, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - 9 * scale, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy + 9 * scale,
        center.dx + 9 * scale,
        center.dy,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MascotPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.bodyColor != bodyColor ||
      oldDelegate.detailColor != detailColor ||
      oldDelegate.cheekColor != cheekColor;
}
