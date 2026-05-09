import 'package:flutter/material.dart';
import '../services/hand_detector.dart';

class HandOverlayPainter extends CustomPainter {
  final List<HandBoundingBox> boxes;
  final String? label;
  final double confidence;
  final bool hasDetection;
  final int imageWidth;   // ← nouveau
  final int imageHeight;  // ← nouveau

  HandOverlayPainter({
    required this.boxes,
    required this.label,
    required this.confidence,
    required this.hasDetection,
    required this.imageWidth,   // ← nouveau
    required this.imageHeight,  // ← nouveau
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Facteurs de mise à l'échelle image caméra → taille écran
    final double scaleX = size.width  / imageWidth;
    final double scaleY = size.height / imageHeight;

    for (int i = 0; i < boxes.length; i++) {
      final box = boxes[i];
      // Box mise à l'échelle
      final scaledBox = HandBoundingBox(
        left:   box.left   * scaleX,
        top:    box.top    * scaleY,
        width:  box.width  * scaleX,
        height: box.height * scaleY,
      );
      _drawHandBox(canvas, size, scaledBox, i == 0);
    }
  }

  void _drawHandBox(Canvas canvas, Size size, HandBoundingBox box, bool isPrimary) {
    final color = isPrimary
        ? (hasDetection ? const Color(0xFF00F5A0) : const Color(0xFF6C63FF))
        : const Color(0xFFFFB347);

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTRB(box.left, box.top, box.right, box.bottom);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, borderPaint);

    _drawCornerAccents(canvas, rect, color);

    if (label != null && isPrimary) {
      _drawLabel(canvas, rect, label!, confidence, color);
    }

    if (isPrimary && hasDetection) {
      _drawConfidenceBar(canvas, rect, confidence, color);
    }
  }

  void _drawCornerAccents(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const len = 20.0;
    canvas.drawLine(Offset(rect.left, rect.top + len), Offset(rect.left, rect.top), paint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + len, rect.top), paint);
    canvas.drawLine(Offset(rect.right - len, rect.top), Offset(rect.right, rect.top), paint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + len), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom - len), Offset(rect.left, rect.bottom), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + len, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right - len, rect.bottom), Offset(rect.right, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - len), paint);
  }

  void _drawLabel(Canvas canvas, Rect rect, String label, double conf, Color color) {
    const double padH = 14, padV = 8;
    final bgPaint = Paint()..color = color.withOpacity(0.92);

    final letterPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          fontFamily: 'SpaceMono',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final confPainter = TextPainter(
      text: TextSpan(
        text: '${(conf * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'SpaceMono',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final totalW = letterPainter.width + confPainter.width + padH * 3;
    final totalH = letterPainter.height + padV * 2;
    final badgeTop = rect.top - totalH - 6;
    if (badgeTop < 0) return;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, badgeTop, totalW, totalH),
        const Radius.circular(8),
      ),
      bgPaint,
    );
    letterPainter.paint(canvas, Offset(rect.left + padH, badgeTop + padV));
    confPainter.paint(canvas,
        Offset(rect.left + padH + letterPainter.width + padH, badgeTop + padV + 8));
  }

  void _drawConfidenceBar(Canvas canvas, Rect rect, double conf, Color color) {
    const barH = 4.0;
    final barY = rect.bottom + 8;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, barY, rect.width, barH),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withOpacity(0.15),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, barY, rect.width * conf, barH),
        const Radius.circular(2),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(HandOverlayPainter old) =>
      old.label != label ||
      old.confidence != confidence ||
      old.boxes.length != boxes.length ||
      old.imageWidth != imageWidth ||
      old.imageHeight != imageHeight;
}