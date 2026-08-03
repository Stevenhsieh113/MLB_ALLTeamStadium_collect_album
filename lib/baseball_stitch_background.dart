import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 淡色棒球縫線背景（不影響上層地圖座標）。
class BaseballStitchBackground extends StatelessWidget {
  const BaseballStitchBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _BaseballStitchPainter(),
      size: Size.infinite,
    );
  }
}

class _BaseballStitchPainter extends CustomPainter {
  const _BaseballStitchPainter();

  static const _leather = Color(0xFFF3E6D4);
  static const _stitch = Color(0xFFB71C1C);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _leather);

    // 兩條經典棒球縫線弧（淡、不搶地圖）
    _drawSeam(
      canvas,
      size,
      leftArc: true,
    );
    _drawSeam(
      canvas,
      size,
      leftArc: false,
    );
  }

  void _drawSeam(Canvas canvas, Size size, {required bool leftArc}) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    if (leftArc) {
      path.moveTo(w * 0.08, h * 0.12);
      path.cubicTo(
        w * 0.22,
        h * 0.38,
        w * 0.22,
        h * 0.62,
        w * 0.08,
        h * 0.88,
      );
    } else {
      path.moveTo(w * 0.92, h * 0.12);
      path.cubicTo(
        w * 0.78,
        h * 0.38,
        w * 0.78,
        h * 0.62,
        w * 0.92,
        h * 0.88,
      );
    }

    final seamPaint = Paint()
      ..color = _stitch.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, w * 0.004)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, seamPaint);

    // 沿弧線畫短縫線刻痕
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final tickPaint = Paint()
      ..color = _stitch.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, w * 0.0025)
      ..strokeCap = StrokeCap.round;

    const tickCount = 18;
    final tickLen = math.max(6.0, w * 0.012);

    for (var i = 1; i < tickCount; i++) {
      final distance = metric.length * (i / tickCount);
      final tangent = metric.getTangentForOffset(distance);
      if (tangent == null) continue;

      final pos = tangent.position;
      final angle = tangent.angle + math.pi / 2;
      final dx = math.cos(angle) * tickLen / 2;
      final dy = math.sin(angle) * tickLen / 2;

      canvas.drawLine(
        Offset(pos.dx - dx, pos.dy - dy),
        Offset(pos.dx + dx, pos.dy + dy),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
