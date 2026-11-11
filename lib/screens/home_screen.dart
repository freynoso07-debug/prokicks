import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../models/catalogo.dart';
import '../models/filtros.dart';
import '../models/producto.dart';
import '../providers/sesion_provider.dart';
import '../services/envio_service.dart';
import '../utils/navegacion.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/botin_imagen.dart';
import '../widgets/comunes.dart';
import '../widgets/pie_de_pagina.dart';
import '../widgets/seccion_productos.dart';
import 'admin/admin_screen.dart';
import 'pedido_detalle_screen.dart';

/// Página principal de la tienda.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _revisarRetornoDePago(),
    );
  }

  /// Cuando Mercado Pago termina, vuelve a la tienda con ?pedido=ID en la URL.
  /// Si viene ese dato, abrimos el detalle del pedido.
  Future<void> _revisarRetornoDePago() async {
    final parametros = Uri.base.queryParameters;
    final pedidoId = parametros['pedido'] ?? parametros['external_reference'];
    if (pedidoId == null || pedidoId.isEmpty) return;

    final usuario = await FirebaseAuth.instance.authStateChanges().first;
    if (usuario == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PedidoDetalleScreen(pedidoId: pedidoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<List<Producto>?>();
    final activos = todos?.where((p) => p.activo).toList();

    return Scaffold(
      appBar: const BarraNavegacion(),
      body: ListView(
        children: [
          const _Hero(),
          const _Beneficios(),
          if (activos == null)
            const Padding(
              padding: EdgeInsets.all(64),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (activos.isEmpty)
            const _SinProductos()
          else ...[
            SeccionProductos(
              titulo: 'DESTACADOS',
              subtitulo: 'Los botines que más piden los jugadores.',
              productos: activos.where((p) => p.destacado).take(10).toList(),
              filtrosVerTodo: const FiltrosCatalogo(soloDestacados: true),
            ),
            const _Superficies(),
            SeccionProductos(
              titulo: 'NUEVOS LANZAMIENTOS',
              subtitulo: 'Lo último que llegó a la tienda.',
              productos: _nuevos(activos),
              filtrosVerTodo: const FiltrosCatalogo(
                soloNuevos: true,
                orden: OrdenCatalogo.novedades,
              ),
            ),
            const _BannerOfertas(),
            SeccionProductos(
              titulo: 'OFERTAS',
              subtitulo: 'Descuentos por tiempo limitado.',
              productos: _ofertas(activos),
              filtrosVerTodo: const FiltrosCatalogo(soloOfertas: true),
            ),
            const _Marcas(),
          ],
          const PieDePagina(),
        ],
      ),
    );
  }

  List<Producto> _nuevos(List<Producto> activos) {
    final lista = activos.where((p) => p.nuevo).toList();
    final viejo = DateTime(2000);
    lista.sort((a, b) => (b.creadoEn ?? viejo).compareTo(a.creadoEn ?? viejo));
    return lista.take(10).toList();
  }

  List<Producto> _ofertas(List<Producto> activos) {
    final lista = activos.where((p) => p.enOferta).toList();
    lista.sort((a, b) => b.descuento.compareTo(a.descuento));
    return lista.take(10).toList();
  }
}

// ---------------------------------------------------------------------------
// Banner principal
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth >= 900;
        final texto = TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - v)),
              child: child,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NUEVA TEMPORADA 2026',
                style: Tema.etiqueta(color: Tema.verde, tamanio: 13),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'ELEVÁ\n',
                      style: Tema.titulo(ancho ? 120 : 72, color: Colors.white),
                    ),
                    TextSpan(
                      text: 'TU JUEGO',
                      style: Tema.titulo(ancho ? 120 : 72, color: Tema.verde),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 460,
                child: Text(
                  'Botines de Nike, Adidas, Puma, New Balance y Mizuno para cada superficie. '
                  'Envíos a todo el país y hasta 6 cuotas sin interés.',
                  style: TextStyle(
                    color: Color(0xFFCFCFCF),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Tema.verde,
                      foregroundColor: Tema.negro,
                    ),
                    onPressed: () => irACatalogo(context),
                    child: const Text('COMPRAR AHORA'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    onPressed: () => irACatalogo(
                      context,
                      filtros: const FiltrosCatalogo(soloOfertas: true),
                    ),
                    child: const Text('VER OFERTAS'),
                  ),
                ],
              ),
            ],
          ),
        );

        return Container(
          color: Tema.negro,
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: ancho ? 72 : 40,
          ),
          child: ancho
              ? Row(
                  children: [
                    Expanded(child: texto),
                    const Expanded(
                      child: SizedBox(height: 380, child: _BotinFlotante()),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    texto,
                    const SizedBox(height: 24),
                    const SizedBox(height: 220, child: _BotinFlotante()),
                  ],
                ),
        );
      },
    );
  }
}

