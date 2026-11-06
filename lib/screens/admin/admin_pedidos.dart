import 'package:flutter/material.dart';

import '../../config/tema.dart';
import '../../models/pedido.dart';
import '../../services/pedidos_service.dart';
import '../../utils/navegacion.dart';
import '../../widgets/comunes.dart';
import '../pedido_detalle_screen.dart';
import '../pedidos_screen.dart';

/// Todos los pedidos de la tienda, con cambio de estado.
class AdminPedidos extends StatefulWidget {
  const AdminPedidos({super.key});

  @override
  State<AdminPedidos> createState() => _AdminPedidosState();
}

class _AdminPedidosState extends State<AdminPedidos> {
  final _servicio = PedidosService();
  late final Stream<List<Pedido>> _stream = _servicio.todos();
  String? _filtroEstado; // null = todos

  Future<void> _cambiarEstado(Pedido p, String nuevo) async {
    if (nuevo == p.estado) return;
    try {
      if (nuevo == EstadosPedido.cancelado) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Cancelar el pedido?'),
            content: const Text('Se devuelve el stock de cada talle al catálogo.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí')),
            ],
          ),
        );
        if (ok != true) return;
        await _servicio.cancelar(p.id);
      } else {
        await _servicio.cambiarEstado(p.id, nuevo);
      }
      if (mounted) mostrarMensaje(context, 'Pedido #${p.numeroCorto}: ${EstadosPedido.nombre(nuevo)}.');
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo cambiar el estado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pedido>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error al leer pedidos: ${snapshot.error}'));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final todos = snapshot.data!;
        final lista =
            _filtroEstado == null ? todos : todos.where((p) => p.estado == _filtroEstado).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text('PEDIDOS (${todos.length})', style: Tema.titulo(40)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _filtroEstado == null,
                    onSelected: (_) => setState(() => _filtroEstado = null),
                  ),
                  for (final e in EstadosPedido.todos)
                    ChoiceChip(
                      label: Text(
                        '${EstadosPedido.nombre(e)} (${todos.where((p) => p.estado == e).length})',
                      ),
                      selected: _filtroEstado == e,
                      onSelected: (_) => setState(() => _filtroEstado = e),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: lista.isEmpty
                  ? const EstadoVacio(icono: Icons.receipt_long_outlined, titulo: 'SIN PEDIDOS')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: lista.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final p = lista[i];
                        return TarjetaPedido(
                          pedido: p,
                          alPresionar: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PedidoDetalleScreen(pedidoId: p.id)),
                          ),
                          extra: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${p.nombre} · ${p.email}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Estado: ', style: TextStyle(fontSize: 13)),
                                    DropdownButton<String>(
                                      value: p.estado,
                                      isDense: true,
                                      items: [
                                        for (final e in EstadosPedido.todos)
                                          DropdownMenuItem(
                                            value: e,
                                            child: Text(EstadosPedido.nombre(e)),
                                          ),
                                      ],
                                      // Un pedido cancelado ya devolvió su stock: no se reabre.
                                      onChanged: p.estado == EstadosPedido.cancelado
                                          ? null
                                          : (v) {
                                              if (v != null) _cambiarEstado(p, v);
                                            },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
