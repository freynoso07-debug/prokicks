import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../models/catalogo.dart';
import '../models/producto.dart';
import '../providers/carrito_provider.dart';
import '../providers/cotizacion_provider.dart';
import '../providers/sesion_provider.dart';
import '../services/envio_service.dart';
import '../utils/formato.dart';
import '../utils/navegacion.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/botin_imagen.dart';
import '../widgets/comunes.dart';
import '../widgets/dialogos_info.dart';
import '../widgets/pie_de_pagina.dart';
import '../widgets/seccion_productos.dart';
import 'carrito_screen.dart';

/// Página individual de un botín (GET /api/products/:id).
/// Se actualiza sola si cambia el stock o el precio en Firestore.
class ProductoScreen extends StatefulWidget {
  const ProductoScreen({super.key, required this.productoId});

  final String productoId;

  @override
  State<ProductoScreen> createState() => _ProductoScreenState();
}

class _ProductoScreenState extends State<ProductoScreen> {
  String? _talle;
  int _cantidad = 1;
  int _foto = 0;
  String? _error;

  void _agregar(Producto p) {
    final talle = _talle;
    if (talle == null) {
      setState(() => _error = 'Elegí un talle.');
      return;
    }
    final error = context.read<CarritoProvider>().agregar(p, talle, _cantidad);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _error = null;
      _cantidad = 1;
    });
    mostrarMensaje(
      context,
      'Agregaste ${p.nombre} (talle $talle) al carrito.',
      accion: SnackBarAction(
        label: 'VER CARRITO',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CarritoScreen()),
        ),
      ),
    );
  }

  Future<void> _alternarFavorito(Producto p) async {
    if (!await asegurarSesion(context)) return;
    if (!mounted) return;
    await context.read<SesionProvider>().alternarFavorito(p.id);
  }

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<List<Producto>?>();
    final p = buscarProducto(todos, widget.productoId);

    if (todos == null) {
      return const Scaffold(
        appBar: BarraNavegacion(),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (p == null || !p.activo) {
      return Scaffold(
        appBar: const BarraNavegacion(),
        body: EstadoVacio(
          icono: Icons.search_off,
          titulo: 'PRODUCTO NO DISPONIBLE',
          texto: 'Este botín ya no está en el catálogo.',
          textoBoton: 'VER CATÁLOGO',
          alPresionar: () => irACatalogo(context),
        ),
      );
    }

    // Si el talle elegido se quedó sin stock (otra persona compró), se deselecciona.
    final talle = _talle;
    if (talle != null && p.stockDe(talle) <= 0) _talle = null;

    final relacionados = todos
        .where((x) => x.activo && x.id != p.id && x.superficie == p.superficie)
        .take(10)
        .toList();

    return Scaffold(
      appBar: const BarraNavegacion(),
      body: ListView(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final grande = constraints.maxWidth >= 900;
              final galeria = _galeria(p);
              final info = _info(p);
              return Padding(
                padding: EdgeInsets.all(grande ? 40 : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: grande
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: galeria),
                              const SizedBox(width: 48),
                              Expanded(flex: 5, child: info),
                            ],
                          )
                        : Column(children: [galeria, const SizedBox(height: 24), info]),
                  ),
                ),
              );
            },
          ),
          SeccionProductos(
            titulo: 'TAMBIÉN TE PUEDE GUSTAR',
            subtitulo: 'Más botines ${p.superficie} · ${Catalogo.nombreSuperficie(p.superficie)}',
            productos: relacionados,
          ),
          const PieDePagina(),
        ],
      ),
    );
  }

  Widget _galeria(Producto p) {
    final indice = p.imagenes.isEmpty ? 0 : _foto.clamp(0, p.imagenes.length - 1).toInt();
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            color: Tema.grisFondo,
            child: Stack(
              children: [
                Positioned.fill(
                  child: BotinImagen(
                    url: p.imagenes.isEmpty ? null : p.imagenes[indice],
                    colores: p.colores,
                    superficie: p.superficie,
                    padding: const EdgeInsets.all(32),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.nuevo) const EtiquetaChica('NUEVO', fondo: Tema.negro),
                      if (p.descuento > 0) EtiquetaChica('-${p.descuento}%', fondo: Tema.naranja),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (p.imagenes.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: p.imagenes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _foto = i),
                child: Container(
                  width: 84,
                  decoration: BoxDecoration(
                    color: Tema.grisFondo,
                    border: Border.all(
                      color: i == indice ? Tema.negro : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: BotinImagen(
                    url: p.imagenes[i],
                    colores: p.colores,
                    superficie: p.superficie,
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _info(Producto p) {
    final favorito = context.watch<SesionProvider>().esFavorito(p.id);
    final usd = context.watch<CotizacionProvider>().enUsd(p.precio);
    final talle = _talle;
    final stockTalle = talle == null ? 0 : p.stockDe(talle);
    final enCarrito =
        talle == null ? 0 : context.watch<CarritoProvider>().cantidadEnCarrito(p.id, talle);
    final maximo = talle == null ? 1 : (stockTalle - enCarrito).clamp(1, 99).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.marca.toUpperCase(), style: Tema.etiqueta(tamanio: 13)),
        const SizedBox(height: 6),
        Text(p.nombre.toUpperCase(), style: Tema.titulo(44)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChipSuperficie(p.superficie),
            Text(Catalogo.nombreSuperficie(p.superficie)),
            Text('SKU ${p.sku}', style: const TextStyle(color: Tema.grisTexto, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              precioArs(p.precio),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            if (p.descuento > 0 && p.precioAnterior != null) ...[
              Text(
                precioArs(p.precioAnterior!),
                style: const TextStyle(
                  fontSize: 18,
                  color: Tema.grisTexto,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              EtiquetaChica('${p.descuento}% OFF', fondo: Tema.naranja),
            ],
          ],
        ),
        Text(
          '6 cuotas sin interés de ${precioArs(p.precio / 6)}'
          '${usd == null ? '' : ' · ≈ ${precioUsd(usd)} (dólar oficial)'}',
          style: const TextStyle(color: Tema.grisTexto),
        ),
        if (p.colores.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('COLORES', style: Tema.etiqueta(color: Tema.negro)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final c in p.colores)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: colorDesdeNombre(c),
                        shape: BoxShape.circle,
                        border: Border.all(color: Tema.grisBorde),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(c),
                  ],
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Text('ELEGÍ TU TALLE (AR)', style: Tema.etiqueta(color: Tema.negro)),
            const Spacer(),
            TextButton(
              onPressed: () => mostrarGuiaTalles(context),
              child: const Text('Guía de talles'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in p.talles) _BotonTalle(
              talle: t,
              stock: p.stockDe(t),
              seleccionado: t == talle,
              alPresionar: () => setState(() {
                _talle = t;
                _cantidad = 1;
                _error = null;
              }),
            ),
          ],
        ),
        if (talle != null && stockTalle <= 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              stockTalle == 1
                  ? '¡Queda la última unidad en talle $talle!'
                  : '¡Quedan solo $stockTalle unidades en talle $talle!',
              style: const TextStyle(color: Tema.naranja, fontWeight: FontWeight.w700),
            ),
          ),
        if (p.sinStock)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Sin stock por el momento.',
              style: TextStyle(color: Tema.rojo, fontWeight: FontWeight.w700),
            ),
          ),
        const SizedBox(height: 20),
        Text('CANTIDAD', style: Tema.etiqueta(color: Tema.negro)),
        const SizedBox(height: 8),
        _SelectorCantidad(
          valor: _cantidad,
          maximo: maximo,
          alCambiar: (v) => setState(() => _cantidad = v),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: const TextStyle(color: Tema.rojo)),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: p.sinStock ? null : () => _agregar(p),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(p.sinStock ? 'SIN STOCK' : 'AGREGAR AL CARRITO'),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              width: 56,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => _alternarFavorito(p),
                child: Icon(
                  favorito ? Icons.favorite : Icons.favorite_border,
                  color: favorito ? Tema.naranja : Tema.negro,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _Garantias(),
        const SizedBox(height: 24),
        Text('DESCRIPCIÓN', style: Tema.etiqueta(color: Tema.negro)),
        const SizedBox(height: 8),
        Text(p.descripcion, style: const TextStyle(height: 1.6)),
      ],
    );
  }
}

class _BotonTalle extends StatelessWidget {
  const _BotonTalle({
    required this.talle,
    required this.stock,
    required this.seleccionado,
    required this.alPresionar,
  });

  final String talle;
  final int stock;
  final bool seleccionado;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    final disponible = stock > 0;
    return Tooltip(
      message: disponible ? '$stock disponibles' : 'Sin stock',
      child: InkWell(
        onTap: disponible ? alPresionar : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 58,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: seleccionado ? Tema.negro : Colors.white,
            border: Border.all(color: disponible ? Tema.negro : Tema.grisBorde),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            talle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: seleccionado
                  ? Colors.white
                  : (disponible ? Tema.negro : Tema.grisBorde),
              decoration: disponible ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorCantidad extends StatelessWidget {
  const _SelectorCantidad({required this.valor, required this.maximo, required this.alCambiar});

  final int valor;
  final int maximo;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Tema.grisBorde),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Restar',
            onPressed: valor > 1 ? () => alCambiar(valor - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$valor',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Sumar',
            onPressed: valor < maximo ? () => alCambiar(valor + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _Garantias extends StatelessWidget {
  const _Garantias();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.local_shipping_outlined, EnvioService.textoEnvioGratis),
      (Icons.autorenew, 'Cambio de talle gratis durante 30 días'),
      (Icons.verified_user_outlined, 'Pago protegido con Mercado Pago'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      color: Tema.grisFondo,
      child: Column(
        children: [
          for (final i in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(i.$1, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(i.$2)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
