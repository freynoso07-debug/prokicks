import 'package:cloud_firestore/cloud_firestore.dart';

/// Un botín del catálogo, leído de la colección `productos` de Firestore.
class Producto {
  final String id;
  final String nombre;
  final String marca;
  final String superficie; // FG, AG, MG, TF o IC
  final String descripcion;
  final String sku;
  final double precio;
  final double? precioAnterior;
  final List<String> imagenes;
  final List<String> colores;

  /// Stock por talle. Ejemplo: {"40": 3, "41": 0, "42": 5}
  final Map<String, int> stockPorTalle;

  final bool nuevo;
  final bool destacado;
  final bool oferta;
  final bool activo;

  /// Unidades vendidas. Se usa para "ordenar por popularidad".
  final int ventas;
  final DateTime? creadoEn;

  const Producto({
    required this.id,
    required this.nombre,
    required this.marca,
    required this.superficie,
    required this.descripcion,
    required this.sku,
    required this.precio,
    required this.precioAnterior,
    required this.imagenes,
    required this.colores,
    required this.stockPorTalle,
    required this.nuevo,
    required this.destacado,
    required this.oferta,
    required this.activo,
    required this.ventas,
    required this.creadoEn,
  });

  /// Porcentaje de descuento calculado a partir del precio anterior.
  int get descuento {
    final anterior = precioAnterior;
    if (anterior == null || anterior <= precio) return 0;
    return ((1 - precio / anterior) * 100).round();
  }

  bool get enOferta => oferta || descuento > 0;

  int stockDe(String talle) => stockPorTalle[talle] ?? 0;

  int get stockTotal => stockPorTalle.values.fold<int>(0, (a, b) => a + b);

  bool get sinStock => stockTotal <= 0;

  /// Talles ordenados de menor a mayor.
  List<String> get talles {
    final lista = stockPorTalle.keys.toList();
    lista.sort((a, b) => (double.tryParse(a) ?? 0).compareTo(double.tryParse(b) ?? 0));
    return lista;
  }

  String? get imagenPrincipal => imagenes.isEmpty ? null : imagenes.first;

  factory Producto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final tallesCrudos = Map<String, dynamic>.from(d['talles'] as Map? ?? const {});

    return Producto(
      id: doc.id,
      nombre: d['nombre'] as String? ?? '',
      marca: d['marca'] as String? ?? '',
      superficie: d['superficie'] as String? ?? '',
      descripcion: d['descripcion'] as String? ?? '',
      sku: d['sku'] as String? ?? '',
      // Firestore puede devolver int o double: `num` cubre los dos casos.
      precio: (d['precio'] as num?)?.toDouble() ?? 0,
      precioAnterior: (d['precioAnterior'] as num?)?.toDouble(),
      imagenes: List<String>.from(d['imagenes'] as List? ?? const []),
      colores: List<String>.from(d['colores'] as List? ?? const []),
      stockPorTalle: tallesCrudos.map(
        (talle, cantidad) => MapEntry(talle, (cantidad as num?)?.toInt() ?? 0),
      ),
      nuevo: d['nuevo'] as bool? ?? false,
      destacado: d['destacado'] as bool? ?? false,
      oferta: d['oferta'] as bool? ?? false,
      activo: d['activo'] as bool? ?? true,
      ventas: (d['ventas'] as num?)?.toInt() ?? 0,
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
    );
  }
}

/// Busca un producto por id en una lista (devuelve null si no está).
Producto? buscarProducto(List<Producto>? lista, String id) {
  if (lista == null) return null;
  for (final p in lista) {
    if (p.id == id) return p;
  }
  return null;
}
