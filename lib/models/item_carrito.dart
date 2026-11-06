import 'producto.dart';

/// Un botín dentro del carrito: producto + talle + cantidad.
///
/// Guarda una "foto" de los datos del producto (nombre, precio, imagen) para
/// poder mostrarse aunque el catálogo todavía no haya cargado. Al confirmar
/// la compra, el precio se vuelve a leer de Firestore (no se confía en este).
class ItemCarrito {
  final String productoId;
  final String nombre;
  final String marca;
  final String superficie;
  final String talle;
  final String sku;
  final String? imagen;
  final List<String> colores;
  final double precio;
  int cantidad;

  ItemCarrito({
    required this.productoId,
    required this.nombre,
    required this.marca,
    required this.superficie,
    required this.talle,
    required this.sku,
    required this.imagen,
    required this.colores,
    required this.precio,
    required this.cantidad,
  });

  /// El mismo botín en otro talle es otro ítem del carrito.
  String get clave => '$productoId-$talle';

  double get subtotal => precio * cantidad;

  factory ItemCarrito.desdeProducto(Producto p, String talle, int cantidad) {
    return ItemCarrito(
      productoId: p.id,
      nombre: p.nombre,
      marca: p.marca,
      superficie: p.superficie,
      talle: talle,
      sku: p.sku,
      imagen: p.imagenPrincipal,
      colores: p.colores,
      precio: p.precio,
      cantidad: cantidad,
    );
  }

  ItemCarrito conPrecio(double nuevoPrecio) {
    return ItemCarrito(
      productoId: productoId,
      nombre: nombre,
      marca: marca,
      superficie: superficie,
      talle: talle,
      sku: sku,
      imagen: imagen,
      colores: colores,
      precio: nuevoPrecio,
      cantidad: cantidad,
    );
  }

  /// Formato con el que se guarda en Firestore (carrito del usuario y pedidos).
  Map<String, dynamic> toMap() => {
        'productoId': productoId,
        'nombre': nombre,
        'marca': marca,
        'superficie': superficie,
        'talle': talle,
        'sku': sku,
        'imagen': imagen,
        'colores': colores,
        'precio': precio,
        'cantidad': cantidad,
      };

  factory ItemCarrito.fromMap(Map<String, dynamic> m) {
    return ItemCarrito(
      productoId: m['productoId'] as String? ?? '',
      nombre: m['nombre'] as String? ?? '',
      marca: m['marca'] as String? ?? '',
      superficie: m['superficie'] as String? ?? '',
      talle: m['talle'] as String? ?? '',
      sku: m['sku'] as String? ?? '',
      imagen: m['imagen'] as String?,
      colores: List<String>.from(m['colores'] as List? ?? const []),
      precio: (m['precio'] as num?)?.toDouble() ?? 0,
      cantidad: (m['cantidad'] as num?)?.toInt() ?? 1,
    );
  }

  static List<ItemCarrito> listaDesde(dynamic crudo) {
    final lista = crudo as List? ?? const [];
    return lista
        .map((e) => ItemCarrito.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
