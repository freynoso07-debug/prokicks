import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/filtros.dart';
import '../models/producto.dart';
import '../utils/navegacion.dart';
import 'producto_card.dart';

/// Fila horizontal de productos con título y "Ver todo".
class SeccionProductos extends StatelessWidget {
  const SeccionProductos({
    super.key,
    required this.titulo,
    required this.productos,
    this.subtitulo,
    this.filtrosVerTodo,
  });

  final String titulo;
  final String? subtitulo;
  final List<Producto> productos;
  final FiltrosCatalogo? filtrosVerTodo;

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) return const SizedBox.shrink();

    final chico = MediaQuery.sizeOf(context).width < 600;
    final anchoTarjeta = chico ? 200.0 : 250.0;
    final filtros = filtrosVerTodo;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: Tema.titulo(chico ? 32 : 44)),
                      if (subtitulo != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitulo!, style: const TextStyle(color: Tema.grisTexto)),
                      ],
                    ],
                  ),
                ),
                if (filtros != null)
                  TextButton(
                    onPressed: () => irACatalogo(context, filtros: filtros),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'VER TODO',
                          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: anchoTarjeta + 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: productos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (_, i) => SizedBox(
                width: anchoTarjeta,
                child: ProductoCard(producto: productos[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
