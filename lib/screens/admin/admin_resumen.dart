import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/tema.dart';
import '../../models/catalogo.dart';
import '../../models/pedido.dart';
import '../../models/producto.dart';
import '../../services/pedidos_service.dart';
import '../../services/productos_service.dart';
import '../../utils/formato.dart';
import '../../utils/navegacion.dart';
import '../../widgets/comunes.dart';
import '../../widgets/graficos.dart';
import 'admin_screen.dart';

/// Estadísticas de ventas con gráficos.
class AdminResumen extends StatefulWidget {
  const AdminResumen({super.key});

  @override
  State<AdminResumen> createState() => _AdminResumenState();
}

class _AdminResumenState extends State<AdminResumen> {
  late final Stream<List<Pedido>> _pedidos = PedidosService().todos();
  bool _cargandoEjemplos = false;

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
      if (mounted) {
        mostrarMensaje(context, 'No se pudieron cargar los datos: $e');
      }
    } finally {
      if (mounted) setState(() => _cargandoEjemplos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productos = context.watch<List<Producto>?>() ?? const <Producto>[];

    return StreamBuilder<List<Pedido>>(
      stream: _pedidos,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al leer pedidos: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final pedidos = snapshot.data!;
        // Ventas = pedidos con pago aprobado que no se cancelaron.
        final pagados = pedidos
            .where((p) => p.pagoAprobado && p.estado != EstadosPedido.cancelado)
            .toList();
        final ventasTotales = pagados.fold<double>(0, (s, p) => s + p.total);
        final ticketPromedio = pagados.isEmpty
            ? 0.0
            : ventasTotales / pagados.length;
        final stockTotal = productos.fold<int>(0, (s, p) => s + p.stockTotal);
        final sinStock = productos.where((p) => p.activo && p.sinStock).length;
        final unidades = pagados.fold<int>(
          0,
          (s, p) => s + p.cantidadProductos,
        );

        // Ingresos de los últimos 6 meses.
        final ahora = DateTime.now();
        final meses = [
          for (var i = 5; i >= 0; i--) DateTime(ahora.year, ahora.month - i),
        ];
        final ingresosMensuales = [
          for (final m in meses)
            DatoGrafico(
              mesCorto(m),
              pagados
                  .where(
                    (p) =>
                        p.creadoEn != null &&
                        p.creadoEn!.year == m.year &&
                        p.creadoEn!.month == m.month,
                  )
                  .fold<double>(0, (s, p) => s + p.total),
            ),
        ];

        // Productos más vendidos (campo `ventas` que suma la transacción).
        final masVendidos = [...productos]
          ..sort((a, b) => b.ventas.compareTo(a.ventas));
        final topVendidos = masVendidos
            .take(6)
            .where((p) => p.ventas > 0)
            .map((p) => DatoGrafico(p.nombre, p.ventas.toDouble()))
            .toList();

        final stockPorMarca = [
          for (final m in Catalogo.marcas)
            DatoGrafico(
              m,
              productos
                  .where((p) => p.marca == m)
                  .fold<int>(0, (s, p) => s + p.stockTotal)
                  .toDouble(),
            ),
        ];

        final pedidosPorEstado = [
          for (final e in EstadosPedido.todos)
            DatoGrafico(
              EstadosPedido.nombre(e),
              pedidos.where((p) => p.estado == e).length.toDouble(),
            ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            // Ancho útil = ancho disponible - 48 de padding. Si entran dos gráficos
            // de al menos 380 px (más 16 de separación) van de a dos; si no, uno por fila.
            // Antes era fijo en 520 px y en una pantalla de 1280 quedaba uno solo por fila.
            final util = constraints.maxWidth - 48;
            final anchoGrafico = util >= 380 * 2 + 16 ? (util - 16) / 2 : util;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TituloSeccion('RESUMEN DE VENTAS', tamanio: 40),
                  if (productos.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFFFFF3E0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'La tienda no tiene productos. Cargá los datos de ejemplo '
                              '(20 botines y 3 cupones) para empezar a probar.',
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _cargandoEjemplos
                                ? null
                                : _cargarEjemplos,
                            child: Text(
                              _cargandoEjemplos
                                  ? 'CARGANDO…'
                                  : 'CARGAR DATOS DE EJEMPLO',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      TarjetaMetrica(
                        titulo: 'VENTAS TOTALES',
                        valor: precioArs(ventasTotales),
                        icono: Icons.payments_outlined,
                        detalle: 'Pedidos con pago aprobado',
                      ),
                      TarjetaMetrica(
                        titulo: 'PEDIDOS',
                        valor: '${pedidos.length}',
                        icono: Icons.receipt_long_outlined,
                        detalle: '${pagados.length} pagados',
                      ),
                      TarjetaMetrica(
                        titulo: 'TICKET PROMEDIO',
                        valor: precioArs(ticketPromedio),
                        icono: Icons.trending_up,
                        detalle: '$unidades pares vendidos',
                      ),
                      TarjetaMetrica(
                        titulo: 'STOCK DISPONIBLE',
                        valor: '$stockTotal',
                        icono: Icons.inventory_2_outlined,
                        detalle: '$sinStock productos sin stock',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      TarjetaGrafico(
                        ancho: anchoGrafico,
                        titulo: 'INGRESOS MENSUALES (ÚLTIMOS 6 MESES)',
                        child: BarrasVerticales(
                          datos: ingresosMensuales,
                          formato: (v) => v == 0
                              ? '\$0'
                              : '\$${formatearNumero(v / 1000)}k',
                          color: Tema.negro,
                        ),
                      ),
                      TarjetaGrafico(
                        ancho: anchoGrafico,
                        titulo: 'PRODUCTOS MÁS VENDIDOS (UNIDADES)',
                        child: BarrasHorizontales(
                          datos: topVendidos,
                          formato: (v) => formatearNumero(v),
                          color: Tema.naranja,
                        ),
                      ),
                      TarjetaGrafico(
                        ancho: anchoGrafico,
                        titulo: 'STOCK DISPONIBLE POR MARCA (PARES)',
                        child: BarrasHorizontales(
                          datos: stockPorMarca,
                          formato: (v) => formatearNumero(v),
                          color: const Color(0xFF8BC34A),
                        ),
                      ),
                      TarjetaGrafico(
                        ancho: anchoGrafico,
                        titulo: 'PEDIDOS POR ESTADO',
                        child: BarrasHorizontales(
                          datos: pedidosPorEstado,
                          formato: (v) => formatearNumero(v),
                          color: Tema.negro,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
