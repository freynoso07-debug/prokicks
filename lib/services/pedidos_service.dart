import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cupon.dart';
import '../models/envio.dart';
import '../models/item_carrito.dart';
import '../models/pedido.dart';
import '../models/producto.dart';
import '../models/usuario.dart';
import 'envio_service.dart';

class PedidoException implements Exception {
  final String mensaje;
  const PedidoException(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Pedidos (colección `pedidos`). Equivalente a POST/GET /api/orders.
class PedidosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pedidos =>
      _db.collection('pedidos');
  CollectionReference<Map<String, dynamic>> get _productos =>
      _db.collection('productos');
  CollectionReference<Map<String, dynamic>> get _cupones =>
      _db.collection('cupones');

  /// Crea el pedido dentro de una TRANSACCIÓN de Firestore:
  ///
  /// 1. Lee el stock y el precio ACTUAL de cada botín (no confía en el carrito).
  /// 2. Valida que alcance el stock de cada talle y que el cupón siga vigente.
  /// 3. Descuenta el stock, suma las ventas, cuenta el uso del cupón y crea
  ///    el pedido.
  ///
  /// Si dos personas compran el último par al mismo tiempo, Firestore reintenta
  /// la transacción y la segunda recibe "stock insuficiente". Nunca se vende
  /// más de lo que hay.
  Future<String> crearPedido({
    required String uid,
    required String email,
    required String nombre,
    required String telefono,
    required List<ItemCarrito> items,
    required String? cuponCodigo,
    required OpcionEnvio envio,
    required Direccion? direccion,
    required double? cotizacionDolar,
    required String modoPago,
  }) {
    if (items.isEmpty) throw const PedidoException('El carrito está vacío.');

    return _db.runTransaction<String>((tx) async {
      // ---------- 1) Lecturas (en una transacción van todas primero) ----------
      final snaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final id in items.map((i) => i.productoId).toSet()) {
        snaps[id] = await tx.get(_productos.doc(id));
      }
      DocumentSnapshot<Map<String, dynamic>>? cuponSnap;
      if (cuponCodigo != null) {
        cuponSnap = await tx.get(_cupones.doc(cuponCodigo));
      }

      // ---------- 2) Validaciones ----------
      final stocks = <String, Map<String, int>>{};
      final vendidos = <String, int>{};
      final itemsFinales = <ItemCarrito>[];

      for (final item in items) {
        final snap = snaps[item.productoId]!;
        if (!snap.exists) {
          throw PedidoException('"${item.nombre}" ya no está disponible.');
        }
        final producto = Producto.fromFirestore(snap);
        if (!producto.activo) {
          throw PedidoException('"${producto.nombre}" ya no está a la venta.');
        }

        final stock = stocks.putIfAbsent(
          producto.id,
          () => Map<String, int>.from(producto.stockPorTalle),
        );
        final disponible = stock[item.talle] ?? 0;
        if (disponible < item.cantidad) {
          throw PedidoException(
            disponible == 0
                ? 'Se agotó el talle ${item.talle} de "${producto.nombre}".'
                : 'Solo quedan $disponible del talle ${item.talle} de "${producto.nombre}".',
          );
        }
        stock[item.talle] = disponible - item.cantidad;
        vendidos[producto.id] = (vendidos[producto.id] ?? 0) + item.cantidad;
        itemsFinales.add(item.conPrecio(producto.precio));
      }

      final subtotal = itemsFinales.fold<double>(0, (s, i) => s + i.subtotal);

      double descuento = 0;
      if (cuponSnap != null) {
        if (!cuponSnap.exists) {
          throw PedidoException('El cupón $cuponCodigo ya no existe.');
        }
        final cupon = Cupon.fromFirestore(cuponSnap);
        final motivo = cupon.motivoInvalido(subtotal);
        if (motivo != null) throw PedidoException(motivo);
        descuento = cupon.descuentoPara(subtotal);
      }

      // El envío se recalcula con el subtotal real (por el envío gratis).
      final envioFinal = envio.esRetiro
          ? envio
          : EnvioService().cotizarDomicilio(
              provincia: direccion?.provincia ?? '',
              subtotal: subtotal - descuento,
            );
      final total = subtotal - descuento + envioFinal.costo;

      // ---------- 3) Escrituras ----------
      for (final id in stocks.keys) {
        tx.update(_productos.doc(id), {
          'talles': stocks[id],
          'ventas': FieldValue.increment(vendidos[id] ?? 0),
        });
      }
      if (cuponSnap != null) {
        tx.update(cuponSnap.reference, {'usos': FieldValue.increment(1)});
      }

      final ref = _pedidos.doc();
      tx.set(ref, {
        'uid': uid,
        'email': email,
        'nombre': nombre,
        'telefono': telefono,
        'items': itemsFinales.map((i) => i.toMap()).toList(),
        'cantidadProductos': itemsFinales.fold<int>(
          0,
          (s, i) => s + i.cantidad,
        ),
        'subtotal': subtotal,
        'descuento': descuento,
        'cuponCodigo': cuponCodigo,
        'envio': envioFinal.toMap(),
        'direccion': direccion?.toMap(),
        'total': total,
        'cotizacionDolar': cotizacionDolar,
        'totalUsd': cotizacionDolar == null
            ? null
            : double.parse((total / cotizacionDolar).toStringAsFixed(2)),
        'estado': EstadosPedido.pendientePago,
        'pago': {
          'metodo': 'mercadopago',
          'modo': modoPago,
          'estado': EstadosPago.pendiente,
          'referencia': null,
        },
        'emailEnviado': false,
        'creadoEn': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      return ref.id;
    });
  }

  /// Guarda el resultado del pago. En modo prueba lo llama la app; con
  /// Mercado Pago real lo hace la Cloud Function del webhook.
  Future<void> registrarPago(
    String pedidoId,
    String estadoPago,
    String referencia,
  ) {
    return _pedidos.doc(pedidoId).update({
      'pago.estado': estadoPago,
      'pago.referencia': referencia,
      if (estadoPago == EstadosPago.aprobado) 'estado': EstadosPedido.pagado,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// Cancela el pedido y DEVUELVE el stock de cada talle (en una transacción).
  Future<void> cancelar(String pedidoId) {
    return _db.runTransaction<void>((tx) async {
      final pedidoRef = _pedidos.doc(pedidoId);
      final pedidoSnap = await tx.get(pedidoRef);
      if (!pedidoSnap.exists) {
        throw const PedidoException('El pedido no existe.');
      }
      final pedido = Pedido.fromFirestore(pedidoSnap);
      if (pedido.estado == EstadosPedido.cancelado) return;

      final snaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final id in pedido.items.map((i) => i.productoId).toSet()) {
        snaps[id] = await tx.get(_productos.doc(id));
      }
      // Si el pedido usó un cupón, se devuelve ese uso (si el cupón todavía existe).
      final codigo = pedido.cuponCodigo;
      final cuponSnap = codigo == null
          ? null
          : await tx.get(_cupones.doc(codigo));

      final stocks = <String, Map<String, int>>{};
      final devueltos = <String, int>{};
      for (final item in pedido.items) {
        final snap = snaps[item.productoId]!;
        if (!snap.exists) {
          continue; // el producto se borró: no hay stock que devolver
        }
        final stock = stocks.putIfAbsent(
          item.productoId,
          () =>
              Map<String, int>.from(Producto.fromFirestore(snap).stockPorTalle),
        );
        stock[item.talle] = (stock[item.talle] ?? 0) + item.cantidad;
        devueltos[item.productoId] =
            (devueltos[item.productoId] ?? 0) + item.cantidad;
      }

      for (final id in stocks.keys) {
        tx.update(_productos.doc(id), {
          'talles': stocks[id],
          'ventas': FieldValue.increment(-(devueltos[id] ?? 0)),
        });
      }
      if (cuponSnap != null && cuponSnap.exists) {
        tx.update(cuponSnap.reference, {'usos': FieldValue.increment(-1)});
      }
      tx.update(pedidoRef, {
        'estado': EstadosPedido.cancelado,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> marcarEmailEnviado(String pedidoId) {
    return _pedidos.doc(pedidoId).update({'emailEnviado': true});
  }

  /// GET /api/orders/:id (en tiempo real).
  Stream<Pedido?> pedido(String id) {
    return _pedidos
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? Pedido.fromFirestore(d) : null);
  }

  Future<Pedido?> obtener(String id) async {
    final d = await _pedidos.doc(id).get();
    return d.exists ? Pedido.fromFirestore(d) : null;
  }

  /// GET /api/orders del usuario logueado.
  /// Se ordena en Dart para no necesitar un índice compuesto en Firestore.
  Stream<List<Pedido>> pedidosDe(String uid) {
    return _pedidos.where('uid', isEqualTo: uid).snapshots().map(_ordenar);
  }

  // ---------------------------- Solo admin ----------------------------

  Stream<List<Pedido>> todos() => _pedidos.snapshots().map(_ordenar);

  Future<void> cambiarEstado(String pedidoId, String estado) {
    return _pedidos.doc(pedidoId).update({
      'estado': estado,
      // Si el admin lo marca como pagado a mano (ej: pago en el local),
      // el pago también queda aprobado.
      if (estado == EstadosPedido.pagado) 'pago.estado': EstadosPago.aprobado,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  List<Pedido> _ordenar(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs.map((d) => Pedido.fromFirestore(d)).toList();
    // Un pedido recién creado puede no tener fecha todavía: va primero.
    final futuro = DateTime(9999);
    lista.sort(
      (a, b) => (b.creadoEn ?? futuro).compareTo(a.creadoEn ?? futuro),
    );
    return lista;
  }
}
