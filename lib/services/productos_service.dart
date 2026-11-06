import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/datos_ejemplo.dart';
import '../models/producto.dart';

/// CRUD de la colección `productos` (equivalente a GET/POST/PUT/DELETE
/// /api/products, pero hablando directo con Firestore).
class ProductosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('productos');

  /// Todo el catálogo en tiempo real (GET /api/products).
  /// Si el admin cambia un precio o el stock, la tienda se actualiza sola.
  Stream<List<Producto>> productos() {
    return _col.snapshots().map(
      (snap) => snap.docs.map((d) => Producto.fromFirestore(d)).toList(),
    );
  }

  /// POST /api/products
  Future<void> crear(Map<String, dynamic> datos) {
    return _col.add({
      ...datos,
      'ventas': 0,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// PUT /api/products/:id
  Future<void> actualizar(String id, Map<String, dynamic> datos) {
    return _col.doc(id).update({
      ...datos,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// DELETE /api/products/:id
  Future<void> eliminar(String id) => _col.doc(id).delete();

  /// Carga los productos y cupones de ejemplo en un solo lote.
  /// Devuelve cuántos productos agregó.
  ///
  /// Es seguro tocar el botón más de una vez: saltea los productos cuyo SKU
  /// ya existe y los cupones que ya están (así no se duplica el catálogo ni
  /// se reinicia el contador de usos de un cupón).
  Future<int> cargarDatosDeEjemplo() async {
    final lote = _db.batch();
    final ahora = DateTime.now();
    final productos = DatosEjemplo.productos;

    final existentes = await _col.get();
    final skus = existentes.docs.map((d) => d.data()['sku']).toSet();
    var agregados = 0;

    for (var i = 0; i < productos.length; i++) {
      final datos = productos[i];
      if (skus.contains(datos['sku'])) continue;
      agregados++;
      // Fechas escalonadas para que "Novedades" tenga un orden real:
      // los marcados como nuevos quedan como los más recientes.
      final dias = (datos['nuevo'] == true) ? i : 30 + i;
      lote.set(_col.doc(), {
        ...datos,
        'creadoEn': Timestamp.fromDate(ahora.subtract(Duration(days: dias))),
      });
    }

    for (final cupon in DatosEjemplo.cupones) {
      final codigo = cupon['codigo'] as String;
      final datos = Map<String, dynamic>.from(cupon)..remove('codigo');
      final ref = _db.collection('cupones').doc(codigo);
      if ((await ref.get()).exists) continue;
      lote.set(ref, {
        ...datos,
        'usos': 0,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    }

    await lote.commit();
    return agregados;
  }
}
