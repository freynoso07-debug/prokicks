import 'package:flutter/foundation.dart';

import '../models/pedido.dart';
import '../utils/formato.dart';
import 'email_service.dart';
import 'pedidos_service.dart';

/// Arma y manda el mail de confirmación de compra.
class NotificacionesService {
  final EmailService _email = EmailService();
  final PedidosService _pedidos = PedidosService();

  /// Manda el mail solo si el pago está aprobado y todavía no se mandó.
  /// Sirve igual para el modo prueba y para Mercado Pago real.
  Future<bool> enviarConfirmacionSiCorresponde(Pedido p) async {
    if (p.emailEnviado || !p.pagoAprobado) return false;

    // El template de EmailJS es HTML: los saltos de línea (\n) se ignoran,
    // así que cada producto se separa con <br>. En el template esta variable
    // va con TRES llaves, {{{order_detail}}}, para que EmailJS no escape el HTML.
    final detalle = p.items
        .map((i) => '${i.cantidad} x ${i.nombre} (talle ${i.talle}) — ${precioArs(i.subtotal)}')
        .join('<br>');
    final entrega = p.envio.esRetiro
        ? 'Retiro en el local'
        : 'Envío a ${p.direccion?.texto ?? ''} (${p.envio.demora})';

    final enviado = await _email.enviar({
      'to_email': p.email,
      'to_name': p.nombre,
      'order_id': p.numeroCorto,
      'order_detail': detalle,
      'order_total': precioArs(p.total),
      'order_delivery': entrega,
    });

    if (enviado) {
      try {
        await _pedidos.marcarEmailEnviado(p.id);
      } catch (e) {
        debugPrint('No se pudo marcar el mail como enviado: $e');
      }
    }
    return enviado;
  }
}
