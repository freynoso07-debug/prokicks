import 'package:flutter/foundation.dart';

import '../models/cupon.dart';
import '../models/item_carrito.dart';
import '../models/producto.dart';
import '../services/usuarios_service.dart';

/// Estado del carrito (GET/POST/PUT/DELETE /api/cart).
///
/// - Sin sesión: vive solo en memoria.
/// - Con sesión: se guarda en el perfil del usuario en Firestore cada vez
///   que cambia, así no se pierde al recargar la página.
class CarritoProvider extends ChangeNotifier {
  final UsuariosService _usuarios = UsuariosService();
  final Map<String, ItemCarrito> _items = {};
  String? _uid;

  Cupon? _cupon;

  List<ItemCarrito> get items => _items.values.toList();
  bool get estaVacio => _items.isEmpty;
  int get cantidadTotal => _items.values.fold<int>(0, (s, i) => s + i.cantidad);
  double get subtotal => _items.values.fold<double>(0, (s, i) => s + i.subtotal);

  Cupon? get cupon => _cupon;
  double get descuento => _cupon?.descuentoPara(subtotal) ?? 0;

  /// Mensaje si el cupón aplicado dejó de cumplir sus condiciones
  /// (por ejemplo, se sacaron productos y no llega al mínimo).
  String? get avisoCupon => _cupon?.motivoInvalido(subtotal);

  double get totalSinEnvio => subtotal - descuento;

  int cantidadEnCarrito(String productoId, String talle) =>
      _items['$productoId-$talle']?.cantidad ?? 0;

  /// Agrega un botín. Devuelve un mensaje de error si no alcanza el stock.
  String? agregar(Producto producto, String talle, int cantidad) {
    final clave = '${producto.id}-$talle';
    final yaEnCarrito = _items[clave]?.cantidad ?? 0;
    final stock = producto.stockDe(talle);

    if (yaEnCarrito + cantidad > stock) {
      final quedan = stock - yaEnCarrito;
      return quedan <= 0
          ? 'Ya tenés en el carrito todo el stock del talle $talle.'
          : 'Solo podés agregar $quedan más del talle $talle.';
    }

    final existente = _items[clave];
    if (existente != null) {
      existente.cantidad += cantidad;
    } else {
      _items[clave] = ItemCarrito.desdeProducto(producto, talle, cantidad);
    }
    _huboCambios();
    return null;
  }

  void cambiarCantidad(String clave, int cantidad) {
    final item = _items[clave];
    if (item == null) return;
    if (cantidad <= 0) {
      _items.remove(clave);
    } else {
      item.cantidad = cantidad;
    }
    _huboCambios();
  }

  void eliminar(String clave) {
    _items.remove(clave);
    _huboCambios();
  }

  void vaciar() {
    _items.clear();
    _cupon = null;
    _huboCambios();
  }

  void aplicarCupon(Cupon cupon) {
    _cupon = cupon;
    notifyListeners();
  }

  void quitarCupon() {
    _cupon = null;
    notifyListeners();
  }

  /// Si el admin cambió precios, actualiza los ítems con el precio nuevo.
  void sincronizarPrecios(List<Producto> productos) {
    var cambio = false;
    for (final p in productos) {
      for (final clave in _items.keys.toList()) {
        final item = _items[clave]!;
        if (item.productoId == p.id && item.precio != p.precio) {
          _items[clave] = item.conPrecio(p.precio);
          cambio = true;
        }
      }
    }
    if (cambio) _huboCambios();
  }

  /// Al iniciar sesión: junta lo que había en memoria con lo guardado.
  void vincular(String uid, List<ItemCarrito> guardados) {
    _uid = uid;
    for (final item in guardados) {
      _items.putIfAbsent(item.clave, () => item);
    }
    _huboCambios();
  }

  /// Al cerrar sesión: se vacía (el carrito queda guardado en la cuenta).
  void desvincular() {
    _uid = null;
    _items.clear();
    _cupon = null;
    notifyListeners();
  }

  void _huboCambios() {
    notifyListeners();
    final uid = _uid;
    if (uid != null) {
      _usuarios.guardarCarrito(uid, items).catchError((Object e) {
        debugPrint('No se pudo guardar el carrito: $e');
      });
    }
  }
}
