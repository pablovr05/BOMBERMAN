import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'SpriteSheet.dart';

class SpriteFrame extends StatelessWidget {
  final SpriteSheet sheet;
  final int row;
  final int column;
  final double scale;

  const SpriteFrame({
    super.key,
    required this.sheet,
    required this.row,
    required this.column,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final frame = sheet.getFrame(row, column);

    return CustomPaint(
      size: Size(frame.width * scale, frame.height * scale),
      painter: _SpritePainter(sheet.image, frame),
    );
  }
}

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final Rect src;

  _SpritePainter(this.image, this.src);

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
