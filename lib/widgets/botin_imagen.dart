import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/tema.dart';

/// Foto del producto. Si el producto todavía no tiene fotos (o la foto no
/// carga), dibuja un botín genérico con los colores del producto y la suela
/// que corresponde a su superficie.
class BotinImagen extends StatelessWidget {
  const BotinImagen({
    super.key,
    this.url,
    required this.colores,
    required this.superficie,
    this.fit = BoxFit.contain,
    this.padding = const EdgeInsets.all(12),
  });

  final String? url;
  final List<String> colores;
  final String superficie;
  final BoxFit fit;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final base = colores.isEmpty ? const Color(0xFF424242) : colorDesdeNombre(colores.first);
    final detalle = colores.length > 1
        ? colorDesdeNombre(colores[1])
        : (base.computeLuminance() > 0.5 ? Tema.negro : Colors.white);

    final dibujo = SizedBox.expand(
      child: CustomPaint(
        painter: BotinPainter(colorBase: base, colorDetalle: detalle, superficie: superficie),
      ),
    );

    final direccion = url;
    if (direccion == null || direccion.isEmpty) {
      return Padding(padding: padding, child: dibujo);
    }

    return Padding(
      padding: padding,
      child: Image.network(
        direccion,
        fit: fit,
        // Si el servidor de la foto no permite CORS, usa un <img> común.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (context, child, progreso) {
          if (progreso == null) return child;
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stack) => dibujo,
      ),
    );
  }
}

/// Convierte el nombre de un color ("Verde flúor", "Negro"...) en un Color.
Color colorDesdeNombre(String nombre) {
  final n = nombre.toLowerCase();
  if (n.contains('negro')) return const Color(0xFF1C1C1C);
  if (n.contains('blanco')) return const Color(0xFFF5F5F5);
  if (n.contains('verde')) return Tema.verde;
  if (n.contains('naranja')) return Tema.naranja;
  if (n.contains('rojo')) return const Color(0xFFE53935);
  if (n.contains('celeste')) return const Color(0xFF4FC3F7);
  if (n.contains('azul')) return const Color(0xFF1E40AF);
  if (n.contains('rosa')) return const Color(0xFFF06292);
  if (n.contains('amarillo')) return const Color(0xFFFFD600);
  if (n.contains('dorado')) return const Color(0xFFD4AF37);
  if (n.contains('violeta')) return const Color(0xFF7E57C2);
  if (n.contains('gris') || n.contains('plata')) return const Color(0xFF9E9E9E);
  return const Color(0xFF424242);
}

/// Dibujo vectorial de un botín genérico (sin logos de ninguna marca).
class BotinPainter extends CustomPainter {
  BotinPainter({
    required this.colorBase,
    required this.colorDetalle,
    required this.superficie,
  });

  final Color colorBase;
  final Color colorDetalle;
  final String superficie;

  @override
  void paint(Canvas canvas, Size size) {
    // El dibujo mantiene una proporción de 1,7 : 1 centrada en el espacio.
    final ancho = math.min(size.width, size.height * 1.7) * 0.92;
    final alto = ancho / 1.7;
    final ox = (size.width - ancho) / 2;
    final oy = (size.height - alto) / 2;
    double x(double v) => ox + v * ancho;
    double y(double v) => oy + v * alto;

    final contorno = Color.lerp(colorBase, Colors.black, 0.45)!;
    final esSala = superficie == 'IC';
    final colorSuela = esSala ? const Color(0xFFC68E52) : const Color(0xFF1A1A1A);

    // Sombra
    canvas.drawOval(
      Rect.fromLTRB(x(0.08), y(0.86), x(0.94), y(0.96)),
      Paint()..color = const Color(0x22000000),
    );

    // Tapones / tacos según la superficie
    final pintaTapon = Paint()..color = colorSuela;
    void tapon(double cx, double anchoT, double altoT) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x(cx - anchoT / 2), y(0.79), x(cx + anchoT / 2), y(0.79 + altoT)),
          Radius.circular(ancho * 0.01),
        ),
        pintaTapon,
      );
    }

    switch (superficie) {
      case 'FG':
        for (final cx in [0.12, 0.24, 0.52, 0.66, 0.80]) {
          tapon(cx, 0.05, 0.10);
        }
        break;
      case 'AG':
        for (var i = 0; i < 9; i++) {
          tapon(0.10 + i * 0.095, 0.035, 0.06);
        }
        break;
      case 'MG':
        for (var i = 0; i < 7; i++) {
          tapon(0.11 + i * 0.12, 0.045, 0.08);
        }
        break;
      case 'TF':
        for (var i = 0; i < 16; i++) {
          tapon(0.08 + i * 0.054, 0.025, 0.035);
        }
        break;
      default:
        break;
    }

    // Suela
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x(0.03), y(0.72), x(0.96), y(esSala ? 0.85 : 0.80)),
        Radius.circular(ancho * 0.025),
      ),
      Paint()..color = colorSuela,
    );

    // Capellada
    final capellada = Path()
      ..moveTo(x(0.05), y(0.74))
      ..lineTo(x(0.04), y(0.42))
      ..quadraticBezierTo(x(0.04), y(0.20), x(0.16), y(0.17))
      ..lineTo(x(0.30), y(0.15))
      ..quadraticBezierTo(x(0.36), y(0.30), x(0.47), y(0.31))
      ..lineTo(x(0.63), y(0.40))
      ..quadraticBezierTo(x(0.86), y(0.47), x(0.95), y(0.61))
      ..quadraticBezierTo(x(0.99), y(0.71), x(0.92), y(0.74))
      ..close();
    canvas.drawPath(capellada, Paint()..color = colorBase);

    // Detalles en el color secundario: talonera y franja inferior
    canvas.save();
    canvas.clipPath(capellada);
    final pintaDetalle = Paint()..color = colorDetalle;
    canvas.drawPath(
      Path()
        ..moveTo(x(0.0), y(0.30))
        ..lineTo(x(0.17), y(0.36))
        ..lineTo(x(0.14), y(0.76))
        ..lineTo(x(0.0), y(0.76))
        ..close(),
      pintaDetalle,
    );
    canvas.drawRect(Rect.fromLTRB(x(0.0), y(0.66), x(1.0), y(0.76)), pintaDetalle);
    canvas.restore();

    // Contorno
    canvas.drawPath(
      capellada,
      Paint()
        ..color = contorno
        ..style = PaintingStyle.stroke
        ..strokeWidth = ancho * 0.008
        ..strokeJoin = StrokeJoin.round,
    );

    // Cordones
    final pintaCordon = Paint()
      ..color = colorBase.computeLuminance() > 0.6 ? const Color(0xFF555555) : Colors.white
      ..strokeWidth = ancho * 0.012
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final cx = 0.43 + i * 0.05;
      final cy = 0.33 + i * 0.026;
      canvas.drawLine(Offset(x(cx), y(cy)), Offset(x(cx + 0.03), y(cy + 0.07)), pintaCordon);
    }
  }

  @override
  bool shouldRepaint(covariant BotinPainter old) =>
      old.colorBase != colorBase ||
      old.colorDetalle != colorDetalle ||
      old.superficie != superficie;
}
