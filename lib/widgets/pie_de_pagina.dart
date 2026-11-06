import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/tema.dart';
import '../models/catalogo.dart';
import '../models/filtros.dart';
import '../utils/navegacion.dart';
import 'comunes.dart';
import 'dialogos_info.dart';

/// Footer con categorías, ayuda, contacto y redes.
class PieDePagina extends StatelessWidget {
  const PieDePagina({super.key});

  static const String emailContacto = 'hola@prokicks.com.ar';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Tema.negro,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 56,
            runSpacing: 32,
            children: [
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    LogoProKicks(tamanio: 32),
                    SizedBox(height: 12),
                    Text(
                      'Botines de fútbol de las mejores marcas para cada superficie. '
                      'Elevá tu juego.',
                      style: TextStyle(color: Color(0xFFB5B5B5), height: 1.5),
                    ),
                    SizedBox(height: 16),
                    _Red(icono: Icons.camera_alt_outlined, texto: 'Instagram · @prokicks.ar'),
                    _Red(icono: Icons.facebook, texto: 'Facebook · /prokicks.ar'),
                    _Red(icono: Icons.play_circle_outline, texto: 'YouTube · @prokicks'),
                  ],
                ),
              ),
              _Columna(
                titulo: 'COMPRAR',
                enlaces: [
                  for (final e in Catalogo.superficies.entries)
                    _Enlace(
                      'Botines ${e.key} · ${e.value}',
                      () => irACatalogo(
                        context,
                        filtros: FiltrosCatalogo(superficies: {e.key}),
                      ),
                    ),
                  _Enlace(
                    'Ofertas',
                    () => irACatalogo(context, filtros: const FiltrosCatalogo(soloOfertas: true)),
                  ),
                ],
              ),
              _Columna(
                titulo: 'AYUDA',
                enlaces: [
                  _Enlace('Envíos', () => mostrarAyuda(context, TemaAyuda.envios)),
                  _Enlace('Cambios y devoluciones', () => mostrarAyuda(context, TemaAyuda.cambios)),
                  _Enlace('Medios de pago', () => mostrarAyuda(context, TemaAyuda.pagos)),
                  _Enlace('Guía de talles', () => mostrarGuiaTalles(context)),
                ],
              ),
              _Columna(
                titulo: 'CONTACTO',
                enlaces: [
                  _Enlace(
                    emailContacto,
                    () => launchUrl(Uri.parse('mailto:$emailContacto')),
                  ),
                ],
                extra: const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Atención de lunes a viernes de 9 a 18 h.',
                    style: TextStyle(color: Color(0xFFB5B5B5)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(color: Color(0xFF2A2A2A)),
          const SizedBox(height: 16),
          const Text(
            '© 2026 PROKICKS · Proyecto académico: productos, precios y datos de contacto de ejemplo.',
            style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Enlace {
  const _Enlace(this.texto, this.alPresionar);
  final String texto;
  final VoidCallback alPresionar;
}

class _Columna extends StatelessWidget {
  const _Columna({required this.titulo, required this.enlaces, this.extra});

  final String titulo;
  final List<_Enlace> enlaces;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Tema.etiqueta(color: Tema.verde, tamanio: 13)),
          const SizedBox(height: 12),
          for (final e in enlaces)
            InkWell(
              onTap: e.alPresionar,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(e.texto, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ?extra,
        ],
      ),
    );
  }
}

class _Red extends StatelessWidget {
  const _Red({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icono, color: Tema.verde, size: 18),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(color: Color(0xFFB5B5B5))),
        ],
      ),
    );
  }
}
