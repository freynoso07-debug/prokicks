import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../models/pedido.dart';
import '../providers/sesion_provider.dart';
import '../services/pedidos_service.dart';
import '../utils/formato.dart';
import '../utils/navegacion.dart';
import '../widgets/comunes.dart';
import 'pedido_detalle_screen.dart';

/// Historial de pedidos del usuario (GET /api/orders), en tiempo real.
class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  Stream<List<Pedido>>? _stream;
  String? _uid;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<SesionProvider>().usuario?.uid;
    // El stream se crea una sola vez por usuario (no en cada redibujo).
    if (uid != _uid) {
      _uid = uid;
      _stream = uid == null ? null : PedidosService().pedidosDe(uid);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: _stream == null
          ? EstadoVacio(
              icono: Icons.lock_outline,
              titulo: 'INICIÁ SESIÓN',
              texto: 'Ingresá para ver tus pedidos.',
              textoBoton: 'INGRESAR',
              alPresionar: () => asegurarSesion(context),
            )
          : StreamBuilder<List<Pedido>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error al leer pedidos: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pedidos = snapshot.data!;
                if (pedidos.isEmpty) {
                  return EstadoVacio(
                    icono: Icons.receipt_long_outlined,
                    titulo: 'TODAVÍA NO HICISTE PEDIDOS',
                    textoBoton: 'VER BOTINES',
                    alPresionar: () => irACatalogo(context),
                  );
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: pedidos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => TarjetaPedido(
                        pedido: pedidos[i],
                        alPresionar: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PedidoDetalleScreen(pedidoId: pedidos[i].id),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Resumen de un pedido en una lista (cliente y admin).
class TarjetaPedido extends StatelessWidget {
  const TarjetaPedido({super.key, required this.pedido, required this.alPresionar, this.extra});

  final Pedido pedido;
  final VoidCallback alPresionar;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final p = pedido;
    return InkWell(
      onTap: alPresionar,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Tema.grisBorde),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${p.numeroCorto}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    '${p.creadoEn == null ? 'Guardando…' : fechaHora(p.creadoEn!)} · '
                    '${p.cantidadProductos} productos · ${precioArs(p.total)}',
                    style: const TextStyle(color: Tema.grisTexto),
                  ),
                  ?extra,
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [EstadoChip.pedido(p.estado), EstadoChip.pago(p.estadoPago)],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
