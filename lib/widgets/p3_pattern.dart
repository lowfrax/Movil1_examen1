import 'package:flutter/material.dart';
import 'package:medinova/p3_theme.dart';

class P3DiagonalPattern extends StatelessWidget {
  final double spacing;
  final double strokeWidth;
  final double opacity;

  const P3DiagonalPattern({
    super.key,
    this.spacing = 18,
    this.strokeWidth = 1.2,
    this.opacity = 0.06,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: CustomPaint(
        painter: _P3DiagonalPainter(
          color1: P3Palette.cobalt.withOpacity(opacity),
          color2: P3Palette.aqua.withOpacity(opacity * 0.8),
          spacing: spacing,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _P3DiagonalPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double spacing;
  final double strokeWidth;

  _P3DiagonalPainter({
    required this.color1,
    required this.color2,
    required this.spacing,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = color1
      ..strokeWidth = strokeWidth;
    final paint2 = Paint()
      ..color = color2
      ..strokeWidth = strokeWidth;

    // Dibujar líneas diagonales en ambas direcciones con leve variación de color
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      // \\ dirección
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint1,
      );
      // // dirección
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
