import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/tema.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/comunes.dart';
import 'admin_cupones.dart';
import 'admin_pedidos.dart';
import 'admin_productos.dart';
import 'admin_resumen.dart';
import 'admin_usuarios.dart';

/// Panel de administración. Solo entra quien tiene rol 'admin' en su perfil.
/// (Además, las reglas de Firestore bloquean las escrituras de cualquier otro.)
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _seccion = 0;

  static const _destinos = [
    (Icons.insights_outlined, 'Resumen'),
    (Icons.inventory_2_outlined, 'Productos'),
    (Icons.receipt_long_outlined, 'Pedidos'),
    (Icons.local_offer_outlined, 'Cupones'),
    (Icons.group_outlined, 'Usuarios'),
  ];

  Widget _contenido() {
    switch (_seccion) {
      case 1:
        return const AdminProductos();
      case 2:
        return const AdminPedidos();
      case 3:
        return const AdminCupones();
      case 4:
        return const AdminUsuarios();
      default:
        return const AdminResumen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    final appBar = AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LogoProKicks(tamanio: 24),
          const SizedBox(width: 10),
          Text('ADMIN', style: Tema.titulo(24, color: Tema.naranja)),
        ],
      ),
    );

    if (!sesion.esAdmin) {
      return Scaffold(
        appBar: appBar,
        body: const EstadoVacio(
          icono: Icons.lock_outline,
          titulo: 'ACCESO RESTRINGIDO',
          texto: 'Esta sección es solo para administradores.',
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final grande = constraints.maxWidth >= 840;
        if (grande) {
          final extendido = constraints.maxWidth >= 1200;
          return Scaffold(
            appBar: appBar,
            body: Row(
              // stretch: sin esto el Row centra el contenido en vertical y las
              // secciones cortas (como Cupones) quedaban flotando en el medio.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NavigationRail(
                  selectedIndex: _seccion,
                  onDestinationSelected: (i) => setState(() => _seccion = i),
                  extended: extendido,
                  labelType: extendido
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  indicatorColor: Tema.verde,
                  destinations: [
                    for (final d in _destinos)
                      NavigationRailDestination(
                        icon: Icon(d.$1),
                        label: Text(d.$2),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _contenido()),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: appBar,
          body: _contenido(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _seccion,
            onDestinationSelected: (i) => setState(() => _seccion = i),
            indicatorColor: Tema.verde,
            destinations: [
              for (final d in _destinos)
                NavigationDestination(icon: Icon(d.$1), label: d.$2),
            ],
          ),
        );
      },
    );
  }
}

/// Tarjeta métrica para el resumen.
class TarjetaMetrica extends StatelessWidget {
  const TarjetaMetrica({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.detalle,
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Tema.negro,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: Tema.verde, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: Tema.etiqueta(color: const Color(0xFFBDBDBD)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: Tema.titulo(40, color: Colors.white)),
          ),
          if (detalle != null)
            Text(
              detalle!,
              style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
            ),
        ],
      ),
    );
  }
}

/// Contenedor con título para los gráficos del resumen.
class TarjetaGrafico extends StatelessWidget {
  const TarjetaGrafico({
    super.key,
    required this.titulo,
    required this.child,
    this.ancho = 520,
  });

  final String titulo;
  final Widget child;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Tema.grisBorde),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Tema.etiqueta(color: Tema.negro, tamanio: 13)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
