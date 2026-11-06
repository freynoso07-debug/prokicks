import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../models/pedido.dart';
import '../providers/sesion_provider.dart';
import '../services/notificaciones_service.dart';
import '../services/pago_service.dart';
import '../services/pedidos_service.dart';
import '../utils/formato.dart';
import '../utils/navegacion.dart';
import '../widgets/botin_imagen.dart';
import '../widgets/comunes.dart';
import 'pago_prueba_screen.dart';

/// Detalle de un pedido (GET /api/orders/:id), en tiempo real.
class PedidoDetalleScreen extends StatefulWidget {
  const PedidoDetalleScreen({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  State<PedidoDetalleScreen> createState() => _PedidoDetalleScreenState();
}

class _PedidoDetalleScreenState extends State<PedidoDetalleScreen> {
  final _pedidos = PedidosService();
  final _pago = PagoService();
  late final Stream<Pedido?> _stream = _pedidos.pedido(widget.pedidoId);
  bool _mailIntentado = false;
  bool _procesando = false;

  /// Si el pago se aprobó (por ejemplo, por el webhook de Mercado Pago real)
  /// y todavía no salió el mail, lo manda una sola vez.
  void _revisarMail(Pedido p, String? uidActual) {
    if (_mailIntentado ||
        p.emailEnviado ||
        !p.pagoAprobado ||
        p.uid != uidActual) {
      return;
    }
    _mailIntentado = true;
    NotificacionesService().enviarConfirmacionSiCorresponde(p);
  }

  Future<void> _pagar(Pedido p) async {
    if (_pago.modoPrueba) {
      // pushReplacement: el pago reemplaza a este detalle, y al terminar el pago
      // vuelve a abrir el detalle. Con push quedaban dos detalles apilados y había
      // que tocar "atrás" dos veces.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PagoPruebaScreen(pedidoId: p.id)),
      );
      return;
    }
    setState(() => _procesando = true);
    try {
      await _pago.irAMercadoPago(p.id);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo abrir Mercado Pago: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _cancelar(Pedido p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar el pedido?'),
        content: const Text(
          'Se libera el stock reservado. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _procesando = true);
    try {
      await _pedidos.cancelar(p.id);
      if (mounted) mostrarMensaje(context, 'Pedido cancelado.');
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo cancelar: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<SesionProvider>().usuario?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del pedido')),
      body: StreamBuilder<Pedido?>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EstadoVacio(
              icono: Icons.lock_outline,
              titulo: 'NO SE PUDO ABRIR',
              texto:
                  'No tenés permiso para ver este pedido o no existe.\n${snapshot.error}',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snapshot.data;
          if (p == null) {
            return const EstadoVacio(
              icono: Icons.search_off,
              titulo: 'PEDIDO NO ENCONTRADO',
            );
          }
          _revisarMail(p, uid);
          final esDueno = p.uid == uid;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('PEDIDO #${p.numeroCorto}', style: Tema.titulo(44)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        EstadoChip.pedido(p.estado),
                        EstadoChip.pago(p.estadoPago),
                        if (p.creadoEn != null)
                          Text(
                            fechaHora(p.creadoEn!),
                            style: const TextStyle(color: Tema.grisTexto),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _LineaDeTiempo(estado: p.estado),
                    const SizedBox(height: 24),
                    if (esDueno && (p.puedePagar || p.puedeCancelar))
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (p.puedePagar)
                            FilledButton.icon(
                              onPressed: _procesando ? null : () => _pagar(p),
                              icon: const Icon(Icons.payment),
                              label: Text(
                                p.estadoPago == EstadosPago.rechazado
                                    ? 'REINTENTAR PAGO'
                                    : 'PAGAR AHORA',
                              ),
                            ),
                          if (p.puedeCancelar)
                            OutlinedButton(
                              onPressed: _procesando
                                  ? null
                                  : () => _cancelar(p),
                              child: const Text('CANCELAR PEDIDO'),
                            ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    _Bloque(
                      titulo: 'PRODUCTOS',
                      child: Column(
                        children: [
                          for (final i in p.items)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    color: Tema.grisFondo,
                                    child: BotinImagen(
                                      url: i.imagen,
                                      colores: i.colores,
                                      superficie: i.superficie,
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          i.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Talle ${i.talle} · ${i.cantidad} x ${precioArs(i.precio)} · SKU ${i.sku}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Tema.grisTexto,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    precioArs(i.subtotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    _Bloque(
                      titulo: 'ENTREGA',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.envio.descripcion,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (p.direccion != null) Text(p.direccion!.texto),
                          Text(
                            p.envio.demora,
                            style: const TextStyle(color: Tema.grisTexto),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p.nombre} · ${p.telefono} · ${p.email}',
                            style: const TextStyle(
                              color: Tema.grisTexto,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Bloque(
                      titulo: 'PAGO',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mercado Pago${p.modoPago == 'prueba' ? ' · modo prueba (simulado)' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(EstadosPago.nombre(p.estadoPago)),
                          if (p.referenciaPago != null)
                            Text(
                              'Referencia: ${p.referenciaPago}',
                              style: const TextStyle(
                                color: Tema.grisTexto,
                                fontSize: 13,
                              ),
                            ),
                          if (p.pagoAprobado)
                            Text(
                              p.emailEnviado
                                  ? 'Mail de confirmación enviado.'
                                  : 'Mail de confirmación pendiente.',
                              style: const TextStyle(
                                color: Tema.grisTexto,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _Bloque(
                      titulo: 'TOTAL',
                      child: Column(
                        children: [
                          FilaResumen('Subtotal', precioArs(p.subtotal)),
                          if (p.descuento > 0)
                            FilaResumen(
                              'Cupón ${p.cuponCodigo ?? ''}',
                              '- ${precioArs(p.descuento)}',
                              colorValor: Tema.verdeOk,
                            ),
                          FilaResumen(
                            'Envío',
                            p.envio.costo == 0
                                ? 'Gratis'
                                : precioArs(p.envio.costo),
                          ),
                          const Divider(height: 20),
                          FilaResumen(
                            'Total',
                            precioArs(p.total),
                            destacado: true,
                          ),
                          if (p.cotizacionDolar != null)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Dólar oficial del día: ${precioArs(p.cotizacionDolar!)} '
                                '(≈ ${precioUsd(p.total / p.cotizacionDolar!)})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Tema.grisTexto,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Tema.grisBorde),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: Tema.etiqueta(color: Tema.negro)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Recorrido del pedido: pendiente → pagado → preparando → enviado → entregado.
class _LineaDeTiempo extends StatelessWidget {
  const _LineaDeTiempo({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    if (estado == EstadosPedido.cancelado) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFFFFEBEE),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: Tema.rojo),
            SizedBox(width: 12),
            Expanded(
              child: Text('Este pedido fue cancelado y el stock se liberó.'),
            ),
          ],
        ),
      );
    }
    final actual = EstadosPedido.recorrido.indexOf(estado);
    return Row(
      children: [
        for (var i = 0; i < EstadosPedido.recorrido.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: i <= actual ? Tema.negro : Tema.grisBorde,
                  child: Icon(
                    i <= actual ? Icons.check : Icons.circle,
                    size: i <= actual ? 16 : 8,
                    color: i <= actual ? Tema.verde : Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  EstadosPedido.nombre(EstadosPedido.recorrido[i]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i == actual ? FontWeight.w800 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
