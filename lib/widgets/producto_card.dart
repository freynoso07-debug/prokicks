import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../models/producto.dart';
import '../providers/sesion_provider.dart';
import '../utils/formato.dart';
import '../utils/navegacion.dart';
import 'botin_imagen.dart';
import 'comunes.dart';

/// Tarjeta de un botín (catálogo, home, favoritos). Se agranda la foto
/// al pasar el mouse y tiene botón de favorito.
class ProductoCard extends StatefulWidget {
  const ProductoCard({super.key, required this.producto});

  final Producto producto;

  @override
  State<ProductoCard> createState() => _ProductoCardState();
}

class _ProductoCardState extends State<ProductoCard> {
  bool _hover = false;

  Future<void> _alternarFavorito() async {
    if (!await asegurarSesion(context)) return;
    if (!mounted) return;
    try {
      await context.read<SesionProvider>().alternarFavorito(widget.producto.id);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo actualizar favoritos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final favorito = context.watch<SesionProvider>().esFavorito(p.id);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => irAProducto(context, p.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _hover ? Tema.negro : Tema.grisBorde),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  child: Container(
                    color: Tema.grisFondo,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedScale(
                            scale: _hover ? 1.07 : 1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            child: Opacity(
                              opacity: p.sinStock ? 0.45 : 1,
                              child: BotinImagen(
                                url: p.imagenPrincipal,
                                colores: p.colores,
                                superficie: p.superficie,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p.nuevo) const EtiquetaChica('NUEVO', fondo: Tema.negro),
                              if (p.descuento > 0)
                                EtiquetaChica('-${p.descuento}%', fondo: Tema.naranja),
                              if (p.sinStock)
                                const EtiquetaChica('SIN STOCK', fondo: Tema.grisTexto),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton(
                            tooltip: favorito ? 'Quitar de favoritos' : 'Agregar a favoritos',
                            icon: Icon(
                              favorito ? Icons.favorite : Icons.favorite_border,
                              color: favorito ? Tema.naranja : Tema.negro,
                            ),
                            onPressed: _alternarFavorito,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.marca.toUpperCase(), style: Tema.etiqueta(tamanio: 11)),
                    const SizedBox(height: 2),
                    Text(
                      p.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.25),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ChipSuperficie(p.superficie),
                        const Spacer(),
                        if (!p.sinStock && p.stockTotal <= 5)
                          const Text(
                            '¡Últimos pares!',
                            style: TextStyle(
                              color: Tema.naranja,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(
                          precioArs(p.precio),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        if (p.descuento > 0 && p.precioAnterior != null)
                          Text(
                            precioArs(p.precioAnterior!),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Tema.grisTexto,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
