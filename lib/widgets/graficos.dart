import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/tema.dart';

class DatoGrafico {
  const DatoGrafico(this.etiqueta, this.valor);
  final String etiqueta;
  final double valor;
}

/// Gráfico de barras verticales hecho con widgets (sin librerías externas).
class BarrasVerticales extends StatelessWidget {
  const BarrasVerticales({
    super.key,
    required this.datos,
    required this.formato,
    this.color = Tema.negro,
    this.alto = 170,
  });

  final List<DatoGrafico> datos;
  final String Function(double) formato;
  final Color color;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final maximo = datos.fold<double>(0, (m, d) => math.max(m, d.valor));
    return SizedBox(
      height: alto + 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in datos)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formato(d.valor),
                        style: const TextStyle(fontSize: 11, color: Tema.grisTexto),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: maximo == 0 ? 0 : d.valor / maximo),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Container(
                        height: math.max(2.0, v * alto),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(d.etiqueta, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gráfico de barras horizontales (rankings: más vendidos, stock por marca...).
class BarrasHorizontales extends StatelessWidget {
  const BarrasHorizontales({
    super.key,
    required this.datos,
    required this.formato,
    this.color = Tema.negro,
  });

  final List<DatoGrafico> datos;
  final String Function(double) formato;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Sin datos todavía.', style: TextStyle(color: Tema.grisTexto)),
      );
    }
    final maximo = datos.fold<double>(0, (m, d) => math.max(m, d.valor));
    return Column(
      children: [
        for (final d in datos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  child: Text(
                    d.etiqueta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 16,
                    color: Tema.grisFondo,
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: maximo == 0 ? 0 : d.valor / maximo),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => FractionallySizedBox(
                        widthFactor: v.clamp(0.0, 1.0).toDouble(),
                        child: Container(color: color),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: Text(
                    formato(d.valor),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
