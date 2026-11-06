import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cupon.dart';

class CuponException implements Exception {
  final String mensaje;
  const CuponException(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Cupones de descuento (colección `cupones`, el id del documento es el código).
class CuponesService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('cupones');

  /// Equivalente a POST /api/coupons/validate.
  /// Devuelve el cupón si se puede usar; si no, tira CuponException con el motivo.
  Future<Cupon> validar(String codigo, double subtotal) async {
    final limpio = codigo.trim().toUpperCase();
    if (limpio.isEmpty) throw const CuponException('Ingresá un código.');

    final doc = await _col.doc(limpio).get();
    if (!doc.exists) throw CuponException('El cupón $limpio no existe.');

    final cupon = Cupon.fromFirestore(doc);
    final motivo = cupon.motivoInvalido(subtotal);
    if (motivo != null) throw CuponException(motivo);
    return cupon;
  }

  // ---------------------------- Solo admin ----------------------------

  Stream<List<Cupon>> todos() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map((d) => Cupon.fromFirestore(d)).toList();
      lista.sort((a, b) => a.codigo.compareTo(b.codigo));
      return lista;
    });
  }

  Future<void> crear(Cupon cupon) {
    return _col.doc(cupon.codigo).set({
      ...cupon.toMap(),
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cambiarActivo(String codigo, bool activo) {
    return _col.doc(codigo).update({'activo': activo});
  }

  Future<void> eliminar(String codigo) => _col.doc(codigo).delete();
}
