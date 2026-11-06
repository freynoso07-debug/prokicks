import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../services/envio_service.dart';

/// Guía de talles (aproximada) en un diálogo.
Future<void> mostrarGuiaTalles(BuildContext context) {
  const filas = [
    ['38', '6', '24,0'],
    ['39', '7', '24,8'],
    ['40', '7,5', '25,5'],
    ['41', '8,5', '26,2'],
    ['42', '9', '27,0'],
    ['43', '10', '27,8'],
    ['44', '10,5', '28,5'],
    ['45', '11,5', '29,2'],
  ];
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('GUÍA DE TALLES', style: Tema.titulo(28)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medí tu pie desde el talón hasta el dedo más largo y elegí el talle '
              'cuyo largo sea igual o apenas mayor.',
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Tema.grisBorde),
              children: [
                _filaTabla(const ['AR', 'US', 'Largo (cm)'], encabezado: true),
                for (final f in filas) _filaTabla(f),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    ),
  );
}

TableRow _filaTabla(List<String> celdas, {bool encabezado = false}) {
  return TableRow(
    decoration: BoxDecoration(color: encabezado ? Tema.negro : null),
    children: [
      for (final c in celdas)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            c,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: encabezado ? Colors.white : Tema.negro,
              fontWeight: encabezado ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
    ],
  );
}

enum TemaAyuda { envios, cambios, pagos }

/// Información de ayuda del pie de página.
Future<void> mostrarAyuda(BuildContext context, TemaAyuda tema) {
  late final String titulo;
  late final String texto;
  switch (tema) {
    case TemaAyuda.envios:
      titulo = 'ENVÍOS';
      texto = 'Hacemos envíos a todo el país. El costo se calcula en el checkout según '
          'la provincia. ${EnvioService.textoEnvioGratis}. También podés retirar '
          'tu compra en el local sin costo.';
      break;
    case TemaAyuda.cambios:
      titulo = 'CAMBIOS Y DEVOLUCIONES';
      texto = 'Tenés 30 días desde que recibís tu compra para cambiar el talle o el '
          'modelo. El botín tiene que estar sin uso y en su caja original.';
      break;
    case TemaAyuda.pagos:
      titulo = 'MEDIOS DE PAGO';
      texto = 'Pagás con Mercado Pago: tarjetas de crédito y débito, dinero en cuenta '
          'y otros medios disponibles. Hasta 6 cuotas sin interés con tarjetas '
          'seleccionadas.';
      break;
  }
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo, style: Tema.titulo(28)),
      content: SizedBox(width: 380, child: Text(texto)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
      ],
    ),
  );
}