/// Foto del banner con una animación de "vuelo":
/// - el botín planea: sube y baja, avanza un poco y se inclina como si cortara el aire;
/// - abajo hay una sombra que se achica cuando sube (da sensación de altura);
/// - a la izquierda, líneas de velocidad que salen hacia atrás en loop.
///
/// La foto es un asset (assets/images/botin_banner.png, registrado en pubspec.yaml),
/// así que no depende de internet. Si no se pudiera cargar, se usa el dibujo de siempre.
class _BotinFlotante extends StatefulWidget {
  const _BotinFlotante();

  @override
  State<_BotinFlotante> createState() => _BotinFlotanteState();
}

class _BotinFlotanteState extends State<_BotinFlotante>
    with TickerProviderStateMixin {
  // Planeo: va y vuelve (0 → 1 → 0) cada 2,4 segundos.
  late final AnimationController _vuelo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  // Líneas de velocidad: corren siempre hacia adelante (0 → 1, y vuelve a empezar).
  late final AnimationController _lineas = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Si el usuario pidió "reducir movimiento" en su sistema, el botín queda quieto.
    if (MediaQuery.of(context).disableAnimations) {
      _vuelo.stop();
      _lineas.stop();
    } else {
      if (!_vuelo.isAnimating) _vuelo.repeat(reverse: true);
      if (!_lineas.isAnimating) _lineas.repeat();
    }
  }

  @override
  void dispose() {
    _vuelo.dispose();
    _lineas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final alto = constraints.maxHeight;
        return AnimatedBuilder(
          animation: Listenable.merge([_vuelo, _lineas]),
          child: Image.asset(
            'assets/images/botin_banner.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            // Respaldo: si el asset falla, se ve el dibujo hecho con CustomPainter.
            errorBuilder: (context, error, stack) => const BotinImagen(
              colores: ['Negro', 'Dorado'],
              superficie: 'FG',
              padding: EdgeInsets.all(8),
            ),
          ),
          builder: (context, foto) {
            final t = Curves.easeInOut.transform(
              _vuelo.value,
            ); // 0 = abajo, 1 = arriba
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Líneas de velocidad detrás del botín.
                Positioned.fill(child: _LineasVelocidad(avance: _lineas.value)),
                // Sombra en el "piso": más chica y más clara cuanto más alto vuela.
                Positioned(
                  bottom: alto * 0.02,
                  child: Opacity(
                    opacity: 0.6 - 0.3 * t,
                    // Un círculo con degradé, aplastado en vertical = elipse difusa.
                    // (Un RadialGradient en un rectángulo bajo queda como un puntito,
                    // porque el radio se calcula sobre el lado más corto.)
                    child: Transform.scale(
                      scaleY: 0.12,
                      alignment:
                          Alignment.bottomCenter, // se aplasta contra el piso

                      child: Container(
                        width: alto * (0.75 - 0.25 * t),
                        height: alto * (0.75 - 0.25 * t),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Tema.verde.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // El botín: sube hasta un 7% del alto, avanza unos píxeles hacia
                // adelante y gira un poquito (la punta baja cuando sube).
                Transform.translate(
                  offset: Offset(
                    8 * math.sin(_vuelo.value * math.pi),
                    -alto * 0.07 * t,
                  ),
                  child: Transform.rotate(
                    angle: -0.05 + 0.08 * t,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: alto * 0.08),
                      child: foto,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Tres líneas verdes que salen desde el botín hacia la izquierda y se
/// desvanecen. Cada una va desfasada para que el movimiento sea continuo.
class _LineasVelocidad extends StatelessWidget {
  const _LineasVelocidad({required this.avance});

  /// 0 a 1, viene del controlador de las líneas.
  final double avance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final alto = constraints.maxHeight;
        // (altura relativa, largo relativo, desfase)
        const lineas = [
          (0.38, 0.30, 0.0),
          (0.52, 0.45, 0.35),
          (0.66, 0.22, 0.7),
        ];
        return Stack(
          children: [
            for (final (y, largo, desfase) in lineas)
              Builder(
                builder: (context) {
                  final p =
                      (avance + desfase) %
                      1; // posición de esta línea en su ciclo
                  return Positioned(
                    top: alto * y,
                    // Arranca pegada al botín (40% del ancho) y se va 25% hacia la izquierda.
                    left: ancho * (0.40 - largo) - ancho * 0.25 * p,
                    child: Opacity(
                      opacity: (1 - p).clamp(0.0, 1.0).toDouble(),
                      child: Container(
                        width: ancho * largo,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [Colors.transparent, Tema.verde],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Beneficios
// ---------------------------------------------------------------------------

class _Beneficios extends StatelessWidget {
  const _Beneficios();

  @override
  Widget build(BuildContext context) {
    final beneficios = [
      (
        Icons.local_shipping_outlined,
        'Envíos a todo el país',
        EnvioService.textoEnvioGratis,
      ),
      (
        Icons.credit_card,
        'Hasta 6 cuotas sin interés',
        'Pagando con Mercado Pago',
      ),
      (Icons.autorenew, 'Cambios gratis', '30 días para cambiar el talle'),
    ];
    return Container(
      color: Tema.verde,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 32,
        runSpacing: 16,
        children: [
          for (final b in beneficios)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(b.$1, color: Tema.negro, size: 30),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.$2,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(b.$3, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Categorías por superficie
// ---------------------------------------------------------------------------

class _Superficies extends StatelessWidget {
  const _Superficies();

  @override
  Widget build(BuildContext context) {
    final chico = MediaQuery.sizeOf(context).width < 600;
    return Container(
      color: Tema.grisFondo,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMPRÁ POR SUPERFICIE', style: Tema.titulo(chico ? 32 : 44)),
          const SizedBox(height: 4),
          const Text(
            'Cada cancha pide una suela distinta.',
            style: TextStyle(color: Tema.grisTexto),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final e in Catalogo.superficies.entries)
                _TarjetaHover(
                  ancho: chico ? double.infinity : 220,
                  alPresionar: () => irACatalogo(
                    context,
                    filtros: FiltrosCatalogo(superficies: {e.key}),
                  ),
                  constructor: (hover) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: Tema.titulo(
                          48,
                          color: hover ? Tema.negro : Tema.verde,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        e.value.toUpperCase(),
                        style: TextStyle(
                          color: hover ? Tema.negro : Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Catalogo.superficiesDetalle[e.key] ?? '',
                        style: TextStyle(
                          color: hover ? Tema.negro : const Color(0xFFBDBDBD),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta negra que se pone verde al pasar el mouse.
class _TarjetaHover extends StatefulWidget {
  const _TarjetaHover({
    required this.ancho,
    required this.alPresionar,
    required this.constructor,
  });

  final double ancho;
  final VoidCallback alPresionar;
  final Widget Function(bool hover) constructor;

  @override
  State<_TarjetaHover> createState() => _TarjetaHoverState();
}

class _TarjetaHoverState extends State<_TarjetaHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.alPresionar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.ancho,
          height: 170,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _hover ? Tema.verde : Tema.negro,
            borderRadius: BorderRadius.circular(6),
          ),
          child: widget.constructor(_hover),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Banner de ofertas y marcas
// ---------------------------------------------------------------------------

class _BannerOfertas extends StatelessWidget {
  const _BannerOfertas();

  @override
  Widget build(BuildContext context) {
    final chico = MediaQuery.sizeOf(context).width < 600;
    return Container(
      color: Tema.naranja,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HASTA 20% OFF',
                style: Tema.titulo(chico ? 40 : 56, color: Colors.white),
              ),
              const Text(
                'Usá el cupón BIENVENIDA10 en tu primera compra.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Tema.negro,
              foregroundColor: Colors.white,
            ),
            onPressed: () => irACatalogo(
              context,
              filtros: const FiltrosCatalogo(soloOfertas: true),
            ),
            child: const Text('VER OFERTAS'),
          ),
        ],
      ),
    );
  }
}

class _Marcas extends StatelessWidget {
  const _Marcas();

  @override
  Widget build(BuildContext context) {
    final chico = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MARCAS DESTACADAS', style: Tema.titulo(chico ? 32 : 44)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final marca in Catalogo.marcas)
                _TarjetaHover(
                  ancho: chico ? double.infinity : 210,
                  alPresionar: () => irACatalogo(
                    context,
                    filtros: FiltrosCatalogo(marcas: {marca}),
                  ),
                  constructor: (hover) => Center(
                    child: Text(
                      marca.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: Tema.titulo(
                        34,
                        color: hover ? Tema.negro : Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SinProductos extends StatelessWidget {
  const _SinProductos();

  @override
  Widget build(BuildContext context) {
    final esAdmin = context.watch<SesionProvider>().esAdmin;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: EstadoVacio(
        icono: Icons.inventory_2_outlined,
        titulo: 'TODAVÍA NO HAY PRODUCTOS',
        texto: esAdmin
            ? 'Cargá los datos de ejemplo desde el panel de administración.'
            : 'La tienda se está preparando. Volvé en un rato.',
        textoBoton: esAdmin ? 'IR AL PANEL' : null,
        alPresionar: esAdmin
            ? () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AdminScreen()))
            : null,
      ),
    );
  }
}
