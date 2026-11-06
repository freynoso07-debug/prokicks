import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/tema.dart';
import '../../models/filtros.dart';
import '../../models/producto.dart';
import '../../services/productos_service.dart';
import '../../utils/formato.dart';
import '../../utils/navegacion.dart';
import '../../widgets/botin_imagen.dart';
import '../../widgets/comunes.dart';
import 'producto_form_screen.dart';

/// Listado de productos para el admin: buscar, crear, editar y eliminar.
class AdminProductos extends StatefulWidget {
  const AdminProductos({super.key});

  @override
  State<AdminProductos> createState() => _AdminProductosState();
}

class _AdminProductosState extends State<AdminProductos> {
  String _busqueda = '';
  bool _cargandoEjemplos = false;

  void _abrirFormulario([Producto? producto]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductoFormScreen(producto: producto)),
    );
  }

  Future<void> _eliminar(Producto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Text(
          'Se va a borrar "${p.nombre}" del catálogo. No se puede deshacer.\n\n'
          'Si solo querés ocultarlo, editalo y desactivá "Visible en la tienda".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Tema.rojo),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ProductosService().eliminar(p.id);
      if (mounted) mostrarMensaje(context, 'Producto eliminado.');
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo eliminar: $e');
    }
  }

  Future<void> _cargarEjemplos() async {
    setState(() => _cargandoEjemplos = true);
    try {
      final n = await ProductosService().cargarDatosDeEjemplo();
      if (mounted) {
        mostrarMensaje(
          context,
          n == 0
              ? 'Los datos de ejemplo ya estaban cargados: no se duplicó nada.'
              : 'Se agregaron $n productos de ejemplo (y los cupones que faltaban).',
        );
      }
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudieron cargar: $e');
    } finally {
      if (mounted) setState(() => _cargandoEjemplos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<List<Producto>?>();
    if (todos == null) return const Center(child: CircularProgressIndicator());

    final q = FiltrosCatalogo.normalizar(_busqueda);
    final lista =
        todos
            .where(
              (p) =>
                  q.isEmpty ||
                  FiltrosCatalogo.normalizar('${p.nombre} ${p.marca} ${p.sku}')
                      .contains(q),
            )
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('PRODUCTOS (${todos.length})', style: Tema.titulo(40)),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre, marca o SKU',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _busqueda = v),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('NUEVO PRODUCTO'),
              ),
              OutlinedButton.icon(
                onPressed: _cargandoEjemplos ? null : _cargarEjemplos,
                icon: const Icon(Icons.playlist_add),
                label: Text(
                  _cargandoEjemplos ? 'CARGANDO…' : 'CARGAR EJEMPLOS',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: lista.isEmpty
              ? const EstadoVacio(
                  icono: Icons.inventory_2_outlined,
                  titulo: 'SIN PRODUCTOS',
                  texto: 'Creá uno nuevo o cargá los datos de ejemplo.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, i) {
                    final p = lista[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            color: Tema.grisFondo,
                            child: BotinImagen(
                              url: p.imagenPrincipal,
                              colores: p.colores,
                              superficie: p.superficie,
                              padding: const EdgeInsets.all(4),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${p.marca} · ${p.superficie} · SKU ${p.sku} · ${p.ventas} vendidos',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Tema.grisTexto,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    if (!p.activo)
                                      const EtiquetaChica(
                                        'OCULTO',
                                        fondo: Tema.grisTexto,
                                      ),
                                    if (p.nuevo)
                                      const EtiquetaChica(
                                        'NUEVO',
                                        fondo: Tema.negro,
                                      ),
                                    if (p.destacado)
                                      const EtiquetaChica(
                                        'DESTACADO',
                                        fondo: Tema.verde,
                                        colorTexto: Tema.negro,
                                      ),
                                    if (p.enOferta)
                                      const EtiquetaChica(
                                        'OFERTA',
                                        fondo: Tema.naranja,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  precioArs(p.precio),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Stock: ${p.stockTotal}',
                                  style: TextStyle(
                                    color: p.sinStock
                                        ? Tema.rojo
                                        : Tema.grisTexto,
                                    fontWeight: p.sinStock
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _abrirFormulario(p),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Tema.rojo,
                            ),
                            onPressed: () => _eliminar(p),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
