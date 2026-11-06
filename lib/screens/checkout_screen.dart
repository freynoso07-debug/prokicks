import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../models/envio.dart';
import '../models/filtros.dart';
import '../models/usuario.dart';
import '../providers/carrito_provider.dart';
import '../providers/cotizacion_provider.dart';
import '../providers/sesion_provider.dart';
import '../services/envio_service.dart';
import '../services/georef_service.dart';
import '../services/pago_service.dart';
import '../services/pedidos_service.dart';
import '../services/usuarios_service.dart';
import '../utils/formato.dart';
import '../utils/navegacion.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/comunes.dart';
import 'pago_prueba_screen.dart';
import 'pedido_detalle_screen.dart';

/// Checkout: datos de contacto, entrega (con Georef y costo de envío) y pago.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _calleCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _cpCtrl = TextEditingController();
  final _pago = PagoService();

  String _metodo = 'domicilio';
  String? _provincia;
  String _localidad = '';
  bool _guardarDatos = true;
  bool _procesando = false;

  List<String> _provincias = GeorefService.provinciasRespaldo;
  bool _provinciasDeGeoref = false;
  List<String> _localidades = [];
  bool _cargandoLocalidades = false;

  @override
  void initState() {
    super.initState();
    final sesion = context.read<SesionProvider>();
    final perfil = sesion.perfil;
    _nombreCtrl.text = perfil?.nombre ?? sesion.nombre;
    _telefonoCtrl.text = perfil?.telefono ?? '';
    final dir = perfil?.direccion ?? Direccion.vacia;
    _calleCtrl.text = dir.calle;
    _numeroCtrl.text = dir.numero;
    _cpCtrl.text = dir.codigoPostal;
    _localidad = dir.localidad;
    if (dir.provincia.isNotEmpty) {
      _provincia = dir.provincia;
      _cargandoLocalidades = true;
      _cargarLocalidades(dir.provincia);
    }
    _cargarProvincias();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _calleCtrl.dispose();
    _numeroCtrl.dispose();
    _cpCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarProvincias() async {
    try {
      final lista = await GeorefService().provincias();
      if (!mounted) return;
      setState(() {
        _provincias = lista;
        _provinciasDeGeoref = true;
        if (_provincia != null && !lista.contains(_provincia)) _provincia = null;
      });
    } catch (e) {
      debugPrint('Georef no respondió, se usa la lista de respaldo: $e');
    }
  }

  Future<void> _cargarLocalidades(String provincia) async {
    try {
      final lista = await GeorefService().localidades(provincia);
      if (!mounted || _provincia != provincia) return;
      setState(() => _localidades = lista);
    } catch (e) {
      debugPrint('No se pudieron cargar las localidades: $e');
    } finally {
      if (mounted) setState(() => _cargandoLocalidades = false);
    }
  }

  void _elegirProvincia(String? provincia) {
    if (provincia == null) return;
    setState(() {
      _provincia = provincia;
      _localidad = '';
      _localidades = [];
      _cargandoLocalidades = true;
    });
    _cargarLocalidades(provincia);
  }

  OpcionEnvio? _envio(double subtotalConDescuento) {
    if (_metodo == 'retiro') return EnvioService.retiro;
    final provincia = _provincia;
    if (provincia == null) return null;
    return EnvioService().cotizarDomicilio(provincia: provincia, subtotal: subtotalConDescuento);
  }

  Future<void> _confirmar() async {
    final carrito = context.read<CarritoProvider>();
    final sesion = context.read<SesionProvider>();
    final cotizacion = context.read<CotizacionProvider>().cotizacion;
    final usuario = sesion.usuario;
    if (usuario == null || carrito.estaVacio) return;

    if (!_form.currentState!.validate()) return;
    final envio = _envio(carrito.totalSinEnvio);
    if (envio == null) {
      mostrarMensaje(context, 'Elegí la provincia de envío.');
      return;
    }

    setState(() => _procesando = true);
    try {
      final direccion = _metodo == 'domicilio'
          ? Direccion(
              calle: _calleCtrl.text.trim(),
              numero: _numeroCtrl.text.trim(),
              localidad: _localidad.trim(),
              provincia: _provincia!,
              codigoPostal: _cpCtrl.text.trim(),
            )
          : null;

      if (_guardarDatos) {
        try {
          await UsuariosService().actualizarDatos(
            usuario.uid,
            nombre: _nombreCtrl.text.trim(),
            telefono: _telefonoCtrl.text.trim(),
            direccion: direccion,
          );
        } catch (e) {
          debugPrint('No se pudieron guardar los datos del perfil: $e');
        }
      }

      final cupon = carrito.cupon;
      final pedidoId = await PedidosService().crearPedido(
        uid: usuario.uid,
        email: usuario.email ?? sesion.perfil?.email ?? '',
        nombre: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        items: carrito.items,
        cuponCodigo: (cupon != null && carrito.descuento > 0) ? cupon.codigo : null,
        envio: envio,
        direccion: direccion,
        cotizacionDolar: cotizacion?.venta,
        modoPago: _pago.modoPrueba ? 'prueba' : 'real',
      );

      // El stock ya quedó reservado en el pedido: vaciamos el carrito.
      carrito.vaciar();
      if (!mounted) return;

      if (_pago.modoPrueba) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PagoPruebaScreen(pedidoId: pedidoId)),
        );
        return;
      }

      try {
        await _pago.irAMercadoPago(pedidoId);
      } catch (e) {
        if (!mounted) return;
        mostrarMensaje(context, 'Tu pedido quedó creado, pero no se pudo abrir Mercado Pago: $e');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PedidoDetalleScreen(pedidoId: pedidoId)),
        );
      }
    } on PedidoException catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No pudimos confirmar tu compra'),
          content: Text(e.mensaje),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Revisar carrito'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'Ocurrió un error al crear el pedido: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    final carrito = context.watch<CarritoProvider>();

    if (sesion.usuario == null) {
      return Scaffold(
        appBar: const BarraNavegacion(),
        body: EstadoVacio(
          icono: Icons.lock_outline,
          titulo: 'INICIÁ SESIÓN',
          texto: 'Necesitás una cuenta para finalizar la compra.',
          textoBoton: 'INGRESAR',
          alPresionar: () => asegurarSesion(context),
        ),
      );
    }
    if (carrito.estaVacio) {
      return Scaffold(
        appBar: const BarraNavegacion(),
        body: _procesando
            ? const Center(child: CircularProgressIndicator())
            : EstadoVacio(
                icono: Icons.shopping_bag_outlined,
                titulo: 'TU CARRITO ESTÁ VACÍO',
                textoBoton: 'VER BOTINES',
                alPresionar: () => irACatalogo(context),
              ),
      );
    }

    return Scaffold(
      appBar: const BarraNavegacion(),
      body: Form(
        key: _form,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final grande = constraints.maxWidth >= 900;
            final datos = _datos(sesion);
            final resumen = _resumen(carrito);
            return SingleChildScrollView(
              padding: EdgeInsets.all(grande ? 40 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FINALIZAR COMPRA', style: Tema.titulo(grande ? 52 : 38)),
                      const SizedBox(height: 24),
                      grande
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: datos),
                                const SizedBox(width: 40),
                                Expanded(flex: 2, child: resumen),
                              ],
                            )
                          : Column(children: [datos, const SizedBox(height: 24), resumen]),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _datos(SesionProvider sesion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Paso(
          numero: 1,
          titulo: 'DATOS DE CONTACTO',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre y apellido'),
                validator: (v) => (v ?? '').trim().length < 3 ? 'Ingresá tu nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  hintText: '11 2345 6789',
                ),
                validator: (v) {
                  final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  return digitos.length < 8 ? 'Ingresá un teléfono válido' : null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Te enviamos la confirmación a ${sesion.usuario?.email ?? ''}',
                style: const TextStyle(color: Tema.grisTexto, fontSize: 13),
              ),
            ],
          ),
        ),
        _Paso(
          numero: 2,
          titulo: 'ENTREGA',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OpcionEntrega(
                titulo: 'Envío a domicilio',
                detalle: 'A todo el país. ${EnvioService.textoEnvioGratis}.',
                icono: Icons.local_shipping_outlined,
                seleccionada: _metodo == 'domicilio',
                alPresionar: () => setState(() => _metodo = 'domicilio'),
              ),
              const SizedBox(height: 8),
              _OpcionEntrega(
                titulo: 'Retiro en el local',
                detalle: 'Sin costo. ${EnvioService.retiro.demora}.',
                icono: Icons.storefront_outlined,
                seleccionada: _metodo == 'retiro',
                alPresionar: () => setState(() => _metodo = 'retiro'),
              ),
              if (_metodo == 'domicilio') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  // initialValue se lee una sola vez: la key hace que el campo se
                  // rearme cuando llega la lista de Georef o cambia la provincia.
                  key: ValueKey('prov-${_provincias.length}-$_provincia'),
                  // Solo se pasa si está en la lista (si no, Flutter tira error).
                  initialValue: _provincias.contains(_provincia) ? _provincia : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Provincia'),
                  items: [
                    for (final p in _provincias) DropdownMenuItem(value: p, child: Text(p)),
                  ],
                  onChanged: _elegirProvincia,
                  validator: (v) => v == null ? 'Elegí la provincia' : null,
                ),
                if (!_provinciasDeGeoref)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Usando la lista de provincias de respaldo (Georef no respondió).',
                      style: TextStyle(fontSize: 12, color: Tema.grisTexto),
                    ),
                  ),
                const SizedBox(height: 12),
                Autocomplete<String>(
                  key: ValueKey('localidades-$_provincia'),
                  initialValue: TextEditingValue(text: _localidad),
                  optionsBuilder: (valor) {
                    final q = FiltrosCatalogo.normalizar(valor.text);
                    if (q.isEmpty) return const Iterable<String>.empty();
                    return _localidades
                        .where((l) => FiltrosCatalogo.normalizar(l).contains(q))
                        .take(20);
                  },
                  onSelected: (v) => _localidad = v,
                  fieldViewBuilder: (context, controller, foco, alEnviar) => TextFormField(
                    controller: controller,
                    focusNode: foco,
                    decoration: InputDecoration(
                      labelText: 'Localidad',
                      helperText: _provincia == null
                          ? 'Primero elegí la provincia'
                          : 'Empezá a escribir y elegí de la lista',
                      suffixIcon: _cargandoLocalidades
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (v) => _localidad = v,
                    onFieldSubmitted: (_) => alEnviar(),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Ingresá la localidad' : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _calleCtrl,
                        decoration: const InputDecoration(labelText: 'Calle'),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Ingresá la calle' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _numeroCtrl,
                        decoration: const InputDecoration(labelText: 'Número'),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Falta' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cpCtrl,
                  decoration: const InputDecoration(labelText: 'Código postal'),
                  validator: (v) =>
                      (v ?? '').trim().length < 4 ? 'Ingresá el código postal' : null,
                ),
              ],
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _guardarDatos,
                onChanged: (v) => setState(() => _guardarDatos = v ?? false),
                title: const Text('Guardar estos datos en mi perfil'),
              ),
            ],
          ),
        ),
        _Paso(
          numero: 3,
          titulo: 'PAGO',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Tema.negro, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Mercado Pago',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    if (_pago.modoPrueba)
                      const EtiquetaChica('MODO PRUEBA', fondo: Tema.naranja),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _pago.modoPrueba
                      ? 'No hay credenciales de Mercado Pago configuradas: el pago se '
                          'simula en la pantalla siguiente y no se cobra dinero.'
                      : 'Te vamos a llevar al checkout de Mercado Pago para pagar con '
                          'tarjeta, dinero en cuenta u otros medios.',
                  style: const TextStyle(color: Tema.grisTexto),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _resumen(CarritoProvider carrito) {
    final envio = _envio(carrito.totalSinEnvio);
    final total = carrito.totalSinEnvio + (envio?.costo ?? 0);
    final usd = context.watch<CotizacionProvider>().enUsd(total);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Tema.grisFondo, borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('TU PEDIDO', style: Tema.titulo(30)),
          const SizedBox(height: 12),
          for (final item in carrito.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${item.cantidad} x ${item.nombre} · talle ${item.talle}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(precioArs(item.subtotal), style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          const Divider(height: 24),
          FilaResumen('Subtotal', precioArs(carrito.subtotal)),
          if (carrito.descuento > 0)
            FilaResumen(
              'Cupón ${carrito.cupon?.codigo ?? ''}',
              '- ${precioArs(carrito.descuento)}',
              colorValor: Tema.verdeOk,
            ),
          FilaResumen(
            'Envío',
            envio == null
                ? 'Elegí la provincia'
                : (envio.costo == 0 ? 'Gratis' : precioArs(envio.costo)),
            colorValor: envio != null && envio.costo == 0 ? Tema.verdeOk : null,
          ),
          if (envio != null)
            Text(envio.demora, style: const TextStyle(fontSize: 12, color: Tema.grisTexto)),
          const Divider(height: 24),
          FilaResumen('Total', precioArs(total), destacado: true),
          if (usd != null)
            Text(
              '≈ ${precioUsd(usd)} al dólar oficial',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Tema.grisTexto),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _procesando ? null : _confirmar,
            child: _procesando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('PAGAR CON MERCADO PAGO'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Al confirmar, reservamos el stock de tus botines.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Tema.grisTexto),
          ),
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.titulo, required this.child});

  final int numero;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Tema.negro,
                child: Text(
                  '$numero',
                  style: const TextStyle(color: Tema.verde, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Text(titulo, style: Tema.titulo(26)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _OpcionEntrega extends StatelessWidget {
  const _OpcionEntrega({
    required this.titulo,
    required this.detalle,
    required this.icono,
    required this.seleccionada,
    required this.alPresionar,
  });

  final String titulo;
  final String detalle;
  final IconData icono;
  final bool seleccionada;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alPresionar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: seleccionada ? Tema.negro : Tema.grisBorde,
            width: seleccionada ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              seleccionada ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            ),
            const SizedBox(width: 12),
            Icon(icono),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(detalle, style: const TextStyle(color: Tema.grisTexto, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
