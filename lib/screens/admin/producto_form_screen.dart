import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../config/tema.dart';
import '../../models/catalogo.dart';
import '../../models/producto.dart';
import '../../services/cloudinary_service.dart';
import '../../services/productos_service.dart';
import '../../utils/navegacion.dart';
import '../../widgets/botin_imagen.dart';
import '../../widgets/comunes.dart';

/// Alta y edición de productos (POST y PUT /api/products).
/// Incluye stock por talle, precios, descuentos, estados y fotos.
class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({super.key, this.producto});

  /// null = producto nuevo.
  final Producto? producto;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _sku = TextEditingController();
  final _precio = TextEditingController();
  final _precioAnterior = TextEditingController();
  final _descripcion = TextEditingController();
  final _colores = TextEditingController();
  final Map<String, TextEditingController> _stock = {
    for (final t in Catalogo.talles) t: TextEditingController(text: '0'),
  };

  String _marca = Catalogo.marcas.first;
  String _superficie = Catalogo.superficies.keys.first;
  bool _nuevo = false;
  bool _destacado = false;
  bool _oferta = false;
  bool _activo = true;
  List<String> _imagenes = [];
  bool _subiendo = false;
  bool _guardando = false;

  bool get _esNuevo => widget.producto == null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    if (p != null) {
      _nombre.text = p.nombre;
      _sku.text = p.sku;
      _precio.text = p.precio.round().toString();
      _precioAnterior.text = p.precioAnterior == null ? '' : p.precioAnterior!.round().toString();
      _descripcion.text = p.descripcion;
      _colores.text = p.colores.join(', ');
      if (Catalogo.marcas.contains(p.marca)) _marca = p.marca;
      if (Catalogo.superficies.containsKey(p.superficie)) _superficie = p.superficie;
      _nuevo = p.nuevo;
      _destacado = p.destacado;
      _oferta = p.oferta;
      _activo = p.activo;
      _imagenes = [...p.imagenes];
      for (final t in Catalogo.talles) {
        _stock[t]!.text = p.stockDe(t).toString();
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_nombre, _sku, _precio, _precioAnterior, _descripcion, _colores, ..._stock.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _subirFoto() async {
    if (!ApiConfig.cloudinaryConfigurado) {
      mostrarMensaje(context, 'Cloudinary no está configurado. Usá "Agregar por URL" o ver README, paso 7.');
      return;
    }
    final archivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (archivo == null) return;

    setState(() => _subiendo = true);
    try {
      final bytes = await archivo.readAsBytes();
      final url = await CloudinaryService().subirImagen(bytes, archivo.name);
      if (mounted) setState(() => _imagenes.add(url));
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo subir la foto: $e');
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _agregarPorUrl() async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar foto por URL'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'https://…'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url == null || url.isEmpty) return;
    if (!url.startsWith('http')) {
      if (mounted) mostrarMensaje(context, 'La URL tiene que empezar con http:// o https://');
      return;
    }
    setState(() => _imagenes.add(url));
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;

    final precio = double.parse(_precio.text.trim());
    final anteriorTexto = _precioAnterior.text.trim();
    final precioAnterior = anteriorTexto.isEmpty ? null : double.parse(anteriorTexto);

    final datos = <String, dynamic>{
      'nombre': _nombre.text.trim(),
      'marca': _marca,
      'superficie': _superficie,
      'sku': _sku.text.trim().toUpperCase(),
      'precio': precio,
      'precioAnterior': precioAnterior,
      'descripcion': _descripcion.text.trim(),
      'colores': _colores.text
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList(),
      'talles': {
        for (final t in Catalogo.talles) t: int.tryParse(_stock[t]!.text.trim()) ?? 0,
      },
      'imagenes': _imagenes,
      'nuevo': _nuevo,
      'destacado': _destacado,
      'oferta': _oferta,
      'activo': _activo,
    };

    setState(() => _guardando = true);
    try {
      final servicio = ProductosService();
      if (_esNuevo) {
        await servicio.crear(datos);
      } else {
        await servicio.actualizar(widget.producto!.id, datos);
      }
      if (!mounted) return;
      mostrarMensaje(context, _esNuevo ? 'Producto creado.' : 'Cambios guardados.');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String? _validarPrecio(String? v, {bool opcional = false}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return opcional ? null : 'Ingresá el precio';
    final n = double.tryParse(t);
    if (n == null || n <= 0) return 'Número inválido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final soloNumeros = [FilteringTextInputFormatter.digitsOnly];
    final colores = _colores.text.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(title: Text(_esNuevo ? 'Nuevo producto' : 'Editar producto')),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSeccion('DATOS BÁSICOS'),
                  TextFormField(
                    controller: _nombre,
                    decoration: const InputDecoration(labelText: 'Nombre del producto'),
                    validator: (v) => (v ?? '').trim().length < 3 ? 'Ingresá el nombre' : null,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          initialValue: _marca,
                          decoration: const InputDecoration(labelText: 'Marca'),
                          items: [
                            for (final m in Catalogo.marcas) DropdownMenuItem(value: m, child: Text(m)),
                          ],
                          onChanged: (v) => setState(() => _marca = v ?? _marca),
                        ),
                      ),
                      SizedBox(
                        width: 280,
                        child: DropdownButtonFormField<String>(
                          initialValue: _superficie,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Superficie'),
                          items: [
                            for (final e in Catalogo.superficies.entries)
                              DropdownMenuItem(value: e.key, child: Text('${e.key} · ${e.value}')),
                          ],
                          onChanged: (v) => setState(() => _superficie = v ?? _superficie),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: _sku,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'SKU'),
                          validator: (v) => (v ?? '').trim().isEmpty ? 'Ingresá el SKU' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descripcion,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    validator: (v) => (v ?? '').trim().length < 10 ? 'Escribí una descripción' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _colores,
                    decoration: const InputDecoration(
                      labelText: 'Colores (separados por coma)',
                      hintText: 'Negro, Verde flúor',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  const TituloSeccion('PRECIOS Y DESCUENTOS'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 220,
                        child: TextFormField(
                          controller: _precio,
                          inputFormatters: soloNumeros,
                          decoration: const InputDecoration(labelText: 'Precio actual (\$)'),
                          validator: (v) => _validarPrecio(v),
                        ),
                      ),
                      SizedBox(
                        width: 260,
                        child: TextFormField(
                          controller: _precioAnterior,
                          inputFormatters: soloNumeros,
                          decoration: const InputDecoration(
                            labelText: 'Precio anterior (\$, opcional)',
                            helperText: 'Si es mayor, se muestra el % de descuento',
                          ),
                          validator: (v) {
                            final error = _validarPrecio(v, opcional: true);
                            if (error != null) return error;
                            final anterior = double.tryParse((v ?? '').trim());
                            final actual = double.tryParse(_precio.text.trim());
                            if (anterior != null && actual != null && anterior <= actual) {
                              return 'Tiene que ser mayor al precio actual';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const TituloSeccion('STOCK POR TALLE'),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final t in Catalogo.talles)
                        SizedBox(
                          width: 86,
                          child: TextFormField(
                            controller: _stock[t],
                            inputFormatters: soloNumeros,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(labelText: 'Talle $t'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const TituloSeccion('ESTADO'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Nuevo'),
                        selected: _nuevo,
                        onSelected: (v) => setState(() => _nuevo = v),
                      ),
                      FilterChip(
                        label: const Text('Destacado'),
                        selected: _destacado,
                        onSelected: (v) => setState(() => _destacado = v),
                      ),
                      FilterChip(
                        label: const Text('Oferta'),
                        selected: _oferta,
                        onSelected: (v) => setState(() => _oferta = v),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Visible en la tienda'),
                    subtitle: const Text('Si lo apagás, el producto queda oculto pero no se borra.'),
                    value: _activo,
                    onChanged: (v) => setState(() => _activo = v),
                  ),
                  const SizedBox(height: 24),
                  const TituloSeccion('FOTOS'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < _imagenes.length; i++)
                        Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              color: Tema.grisFondo,
                              child: BotinImagen(
                                url: _imagenes[i],
                                colores: colores,
                                superficie: _superficie,
                                padding: const EdgeInsets.all(6),
                              ),
                            ),
                            if (i == 0)
                              const Positioned(
                                left: 4,
                                bottom: 0,
                                child: EtiquetaChica('PRINCIPAL', fondo: Tema.negro),
                              ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                tooltip: 'Quitar foto',
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _imagenes.removeAt(i)),
                              ),
                            ),
                          ],
                        ),
                      if (_imagenes.isEmpty)
                        Container(
                          width: 120,
                          height: 120,
                          color: Tema.grisFondo,
                          child: BotinImagen(colores: colores, superficie: _superficie),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _subiendo ? null : _subirFoto,
                        icon: _subiendo
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(_subiendo ? 'SUBIENDO…' : 'SUBIR FOTO (CLOUDINARY)'),
                      ),
                      TextButton.icon(
                        onPressed: _agregarPorUrl,
                        icon: const Icon(Icons.link),
                        label: const Text('Agregar por URL'),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Sin fotos, la tienda muestra un botín dibujado con los colores del producto.',
                      style: TextStyle(color: Tema.grisTexto, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: Text(
                      _guardando ? 'GUARDANDO…' : (_esNuevo ? 'CREAR PRODUCTO' : 'GUARDAR CAMBIOS'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
