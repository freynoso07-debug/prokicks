import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../models/usuario.dart';
import '../providers/sesion_provider.dart';
import '../services/auth_service.dart';
import '../services/georef_service.dart';
import '../services/usuarios_service.dart';
import '../utils/navegacion.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/comunes.dart';
import 'admin/admin_screen.dart';
import 'favoritos_screen.dart';
import 'pedidos_screen.dart';

/// Perfil del usuario (GET /api/users/me): datos, dirección y accesos.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _calle = TextEditingController();
  final _numero = TextEditingController();
  final _localidad = TextEditingController();
  final _cp = TextEditingController();
  String? _provincia;
  List<String> _provincias = GeorefService.provinciasRespaldo;
  bool _datosCargados = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    GeorefService().provincias().then((lista) {
      if (mounted) setState(() => _provincias = lista);
    }).catchError((Object e) {
      debugPrint('Georef no respondió: $e');
    });
  }

  @override
  void dispose() {
    for (final c in [_nombre, _telefono, _calle, _numero, _localidad, _cp]) {
      c.dispose();
    }
    super.dispose();
  }

  void _cargarDatos(PerfilUsuario p) {
    _nombre.text = p.nombre;
    _telefono.text = p.telefono;
    _calle.text = p.direccion.calle;
    _numero.text = p.direccion.numero;
    _localidad.text = p.direccion.localidad;
    _cp.text = p.direccion.codigoPostal;
    _provincia = p.direccion.provincia.isEmpty ? null : p.direccion.provincia;
    _datosCargados = true;
  }

  Future<void> _guardar(String uid) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await UsuariosService().actualizarDatos(
        uid,
        nombre: _nombre.text.trim(),
        telefono: _telefono.text.trim(),
        direccion: Direccion(
          calle: _calle.text.trim(),
          numero: _numero.text.trim(),
          localidad: _localidad.text.trim(),
          provincia: _provincia ?? '',
          codigoPostal: _cp.text.trim(),
        ),
      );
      if (!mounted) return;
      mostrarMensaje(context, 'Datos guardados.');
      // Después de guardar, volvemos al inicio de la tienda. El mensaje se sigue
      // viendo porque el ScaffoldMessenger es de toda la app, no de esta pantalla.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudieron guardar los datos: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await AuthService().cerrarSesion();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();

    if (!sesion.logueado) {
      return Scaffold(
        appBar: const BarraNavegacion(),
        body: EstadoVacio(
          icono: Icons.person_outline,
          titulo: 'TU CUENTA',
          texto: 'Ingresá o creá una cuenta para comprar, guardar favoritos y ver tus pedidos.',
          textoBoton: 'INGRESAR O REGISTRARME',
          alPresionar: () => asegurarSesion(context),
        ),
      );
    }

    final perfil = sesion.perfil;
    if (perfil == null) {
      return const Scaffold(
        appBar: BarraNavegacion(),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_datosCargados) _cargarDatos(perfil);

    return Scaffold(
      appBar: const BarraNavegacion(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('HOLA, ${perfil.nombre.toUpperCase()}', style: Tema.titulo(44)),
                    ),
                    if (perfil.esAdmin) const EtiquetaChica('ADMIN', fondo: Tema.negro),
                  ],
                ),
                Text(perfil.email, style: const TextStyle(color: Tema.grisTexto)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PedidosScreen()),
                      ),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('MIS PEDIDOS'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FavoritosScreen()),
                      ),
                      icon: const Icon(Icons.favorite_border),
                      label: Text('FAVORITOS (${perfil.favoritos.length})'),
                    ),
                    if (perfil.esAdmin)
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminScreen()),
                        ),
                        icon: const Icon(Icons.dashboard_outlined),
                        label: const Text('PANEL DE ADMINISTRACIÓN'),
                      ),
                    TextButton.icon(
                      onPressed: _cerrarSesion,
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TituloSeccion('MIS DATOS'),
                      TextFormField(
                        controller: _nombre,
                        decoration: const InputDecoration(labelText: 'Nombre y apellido'),
                        validator: (v) => (v ?? '').trim().length < 3 ? 'Ingresá tu nombre' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telefono,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Teléfono'),
                      ),
                      const SizedBox(height: 24),
                      const TituloSeccion('DIRECCIÓN DE ENVÍO', tamanio: 24),
                      DropdownButtonFormField<String>(
                        // La key rearma el campo cuando llega la lista de Georef.
                        key: ValueKey('prov-${_provincias.length}-$_provincia'),
                        initialValue: _provincias.contains(_provincia) ? _provincia : null,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Provincia'),
                        items: [
                          for (final p in _provincias) DropdownMenuItem(value: p, child: Text(p)),
                        ],
                        onChanged: (v) => setState(() => _provincia = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _localidad,
                        decoration: const InputDecoration(labelText: 'Localidad'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _calle,
                              decoration: const InputDecoration(labelText: 'Calle'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _numero,
                              decoration: const InputDecoration(labelText: 'Número'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cp,
                        decoration: const InputDecoration(labelText: 'Código postal'),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _guardando ? null : () => _guardar(perfil.uid),
                        child: Text(_guardando ? 'GUARDANDO…' : 'GUARDAR CAMBIOS'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
