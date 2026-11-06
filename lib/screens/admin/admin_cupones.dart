import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/tema.dart';
import '../../models/cupon.dart';
import '../../services/cupones_service.dart';
import '../../utils/formato.dart';
import '../../utils/navegacion.dart';
import '../../widgets/comunes.dart';

/// Crear, activar/desactivar y eliminar cupones.
class AdminCupones extends StatefulWidget {
  const AdminCupones({super.key});

  @override
  State<AdminCupones> createState() => _AdminCuponesState();
}

class _AdminCuponesState extends State<AdminCupones> {
  final _servicio = CuponesService();
  late final Stream<List<Cupon>> _stream = _servicio.todos();

  final _form = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _valor = TextEditingController();
  final _minimo = TextEditingController(text: '0');
  final _usosMax = TextEditingController();
  String _tipo = 'porcentaje';
  DateTime? _vence;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_codigo, _valor, _minimo, _usosMax]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirVencimiento() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _vence ?? ahora.add(const Duration(days: 30)),
      firstDate: ahora,
      lastDate: DateTime(ahora.year + 3),
    );
    if (fecha != null) {
      // Vence al final de ese día.
      setState(
        () => _vence = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59),
      );
    }
  }

  Future<void> _crear() async {
    if (!_form.currentState!.validate()) return;
    final usosTexto = _usosMax.text.trim();
    final cupon = Cupon(
      codigo: _codigo.text.trim().toUpperCase(),
      tipo: _tipo,
      valor: double.parse(_valor.text.trim()),
      minimo: double.tryParse(_minimo.text.trim()) ?? 0,
      activo: true,
      vence: _vence,
      usos: 0,
      usosMax: usosTexto.isEmpty ? null : int.parse(usosTexto),
    );
    setState(() => _guardando = true);
    try {
      await _servicio.crear(cupon);
      _codigo.clear();
      _valor.clear();
      _minimo.text = '0';
      _usosMax.clear();
      if (!mounted) return;
      setState(() => _vence = null);
      mostrarMensaje(context, 'Cupón ${cupon.codigo} creado.');
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo crear el cupón: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Pide confirmación antes de borrar (igual que en Productos): borrar un
  /// cupón no se puede deshacer.
  Future<void> _eliminar(Cupon c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar el cupón ${c.codigo}?'),
        content: const Text(
          'Esta acción no se puede deshacer. Si solo querés pausarlo, desactivalo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _servicio.eliminar(c.codigo);
      if (mounted) mostrarMensaje(context, 'Cupón ${c.codigo} eliminado.');
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo eliminar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final soloNumeros = [FilteringTextInputFormatter.digitsOnly];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TituloSeccion('CUPONES', tamanio: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Tema.grisBorde),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NUEVO CUPÓN', style: Tema.etiqueta(color: Tema.negro)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: _codigo,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9_-]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Código',
                            hintText: 'VERANO25',
                          ),
                          validator: (v) => (v ?? '').trim().length < 3
                              ? 'Mínimo 3 caracteres'
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: DropdownButtonFormField<String>(
                          initialValue: _tipo,
                          decoration: const InputDecoration(labelText: 'Tipo'),
                          items: const [
                            DropdownMenuItem(
                              value: 'porcentaje',
                              child: Text('Porcentaje %'),
                            ),
                            DropdownMenuItem(
                              value: 'monto',
                              child: Text('Monto fijo \$'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: _valor,
                          inputFormatters: soloNumeros,
                          decoration: InputDecoration(
                            labelText: _tipo == 'porcentaje'
                                ? 'Valor (%)'
                                : 'Valor (\$)',
                          ),
                          validator: (v) {
                            final n = double.tryParse((v ?? '').trim());
                            if (n == null || n <= 0) return 'Inválido';
                            if (_tipo == 'porcentaje' && n > 90) {
                              return 'Máx. 90%';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: TextFormField(
                          controller: _minimo,
                          inputFormatters: soloNumeros,
                          decoration: const InputDecoration(
                            labelText: 'Compra mínima (\$)',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: _usosMax,
                          inputFormatters: soloNumeros,
                          decoration: const InputDecoration(
                            labelText: 'Usos máximos',
                            hintText: 'Sin límite',
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _elegirVencimiento,
                        icon: const Icon(Icons.event),
                        label: Text(
                          _vence == null
                              ? 'SIN VENCIMIENTO'
                              : 'VENCE ${fechaCorta(_vence!)}',
                        ),
                      ),
                      FilledButton(
                        onPressed: _guardando ? null : _crear,
                        child: const Text('CREAR CUPÓN'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<Cupon>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final cupones = snapshot.data!;
              if (cupones.isEmpty) {
                return const Text(
                  'Todavía no hay cupones.',
                  style: TextStyle(color: Tema.grisTexto),
                );
              }
              return Column(
                children: [
                  for (final c in cupones)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Tema.grisBorde),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${c.codigo} · ${c.descripcion}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Mínimo ${precioArs(c.minimo)} · '
                                  'Usos ${c.usos}${c.usosMax == null ? '' : '/${c.usosMax}'} · '
                                  '${c.vence == null ? 'Sin vencimiento' : 'Vence ${fechaCorta(c.vence!)}'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Tema.grisTexto,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: c.activo,
                            onChanged: (v) =>
                                _servicio.cambiarActivo(c.codigo, v),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Tema.rojo,
                            ),
                            onPressed: () => _eliminar(c),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
