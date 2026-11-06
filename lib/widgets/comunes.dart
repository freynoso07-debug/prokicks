import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/catalogo.dart';
import '../models/pedido.dart';

/// Logo de texto: PRO + KICKS.
class LogoProKicks extends StatelessWidget {
  const LogoProKicks({super.key, this.tamanio = 28, this.sobreOscuro = true});

  final double tamanio;
  final bool sobreOscuro;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.sports_soccer, color: sobreOscuro ? Tema.verde : Tema.negro, size: tamanio * 0.85),
        const SizedBox(width: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'PRO',
                style: Tema.titulo(tamanio, color: sobreOscuro ? Colors.white : Tema.negro),
              ),
              TextSpan(
                text: 'KICKS',
                style: Tema.titulo(tamanio, color: sobreOscuro ? Tema.verde : Tema.naranja),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Etiqueta rectangular chica (NUEVO, -20%, SIN STOCK...).
class EtiquetaChica extends StatelessWidget {
  const EtiquetaChica(this.texto, {super.key, required this.fondo, this.colorTexto = Colors.white});

  final String texto;
  final Color fondo;
  final Color colorTexto;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(2)),
      child: Text(
        texto,
        style: TextStyle(
          color: colorTexto,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Código de superficie (FG, AG...) con su nombre en el tooltip.
class ChipSuperficie extends StatelessWidget {
  const ChipSuperficie(this.codigo, {super.key});

  final String codigo;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: Catalogo.nombreSuperficie(codigo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Tema.negro),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          codigo,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
      ),
    );
  }
}

/// Chip de color con el estado de un pedido o de un pago.
class EstadoChip extends StatelessWidget {
  const EstadoChip({super.key, required this.texto, required this.color});

  factory EstadoChip.pedido(String estado) {
    const colores = {
      EstadosPedido.pendientePago: Tema.naranja,
      EstadosPedido.pagado: Tema.verdeOk,
      EstadosPedido.preparando: Color(0xFF1565C0),
      EstadosPedido.enviado: Color(0xFF6A1B9A),
      EstadosPedido.entregado: Tema.negro,
      EstadosPedido.cancelado: Tema.rojo,
    };
    return EstadoChip(
      texto: EstadosPedido.nombre(estado),
      color: colores[estado] ?? Tema.grisTexto,
    );
  }

  factory EstadoChip.pago(String estado) {
    const colores = {
      EstadosPago.pendiente: Tema.naranja,
      EstadosPago.aprobado: Tema.verdeOk,
      EstadosPago.rechazado: Tema.rojo,
    };
    return EstadoChip(
      texto: EstadosPago.nombre(estado),
      color: colores[estado] ?? Tema.grisTexto,
    );
  }

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.white, 0.86),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Pantalla vacía con ícono, mensaje y un botón opcional.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.texto,
    this.textoBoton,
    this.alPresionar,
  });

  final IconData icono;
  final String titulo;
  final String? texto;
  final String? textoBoton;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 64, color: Tema.grisTexto),
            const SizedBox(height: 16),
            Text(titulo, textAlign: TextAlign.center, style: Tema.titulo(30)),
            if (texto != null) ...[
              const SizedBox(height: 8),
              Text(
                texto!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Tema.grisTexto),
              ),
            ],
            if (textoBoton != null && alPresionar != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: alPresionar, child: Text(textoBoton!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Título de sección del panel o de formularios.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.tamanio = 28});

  final String texto;
  final double tamanio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(texto, style: Tema.titulo(tamanio)),
    );
  }
}

/// Fila "etiqueta ........ valor" para resúmenes de compra.
class FilaResumen extends StatelessWidget {
  const FilaResumen(this.etiqueta, this.valor, {super.key, this.destacado = false, this.colorValor});

  final String etiqueta;
  final String valor;
  final bool destacado;
  final Color? colorValor;

  @override
  Widget build(BuildContext context) {
    final estilo = destacado
        ? const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)
        : const TextStyle(fontSize: 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: estilo)),
          Text(valor, style: estilo.copyWith(color: colorValor)),
        ],
      ),
    );
  }
}
