import 'package:cloud_firestore/cloud_firestore.dart';

import 'envio.dart';
import 'item_carrito.dart';
import 'usuario.dart';

/// Estados por los que pasa un pedido.
class EstadosPedido {
  static const pendientePago = 'pendiente_pago';
  static const pagado = 'pagado';
  static const preparando = 'preparando';
  static const enviado = 'enviado';
  static const entregado = 'entregado';
  static const cancelado = 'cancelado';

  static const todos = [pendientePago, pagado, preparando, enviado, entregado, cancelado];

  /// Recorrido "normal" de un pedido (sin cancelación).
  static const recorrido = [pendientePago, pagado, preparando, enviado, entregado];

  static String nombre(String estado) {
    const nombres = {
      pendientePago: 'Pendiente de pago',
      pagado: 'Pagado',
      preparando: 'Preparando',
      enviado: 'Enviado',
      entregado: 'Entregado',
      cancelado: 'Cancelado',
    };
    return nombres[estado] ?? estado;
  }
}

/// Estados del pago (los mismos que usa Mercado Pago, traducidos).
class EstadosPago {
  static const pendiente = 'pendiente';
  static const aprobado = 'aprobado';
  static const rechazado = 'rechazado';

  static String nombre(String estado) {
    const nombres = {
      pendiente: 'Pago pendiente',
      aprobado: 'Pago aprobado',
      rechazado: 'Pago rechazado',
    };
    return nombres[estado] ?? estado;
  }
}

/// Documento de la colección `pedidos`.
class Pedido {
  final String id;
  final String uid;
  final String email;
  final String nombre;
  final String telefono;
  final List<ItemCarrito> items;
  final double subtotal;
  final double descuento;
  final String? cuponCodigo;
  final OpcionEnvio envio;
  final Direccion? direccion;
  final double total;
  final String estado;
  final String estadoPago;
  final String modoPago; // 'prueba' o 'real'
  final String? referenciaPago;
  final double? cotizacionDolar;
  final bool emailEnviado;
  final DateTime? creadoEn;

  const Pedido({
    required this.id,
    required this.uid,
    required this.email,
    required this.nombre,
    required this.telefono,
    required this.items,
    required this.subtotal,
    required this.descuento,
    required this.cuponCodigo,
    required this.envio,
    required this.direccion,
    required this.total,
    required this.estado,
    required this.estadoPago,
    required this.modoPago,
    required this.referenciaPago,
    required this.cotizacionDolar,
    required this.emailEnviado,
    required this.creadoEn,
  });

  int get cantidadProductos => items.fold<int>(0, (s, i) => s + i.cantidad);

  String get numeroCorto => (id.length >= 8 ? id.substring(0, 8) : id).toUpperCase();

  bool get pagoAprobado => estadoPago == EstadosPago.aprobado;

  /// Se puede (re)intentar pagar.
  bool get puedePagar => estado == EstadosPedido.pendientePago && !pagoAprobado;

  bool get puedeCancelar => estado == EstadosPedido.pendientePago && !pagoAprobado;

  factory Pedido.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final pago = Map<String, dynamic>.from(d['pago'] as Map? ?? const {});
    final envio = d['envio'];
    final direccion = d['direccion'];

    return Pedido(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      email: d['email'] as String? ?? '',
      nombre: d['nombre'] as String? ?? '',
      telefono: d['telefono'] as String? ?? '',
      items: ItemCarrito.listaDesde(d['items']),
      subtotal: (d['subtotal'] as num?)?.toDouble() ?? 0,
      descuento: (d['descuento'] as num?)?.toDouble() ?? 0,
      cuponCodigo: d['cuponCodigo'] as String?,
      envio: OpcionEnvio.fromMap(envio == null ? null : Map<String, dynamic>.from(envio as Map)),
      direccion: direccion == null
          ? null
          : Direccion.fromMap(Map<String, dynamic>.from(direccion as Map)),
      total: (d['total'] as num?)?.toDouble() ?? 0,
      estado: d['estado'] as String? ?? EstadosPedido.pendientePago,
      estadoPago: pago['estado'] as String? ?? EstadosPago.pendiente,
      modoPago: pago['modo'] as String? ?? 'prueba',
      referenciaPago: pago['referencia'] as String?,
      cotizacionDolar: (d['cotizacionDolar'] as num?)?.toDouble(),
      emailEnviado: d['emailEnviado'] as bool? ?? false,
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
    );
  }
}
