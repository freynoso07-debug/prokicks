import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../models/catalogo.dart';
import '../models/filtros.dart';
import '../models/producto.dart';
import '../utils/formato.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/comunes.dart';
import '../widgets/producto_card.dart';

/// Catálogo con buscador en tiempo real, filtros (marca, precio, talle,
/// superficie) y orden (precio, popularidad, novedades).
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({
    super.key,
    this.filtrosIniciales = const FiltrosCatalogo(),
    this.enfocarBuscador = false,
  });

  final FiltrosCatalogo filtrosIniciales;
  final bool enfocarBuscador;

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  late FiltrosCatalogo _filtros = widget.filtrosIniciales;
  late final TextEditingController _buscador =
      TextEditingController(text: widget.filtrosIniciales.texto);

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  void _cambiarFiltros(FiltrosCatalogo nuevos) => setState(() => _filtros = nuevos);

  void _abrirFiltrosMovil(double precioMin, double precioMax) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (contextoHoja) => StatefulBuilder(
        builder: (contextoHoja, setHoja) => ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(contextoHoja).height * 0.85),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PanelFiltros(
                  filtros: _filtros,
                  precioMin: precioMin,
                  precioMax: precioMax,
                  alCambiar: (f) {
                    _cambiarFiltros(f);
                    setHoja(() {});
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(contextoHoja),
                  child: const Text('VER RESULTADOS'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<List<Producto>?>();

    return Scaffold(
      appBar: const BarraNavegacion(),
      body: todos == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final grande = constraints.maxWidth >= 980;
                final activos = todos.where((p) => p.activo).toList();
                final resultado = _filtros.aplicar(activos);

                // Rango del slider de precio, redondeado a $10.000.
                var precioMin = 0.0;
                var precioMax = 100000.0;
                if (activos.isNotEmpty) {
                  final precios = activos.map((p) => p.precio).toList()..sort();
                  precioMin = (precios.first / 10000).floorToDouble() * 10000;
                  precioMax = (precios.last / 10000).ceilToDouble() * 10000;
                  if (precioMax <= precioMin) precioMax = precioMin + 10000;
                }

                final contenido = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cabecera(grande, resultado.length, precioMin, precioMax),
                    if (_filtros.cantidadActivos > 0) _chipsActivos(),
                    Expanded(
                      child: resultado.isEmpty
                          ? EstadoVacio(
                              icono: Icons.search_off,
                              titulo: 'SIN RESULTADOS',
                              texto: 'Probá con otra búsqueda o sacá algunos filtros.',
                              textoBoton: 'LIMPIAR FILTROS',
                              alPresionar: () {
                                _buscador.clear();
                                _cambiarFiltros(const FiltrosCatalogo());
                              },
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(20),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 290,
                                mainAxisExtent: 400,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: resultado.length,
                              itemBuilder: (_, i) => ProductoCard(producto: resultado[i]),
                            ),
                    ),
                  ],
                );

                if (!grande) return contenido;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 290,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: PanelFiltros(
                          filtros: _filtros,
                          precioMin: precioMin,
                          precioMax: precioMax,
                          alCambiar: _cambiarFiltros,
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: contenido),
                  ],
                );
              },
            ),
    );
  }

  Widget _cabecera(bool grande, int cantidad, double precioMin, double precioMax) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_tituloPagina(), style: Tema.titulo(grande ? 48 : 36)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: grande ? 420 : double.infinity,
                child: TextField(
                  controller: _buscador,
                  autofocus: widget.enfocarBuscador,
                  decoration: InputDecoration(
                    hintText: 'Buscar por modelo, marca, color o SKU',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _buscador.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Borrar',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _buscador.clear();
                              _cambiarFiltros(_filtros.copyWith(texto: ''));
                            },
                          ),
                  ),
                  // Búsqueda en tiempo real: filtra en cada letra.
                  onChanged: (t) => _cambiarFiltros(_filtros.copyWith(texto: t)),
                ),
              ),
              if (!grande)
                OutlinedButton.icon(
                  onPressed: () => _abrirFiltrosMovil(precioMin, precioMax),
                  icon: const Icon(Icons.tune),
                  label: Text(
                    _filtros.cantidadActivos == 0
                        ? 'FILTROS'
                        : 'FILTROS (${_filtros.cantidadActivos})',
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ordenar por: '),
                  DropdownButton<OrdenCatalogo>(
                    value: _filtros.orden,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final o in OrdenCatalogo.values)
                        DropdownMenuItem(value: o, child: Text(o.nombre)),
                    ],
                    onChanged: (o) {
                      if (o != null) _cambiarFiltros(_filtros.copyWith(orden: o));
                    },
                  ),
                ],
              ),
              Text(
                '$cantidad ${cantidad == 1 ? 'producto' : 'productos'}',
                style: const TextStyle(color: Tema.grisTexto),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _tituloPagina() {
    final f = _filtros;
    if (f.soloOfertas) return 'OFERTAS';
    if (f.soloNuevos) return 'NUEVOS LANZAMIENTOS';
    if (f.soloDestacados) return 'DESTACADOS';
    if (f.superficies.length == 1) {
      final s = f.superficies.first;
      return 'BOTINES $s · ${Catalogo.nombreSuperficie(s).toUpperCase()}';
    }
    if (f.marcas.length == 1) return 'BOTINES ${f.marcas.first.toUpperCase()}';
    return 'TODOS LOS BOTINES';
  }

  Widget _chipsActivos() {
    final f = _filtros;
    final chips = <Widget>[
      for (final m in f.marcas)
        InputChip(
          label: Text(m),
          onDeleted: () => _cambiarFiltros(f.copyWith(marcas: _sin(f.marcas, m))),
        ),
      for (final s in f.superficies)
        InputChip(
          label: Text(s),
          onDeleted: () => _cambiarFiltros(f.copyWith(superficies: _sin(f.superficies, s))),
        ),
      for (final t in f.talles)
        InputChip(
          label: Text('Talle $t'),
          onDeleted: () => _cambiarFiltros(f.copyWith(talles: _sin(f.talles, t))),
        ),
      if (f.precioMin != null || f.precioMax != null)
        InputChip(
          label: Text(
            '${precioArs(f.precioMin ?? 0)} – ${f.precioMax == null ? 'más' : precioArs(f.precioMax!)}',
          ),
          onDeleted: () => _cambiarFiltros(f.copyWith(precioMin: null, precioMax: null)),
        ),
      if (f.soloOfertas)
        InputChip(
          label: const Text('Ofertas'),
          onDeleted: () => _cambiarFiltros(f.copyWith(soloOfertas: false)),
        ),
      if (f.soloNuevos)
        InputChip(
          label: const Text('Nuevos'),
          onDeleted: () => _cambiarFiltros(f.copyWith(soloNuevos: false)),
        ),
      if (f.soloDestacados)
        InputChip(
          label: const Text('Destacados'),
          onDeleted: () => _cambiarFiltros(f.copyWith(soloDestacados: false)),
        ),
      TextButton(
        onPressed: () => _cambiarFiltros(f.limpiar()),
        child: const Text('Limpiar todo'),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }
}

Set<String> _sin(Set<String> conjunto, String valor) => {...conjunto}..remove(valor);

Set<String> _alternar(Set<String> conjunto, String valor) =>
    conjunto.contains(valor) ? _sin(conjunto, valor) : {...conjunto, valor};

/// Panel de filtros (columna izquierda en pantalla grande, hoja en celular).
class PanelFiltros extends StatelessWidget {
  const PanelFiltros({
    super.key,
    required this.filtros,
    required this.precioMin,
    required this.precioMax,
    required this.alCambiar,
  });

  final FiltrosCatalogo filtros;
  final double precioMin;
  final double precioMax;
  final ValueChanged<FiltrosCatalogo> alCambiar;

  @override
  Widget build(BuildContext context) {
    final f = filtros;
    final desde = (f.precioMin ?? precioMin).clamp(precioMin, precioMax).toDouble();
    final hasta = (f.precioMax ?? precioMax).clamp(precioMin, precioMax).toDouble();

    Widget titulo(String t) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text(t, style: Tema.etiqueta(color: Tema.negro, tamanio: 13)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FILTROS', style: Tema.titulo(30)),
        titulo('MARCA'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final m in Catalogo.marcas)
              FilterChip(
                label: Text(m),
                selected: f.marcas.contains(m),
                onSelected: (_) => alCambiar(f.copyWith(marcas: _alternar(f.marcas, m))),
              ),
          ],
        ),
        titulo('SUPERFICIE'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final e in Catalogo.superficies.entries)
              Tooltip(
                message: e.value,
                child: FilterChip(
                  label: Text(e.key),
                  selected: f.superficies.contains(e.key),
                  onSelected: (_) =>
                      alCambiar(f.copyWith(superficies: _alternar(f.superficies, e.key))),
                ),
              ),
          ],
        ),
        titulo('TALLE (CON STOCK)'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in Catalogo.talles)
              FilterChip(
                label: Text(t),
                showCheckmark: false,
                selected: f.talles.contains(t),
                onSelected: (_) => alCambiar(f.copyWith(talles: _alternar(f.talles, t))),
              ),
          ],
        ),
        titulo('PRECIO'),
        RangeSlider(
          min: precioMin,
          max: precioMax,
          divisions: ((precioMax - precioMin) / 10000).round().clamp(1, 200).toInt(),
          values: RangeValues(desde, hasta),
          activeColor: Tema.negro,
          labels: RangeLabels(precioArs(desde), precioArs(hasta)),
          onChanged: (v) => alCambiar(f.copyWith(
            precioMin: v.start <= precioMin ? null : v.start,
            precioMax: v.end >= precioMax ? null : v.end,
          )),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(precioArs(desde), style: const TextStyle(fontSize: 13)),
            Text(precioArs(hasta), style: const TextStyle(fontSize: 13)),
          ],
        ),
        titulo('MOSTRAR'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Solo ofertas'),
          value: f.soloOfertas,
          onChanged: (v) => alCambiar(f.copyWith(soloOfertas: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Solo nuevos'),
          value: f.soloNuevos,
          onChanged: (v) => alCambiar(f.copyWith(soloNuevos: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Solo destacados'),
          value: f.soloDestacados,
          onChanged: (v) => alCambiar(f.copyWith(soloDestacados: v)),
        ),
        const SizedBox(height: 12),
        if (f.cantidadActivos > 0)
          OutlinedButton(
            onPressed: () => alCambiar(f.limpiar()),
            child: const Text('LIMPIAR FILTROS'),
          ),
      ],
    );
  }
}
