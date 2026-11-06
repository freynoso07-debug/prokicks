import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item_carrito.dart';
import '../models/usuario.dart';

/// Lee y escribe la colección `usuarios` de Firestore.
class UsuariosService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('usuarios');

  /// Perfil en tiempo real. Emite null si el documento todavía no existe
  /// (pasa un instante justo después de registrarse).
  Stream<PerfilUsuario?> streamPerfil(String uid) {
    return _col.doc(uid).snapshots().map(
          (doc) => doc.exists ? PerfilUsuario.fromFirestore(doc) : null,
        );
  }

  /// Se llama al registrarse. El rol siempre arranca como 'cliente':
  /// las reglas de Firestore rechazan cualquier otro valor.
  Future<void> crearPerfil({
    required String uid,
    required String nombre,
    required String email,
  }) {
    return _col.doc(uid).set({
      'nombre': nombre,
      'email': email,
      'rol': 'cliente',
      'telefono': '',
      'direccion': Direccion.vacia.toMap(),
      'favoritos': <String>[],
      'carrito': <Map<String, dynamic>>[],
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> actualizarDatos(
    String uid, {
    required String nombre,
    required String telefono,
    Direccion? direccion,
  }) {
    return _col.doc(uid).update({
      'nombre': nombre,
      'telefono': telefono,
      if (direccion != null) 'direccion': direccion.toMap(),
    });
  }

  Future<void> alternarFavorito(String uid, String productoId, {required bool agregar}) {
    return _col.doc(uid).update({
      'favoritos': agregar
          ? FieldValue.arrayUnion([productoId])
          : FieldValue.arrayRemove([productoId]),
    });
  }

  /// El carrito se guarda en el perfil para no perderlo al recargar la página
  /// o al entrar desde otro dispositivo.
  Future<void> guardarCarrito(String uid, List<ItemCarrito> items) {
    return _col.doc(uid).update({
      'carrito': items.map((i) => i.toMap()).toList(),
    });
  }

  // ---------------------------- Solo admin ----------------------------

  Stream<List<PerfilUsuario>> todos() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map((d) => PerfilUsuario.fromFirestore(d)).toList();
      final viejo = DateTime(2000);
      lista.sort((a, b) => (b.creadoEn ?? viejo).compareTo(a.creadoEn ?? viejo));
      return lista;
    });
  }

  Future<void> cambiarRol(String uid, String rol) {
    return _col.doc(uid).update({'rol': rol});
  }
}
