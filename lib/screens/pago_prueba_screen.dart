import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../models/pedido.dart';
import '../services/notificaciones_service.dart';
import '../services/pedidos_service.dart';
import '../utils/formato.dart';
import '../widgets/comunes.dart';
import 'pedido_detalle_screen.dart';

/// Pago SIMULADO de Mercado Pago (modo prueba).
///
/// Se usa cuando no hay credenciales configuradas. Reproduce los tres
/// resultados posibles de un pago (aprobado, pendiente, rechazado) para poder
/// probar todo el circuito sin cobrar dinero. Está marcado como prueba en
/// toda la pantalla.
class PagoPruebaScreen extends StatefulWidget {
  const PagoPruebaScreen({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  State<PagoPruebaScreen> createState() => _PagoPruebaScreenState();
}

class _PagoPruebaScreenState extends State<PagoPruebaScreen> {
  final _pedidos = PedidosService();
  late final Stream<Pedido?> _stream = _pedidos.pedido(widget.pedidoId);

  String _resultadoElegido = EstadosPago.aprobado;
  bool _procesando = false;
  String? _resultadoFinal;
  bool? _mailEnviado;

  Future<void> _pagar() async {
    setState(() => _procesando = true);
    try {
      // Pequeña espera para simular la comunicación con el procesador de pagos.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final referencia = 'PRUEBA-${DateTime.now().millisecondsSinceEpoch}';
      await _pedidos.registrarPago(widget.pedidoId, _resultadoElegido, referencia);

      bool? mail;
      if (_resultadoElegido == EstadosPago.aprobado) {
        final actualizado = await _pedidos.obtener(widget.pedidoId);
        if (actualizado != null) {
          mail = await NotificacionesService().enviarConfirmacionSiCorresponde(actualizado);
        }
      }
      if (!mounted) return;
      setState(() {
        _resultadoFinal = _resultadoElegido;
        _mailEnviado = mail;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar el pago: $e')),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _verPedido() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PedidoDetalleScreen(pedidoId: widget.pedidoId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago con Mercado Pago'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: EtiquetaChica('MODO PRUEBA', fondo: Tema.naranja)),
          ),
        ],
      ),
      body: StreamBuilder<Pedido?>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error al leer el pedido: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final pedido = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _resultadoFinal != null
                    ? _resultado(pedido)
                    : (pedido.puedePagar ? _formulario(pedido) : _yaProcesado(pedido)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formulario(Pedido pedido) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFFFF3E0),
          child: const Text(
            'Esta es una simulación. No hay credenciales de Mercado Pago configuradas, '
            'así que no se cobra dinero. Elegí qué resultado querés simular: son los '
            'mismos estados que devuelve Mercado Pago con sus tarjetas de prueba.',
          ),
        ),
        const SizedBox(height: 24),
        Text('PEDIDO #${pedido.numeroCorto}', style: Tema.etiqueta()),
        const SizedBox(height: 4),
        Text(precioArs(pedido.total), style: Tema.titulo(56)),
        Text('${pedido.cantidadProductos} productos', style: const TextStyle(color: Tema.grisTexto)),
        const SizedBox(height: 24),
        Text('RESULTADO A SIMULAR', style: Tema.etiqueta(color: Tema.negro)),
        const SizedBox(height: 8),
        _OpcionResultado(
          titulo: 'Pago aprobado',
          detalle: 'Como pagar con una tarjeta de prueba aprobada.',
          icono: Icons.check_circle_outline,
          color: Tema.verdeOk,
          seleccionada: _resultadoElegido == EstadosPago.aprobado,
          alPresionar: () => setState(() => _resultadoElegido = EstadosPago.aprobado),
        ),
        _OpcionResultado(
          titulo: 'Pago pendiente',
          detalle: 'El pago queda en revisión (por ejemplo, pago en efectivo).',
          icono: Icons.schedule,
          color: Tema.naranja,
          seleccionada: _resultadoElegido == EstadosPago.pendiente,
          alPresionar: () => setState(() => _resultadoElegido = EstadosPago.pendiente),
        ),
        _OpcionResultado(
          titulo: 'Pago rechazado',
          detalle: 'La tarjeta rechaza el pago. Podés volver a intentar.',
          icono: Icons.cancel_outlined,
          color: Tema.rojo,
          seleccionada: _resultadoElegido == EstadosPago.rechazado,
          alPresionar: () => setState(() => _resultadoElegido = EstadosPago.rechazado),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _procesando ? null : _pagar,
          child: _procesando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text('PAGAR ${precioArs(pedido.total)} (SIMULADO)'),
        ),
        TextButton(onPressed: _verPedido, child: const Text('Pagar más tarde')),
      ],
    );
  }

  Widget _resultado(Pedido pedido) {
    late final IconData icono;
    late final Color color;
    late final String titulo;
    late final String texto;

    switch (_resultadoFinal) {
      case EstadosPago.aprobado:
        icono = Icons.check_circle;
        color = Tema.verdeOk;
        titulo = '¡COMPRA CONFIRMADA!';
        texto = _mailEnviado == true
            ? 'Te enviamos el detalle a ${pedido.email}.'
            : 'Tu pago se aprobó. (El mail de confirmación no se envió: revisá la configuración de EmailJS.)';
        break;
      case EstadosPago.pendiente:
        icono = Icons.schedule;
        color = Tema.naranja;
        titulo = 'PAGO PENDIENTE';
        texto = 'Tu pedido está reservado. Te avisamos cuando se acredite el pago.';
        break;
      default:
        icono = Icons.cancel;
        color = Tema.rojo;
        titulo = 'PAGO RECHAZADO';
        texto = 'No se cobró nada. Podés reintentar el pago desde el detalle del pedido.';
    }

    return Column(
      children: [
        Icon(icono, color: color, size: 96),
        const SizedBox(height: 16),
        Text(titulo, textAlign: TextAlign.center, style: Tema.titulo(48)),
        const SizedBox(height: 8),
        Text(texto, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Pedido #${pedido.numeroCorto}', style: const TextStyle(color: Tema.grisTexto)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            FilledButton(onPressed: _verPedido, child: const Text('VER MI PEDIDO')),
            OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('SEGUIR COMPRANDO'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _yaProcesado(Pedido pedido) {
    return Column(
      children: [
        const Icon(Icons.info_outline, size: 64),
        const SizedBox(height: 12),
        Text('ESTE PEDIDO NO ESPERA PAGO', style: Tema.titulo(36), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        EstadoChip.pedido(pedido.estado),
        const SizedBox(height: 24),
        FilledButton(onPressed: _verPedido, child: const Text('VER PEDIDO')),
      ],
    );
  }
}

class _OpcionResultado extends StatelessWidget {
  const _OpcionResultado({
    required this.titulo,
    required this.detalle,
    required this.icono,
    required this.color,
    required this.seleccionada,
    required this.alPresionar,
  });

  final String titulo;
  final String detalle;
  final IconData icono;
  final Color color;
  final bool seleccionada;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: alPresionar,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: seleccionada ? color : Tema.grisBorde,
              width: seleccionada ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(seleccionada ? Icons.radio_button_checked : Icons.radio_button_unchecked),
              const SizedBox(width: 12),
              Icon(icono, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(detalle, style: const TextStyle(fontSize: 13, color: Tema.grisTexto)),
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
