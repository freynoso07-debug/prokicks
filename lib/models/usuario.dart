import 'package:cloud_firestore/cloud_firestore.dart';

import 'item_carrito.dart';

/// Dirección de envío.
class Direccion {
  final String calle;
  final String numero;
  final String localidad;
  final String provincia;
  final String codigoPostal;

  const Direccion({
    required this.calle,
    required this.numero,
    required this.localidad,
    required this.provincia,
    required this.codigoPostal,
  });

  static const vacia = Direccion(
    calle: '',
    numero: '',
    localidad: '',
    provincia: '',
    codigoPostal: '',
  );

  bool get completa =>
      calle.isNotEmpty && numero.isNotEmpty && localidad.isNotEmpty && provincia.isNotEmpty;

  String get texto => '$calle $numero, $localidad, $provincia (CP $codigoPostal)';

  factory Direccion.fromMap(Map<String, dynamic>? m) {
    if (m == null) return vacia;
    return Direccion(
      calle: m['calle'] as String? ?? '',
      numero: m['numero'] as String? ?? '',
      localidad: m['localidad'] as String? ?? '',
      provincia: m['provincia'] as String? ?? '',
      codigoPostal: m['codigoPostal'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'calle': calle,
        'numero': numero,
        'localidad': localidad,
        'provincia': provincia,
        'codigoPostal': codigoPostal,
      };
}

/// Documento `usuarios/{uid}` de Firestore.
class PerfilUsuario {
  final String uid;
  final String nombre;
  final String email;
  final String rol; // 'cliente' o 'admin'
  final String telefono;
  final Direccion direccion;
  final List<String> favoritos; // ids de productos
  final List<ItemCarrito> carrito;
  final DateTime? creadoEn;

  const PerfilUsuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.telefono,
    required this.direccion,
    required this.favoritos,
    required this.carrito,
    required this.creadoEn,
  });

  bool get esAdmin => rol == 'admin';

  factory PerfilUsuario.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final dir = d['direccion'];
    return PerfilUsuario(
      uid: doc.id,
      nombre: d['nombre'] as String? ?? '',
      email: d['email'] as String? ?? '',
      rol: d['rol'] as String? ?? 'cliente',
      telefono: d['telefono'] as String? ?? '',
      direccion: Direccion.fromMap(dir == null ? null : Map<String, dynamic>.from(dir as Map)),
      favoritos: List<String>.from(d['favoritos'] as List? ?? const []),
      carrito: ItemCarrito.listaDesde(d['carrito']),
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
    );
  }
}
