import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../models/catalogo.dart';
import '../models/filtros.dart';
import '../providers/carrito_provider.dart';
import '../providers/sesion_provider.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/carrito_screen.dart';
import '../screens/favoritos_screen.dart';
import '../screens/perfil_screen.dart';
import '../utils/navegacion.dart';
import 'comunes.dart';

/// Barra superior de la tienda: logo, categorías, buscador, usuario y carrito.
class BarraNavegacion extends StatelessWidget implements PreferredSizeWidget {
  const BarraNavegacion({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final grande = MediaQuery.sizeOf(context).width >= 960;
    final sesion = context.watch<SesionProvider>();
    final cantidad = context.watch<CarritoProvider>().cantidadTotal;
    final puedeVolver = Navigator.of(context).canPop();

    return AppBar(
      toolbarHeight: 68,
      titleSpacing: puedeVolver ? 0 : 16,
      title: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).popUntil((ruta) => ruta.isFirst),
            child: LogoProKicks(tamanio: grande ? 30 : 24),
          ),
          if (grande) ...[
            const SizedBox(width: 28),
            const _MenuCategorias(),
            const SizedBox(width: 20),
            // Sin "const" afuera: en Flutter 3.47 ConstrainedBox ya no es const.
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: const _BuscadorBarra(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!grande) ...[
          IconButton(
            tooltip: 'Buscar',
            icon: const Icon(Icons.search),
            onPressed: () => irACatalogo(context, enfocarBuscador: true),
          ),
          const _MenuCategorias(compacto: true),
        ],
        if (grande && sesion.esAdmin)
          IconButton(
            tooltip: 'Panel de administración',
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminScreen()),
            ),
          ),
        if (grande)
          IconButton(
            tooltip: 'Favoritos',
            icon: const Icon(Icons.favorite_border),
            onPressed: () async {
              if (!await asegurarSesion(context)) return;
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavoritosScreen()),
              );
            },
          ),
        IconButton(
          tooltip: sesion.logueado ? 'Mi cuenta' : 'Ingresar',
          icon: Icon(sesion.logueado ? Icons.person : Icons.person_outline),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PerfilScreen()),
          ),
        ),
        IconButton(
          tooltip: 'Carrito',
          icon: Badge(
            isLabelVisible: cantidad > 0,
            backgroundColor: Tema.verde,
            textColor: Tema.negro,
            label: Text('$cantidad'),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CarritoScreen()),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _BuscadorBarra extends StatefulWidget {
  const _BuscadorBarra();

  @override
  State<_BuscadorBarra> createState() => _BuscadorBarraState();
}

class _BuscadorBarraState extends State<_BuscadorBarra> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(color: Colors.white),
      cursorColor: Tema.verde,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscá botines, marcas o superficie…',
        hintStyle: const TextStyle(color: Color(0xFF9A9A9A)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9A9A9A)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Tema.verde),
        ),
      ),
      onSubmitted: (texto) {
        irACatalogo(context, filtros: FiltrosCatalogo(texto: texto.trim()));
        _controller.clear();
      },
    );
  }
}

class _MenuCategorias extends StatelessWidget {
  const _MenuCategorias({this.compacto = false});

  final bool compacto;

  void _elegir(BuildContext context, String valor) {
    FiltrosCatalogo filtros = const FiltrosCatalogo();
    if (valor.startsWith('sup:')) {
      filtros = FiltrosCatalogo(superficies: {valor.substring(4)});
    } else if (valor.startsWith('marca:')) {
      filtros = FiltrosCatalogo(marcas: {valor.substring(6)});
    } else if (valor == 'ofertas') {
      filtros = const FiltrosCatalogo(soloOfertas: true);
    } else if (valor == 'nuevos') {
      filtros = const FiltrosCatalogo(soloNuevos: true, orden: OrdenCatalogo.novedades);
    }
    irACatalogo(context, filtros: filtros);
  }

  @override
  Widget build(BuildContext context) {
    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(value: 'todos', child: Text('Todos los botines')),
      const PopupMenuItem(value: 'nuevos', child: Text('Nuevos lanzamientos')),
      const PopupMenuItem(value: 'ofertas', child: Text('Ofertas')),
      const PopupMenuDivider(),
      for (final e in Catalogo.superficies.entries)
        PopupMenuItem(value: 'sup:${e.key}', child: Text('${e.key} · ${e.value}')),
      const PopupMenuDivider(),
      for (final m in Catalogo.marcas) PopupMenuItem(value: 'marca:$m', child: Text(m)),
    ];

    if (compacto) {
      return PopupMenuButton<String>(
        tooltip: 'Categorías',
        icon: const Icon(Icons.menu),
        onSelected: (v) => _elegir(context, v),
        itemBuilder: (_) => items,
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Categorías',
      onSelected: (v) => _elegir(context, v),
      itemBuilder: (_) => items,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CATEGORÍAS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            Icon(Icons.expand_more, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
