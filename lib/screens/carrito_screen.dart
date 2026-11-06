import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../models/item_carrito.dart';
import '../models/producto.dart';
import '../providers/carrito_provider.dart';
import '../services/cupones_service.dart';
import '../services/envio_service.dart';
import '../utils/formato.dart';
import '../utils/navegacion.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/botin_imagen.dart';
import '../widgets/comunes.dart';
import 'checkout_screen.dart';

/// Carrito: modificar cantidades, eliminar, aplicar cupón y ver totales.
class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final _codigoCtrl = TextEditingController();
  bool _validandoCupon = false;
  String? _errorCupon;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _aplicarCupon() async {
    // Los cupones solo se pueden leer con sesión iniciada (reglas de Firestore).
    if (!await asegurarSesion(context)) return;
    if (!mounted) return;
    final carrito = context.read<CarritoProvider>();
    setState(() {
      _validandoCupon = true;
      _errorCupon = null;
    });
    try {
      final cupon = await CuponesService().validar(_codigoCtrl.text, carrito.subtotal);
      carrito.aplicarCupon(cupon);
      _codigoCtrl.clear();
    } on CuponException catch (e) {
      if (mounted) setState(() => _errorCupon = e.mensaje);
    } catch (e) {
      if (mounted) setState(() => _errorCupon = 'No se pudo validar el cupón: $e');
    } finally {
      if (mounted) setState(() => _validandoCupon = false);
    }
  }

  Future<void> _iniciarCompra() async {
    if (!await asegurarSesion(context)) return;
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    final productos = context.watch<List<Producto>?>();

    // Si cambió algún precio en el catálogo, se actualiza el carrito.
    if (productos != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<CarritoProvider>().sincronizarPrecios(productos);
      });
    }

    if (carrito.estaVacio) {
      return Scaffold(
        appBar: const BarraNavegacion(),
        body: EstadoVacio(
          icono: Icons.shopping_bag_outlined,
          titulo: 'TU CARRITO ESTÁ VACÍO',
          texto: 'Elegí tus próximos botines y volvé acá para comprar.',
          textoBoton: 'VER BOTINES',
          alPresionar: () => irACatalogo(context),
        ),
      );
    }

    // Problemas de stock con el catálogo actual (otro cliente compró, etc.).
    final problemas = <String, String>{};
    for (final item in carrito.items) {
      final p = buscarProducto(productos, item.productoId);
      if (productos == null) break;
      if (p == null || !p.activo) {
        problemas[item.clave] = 'Ya no está disponible. Eliminalo para continuar.';
      } else if (p.stockDe(item.talle) < item.cantidad) {
        final quedan = p.stockDe(item.talle);
        problemas[item.clave] = quedan == 0
            ? 'Se agotó el talle ${item.talle}.'
            : 'Solo quedan $quedan en talle ${item.talle}.';
      }
    }

    return Scaffold(
      appBar: const BarraNavegacion(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final grande = constraints.maxWidth >= 900;
          final lista = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('TU CARRITO (${carrito.cantidadTotal})', style: Tema.titulo(44)),
              const SizedBox(height: 16),
              for (final item in carrito.items)
                _FilaItem(
                  item: item,
                  stock: buscarProducto(productos, item.productoId)?.stockDe(item.talle),
                  problema: problemas[item.clave],
                ),
            ],
          );
          final resumen = _resumen(carrito, problemas.isNotEmpty);

          return SingleChildScrollView(
            padding: EdgeInsets.all(grande ? 40 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: grande
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: lista),
                          const SizedBox(width: 40),
                          Expanded(flex: 2, child: resumen),
                        ],
                      )
                    : Column(children: [lista, const SizedBox(height: 24), resumen]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _resumen(CarritoProvider carrito, bool hayProblemas) {
    final cupon = carrito.cupon;
    final faltaParaEnvioGratis = EnvioService.envioGratisDesde - carrito.totalSinEnvio;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Tema.grisFondo,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('RESUMEN', style: Tema.titulo(30)),
          const SizedBox(height: 16),
          Text('CUPÓN DE DESCUENTO', style: Tema.etiqueta(color: Tema.negro)),
          const SizedBox(height: 8),
          if (cupon == null)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'BIENVENIDA10',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _aplicarCupon(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _validandoCupon ? null : _aplicarCupon,
                  child: _validandoCupon
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('APLICAR'),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Tema.verdeOk),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, color: Tema.verdeOk),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${cupon.codigo} · ${cupon.descripcion}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quitar cupón',
                    icon: const Icon(Icons.close),
                    onPressed: carrito.quitarCupon,
                  ),
                ],
              ),
            ),
          if (_errorCupon != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_errorCupon!, style: const TextStyle(color: Tema.rojo)),
            ),
          if (carrito.avisoCupon != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(carrito.avisoCupon!, style: const TextStyle(color: Tema.naranja)),
            ),
          const SizedBox(height: 20),
          FilaResumen('Subtotal', precioArs(carrito.subtotal)),
          if (carrito.descuento > 0)
            FilaResumen(
              'Descuento',
              '- ${precioArs(carrito.descuento)}',
              colorValor: Tema.verdeOk,
            ),
          const FilaResumen('Envío', 'Se calcula en el siguiente paso'),
          const Divider(height: 24),
          FilaResumen('Total', precioArs(carrito.totalSinEnvio), destacado: true),
          const SizedBox(height: 8),
          Text(
            faltaParaEnvioGratis > 0
                ? 'Te faltan ${precioArs(faltaParaEnvioGratis)} para el envío gratis.'
                : '¡Tenés envío gratis!',
            style: TextStyle(
              color: faltaParaEnvioGratis > 0 ? Tema.grisTexto : Tema.verdeOk,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: hayProblemas ? null : _iniciarCompra,
            child: const Text('INICIAR COMPRA'),
          ),
          if (hayProblemas)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Corregí los productos marcados en rojo para continuar.',
                style: TextStyle(color: Tema.rojo),
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => irACatalogo(context),
            child: const Text('Seguir comprando'),
          ),
        ],
      ),
    );
  }
}

class _FilaItem extends StatelessWidget {
  const _FilaItem({required this.item, required this.stock, required this.problema});

  final ItemCarrito item;
  final int? stock; // null = catálogo todavía cargando
  final String? problema;

  @override
  Widget build(BuildContext context) {
    final carrito = context.read<CarritoProvider>();
    final puedeSumar = stock == null || item.cantidad < stock!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: problema == null ? Tema.grisBorde : Tema.rojo),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => irAProducto(context, item.productoId),
            child: Container(
              width: 96,
              height: 96,
              color: Tema.grisFondo,
              child: BotinImagen(
                url: item.imagen,
                colores: item.colores,
                superficie: item.superficie,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.marca.toUpperCase(), style: Tema.etiqueta(tamanio: 11)),
                Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Talle ${item.talle} · ${precioArs(item.precio)} c/u',
                  style: const TextStyle(color: Tema.grisTexto),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Tema.grisBorde),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Restar',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: () =>
                                carrito.cambiarCantidad(item.clave, item.cantidad - 1),
                          ),
                          Text(
                            '${item.cantidad}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            tooltip: puedeSumar ? 'Sumar' : 'No hay más stock',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: puedeSumar
                                ? () => carrito.cambiarCantidad(item.clave, item.cantidad + 1)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => carrito.eliminar(item.clave),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Eliminar'),
                    ),
                  ],
                ),
                if (problema != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      problema!,
                      style: const TextStyle(color: Tema.rojo, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            precioArs(item.subtotal),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
