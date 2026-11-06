/// Datos iniciales (seed) para probar la tienda.
///
/// Se cargan en Firestore desde el panel de administración con el botón
/// "Cargar datos de ejemplo". Los precios y el stock son inventados.
/// Las fotos se agregan después desde el panel (se suben a Cloudinary);
/// mientras tanto la app dibuja un botín genérico con los colores del producto.
class DatosEjemplo {
  /// Stock en orden de talle: 38, 39, 40, 41, 42, 43, 44, 45.
  static Map<String, int> _stock(List<int> cantidades) {
    const talles = ['38', '39', '40', '41', '42', '43', '44', '45'];
    return {for (var i = 0; i < talles.length; i++) talles[i]: cantidades[i]};
  }

  static Map<String, dynamic> _producto({
    required String nombre,
    required String marca,
    required String superficie,
    required String sku,
    required double precio,
    double? precioAnterior,
    required List<String> colores,
    required List<int> stock,
    required String descripcion,
    bool nuevo = false,
    bool destacado = false,
    bool oferta = false,
    int ventas = 0,
  }) {
    return {
      'nombre': nombre,
      'marca': marca,
      'superficie': superficie,
      'sku': sku,
      'precio': precio,
      'precioAnterior': precioAnterior,
      'colores': colores,
      'talles': _stock(stock),
      'descripcion': descripcion,
      'imagenes': <String>[],
      'nuevo': nuevo,
      'destacado': destacado,
      'oferta': oferta,
      'activo': true,
      'ventas': ventas,
    };
  }

  static final List<Map<String, dynamic>> productos = [
    // ----------------------------- NIKE -----------------------------
    _producto(
      nombre: 'Nike Mercurial Vapor 16 Elite FG',
      marca: 'Nike',
      superficie: 'FG',
      sku: 'NK-MV16E-FG',
      precio: 489999,
      colores: ['Verde flúor', 'Negro'],
      stock: [2, 4, 5, 6, 6, 4, 2, 1],
      nuevo: true,
      destacado: true,
      ventas: 142,
      descripcion: 'Botín de velocidad para jugadores explosivos. Capellada ultraliviana '
          'con textura para mejor control a alta velocidad y placa de tapones '
          'cónicos para cambios de dirección rápidos en césped natural firme.',
    ),
    _producto(
      nombre: 'Nike Mercurial Vapor 16 Academy MG',
      marca: 'Nike',
      superficie: 'MG',
      sku: 'NK-MV16A-MG',
      precio: 179999,
      precioAnterior: 199999,
      colores: ['Rosa', 'Negro'],
      stock: [3, 5, 8, 8, 7, 5, 3, 0],
      oferta: true,
      ventas: 233,
      descripcion: 'La silueta Mercurial a un precio accesible. Suela multisuperficie '
          'que funciona en pasto natural y sintético, ideal para quien juega en '
          'distintas canchas durante la semana.',
    ),
    _producto(
      nombre: 'Nike Phantom GX 2 Club TF',
      marca: 'Nike',
      superficie: 'TF',
      sku: 'NK-PGX2C-TF',
      precio: 99999,
      colores: ['Blanco', 'Naranja'],
      stock: [4, 6, 6, 7, 7, 5, 3, 2],
      ventas: 188,
      descripcion: 'Pensado para el fútbol 5 y 7. Suela de goma con tacos cortos que '
          'agarra bien en sintético corto y capellada sintética fácil de limpiar.',
    ),
    _producto(
      nombre: 'Nike Tiempo Legend 10 Academy AG',
      marca: 'Nike',
      superficie: 'AG',
      sku: 'NK-TL10A-AG',
      precio: 169999,
      colores: ['Negro', 'Dorado'],
      stock: [0, 2, 4, 5, 5, 4, 2, 1],
      destacado: true,
      ventas: 97,
      descripcion: 'Comodidad clásica con materiales modernos. Capellada suave para un '
          'toque preciso y tapones cortos distribuidos para césped artificial.',
    ),
    _producto(
      nombre: 'Nike Streetgato IC',
      marca: 'Nike',
      superficie: 'IC',
      sku: 'NK-STG-IC',
      precio: 119999,
      precioAnterior: 139999,
      colores: ['Azul', 'Blanco'],
      stock: [2, 3, 4, 4, 3, 2, 1, 0],
      oferta: true,
      ventas: 64,
      descripcion: 'Botín de fútbol sala con suela de goma plana y puntera reforzada. '
          'Ideal para piso de parquet o cemento.',
    ),
    // ---------------------------- ADIDAS ----------------------------
    _producto(
      nombre: 'Adidas Predator Elite FG',
      marca: 'Adidas',
      superficie: 'FG',
      sku: 'AD-PREDE-FG',
      precio: 499999,
      colores: ['Rojo', 'Negro'],
      stock: [1, 3, 4, 5, 5, 4, 2, 1],
      nuevo: true,
      destacado: true,
      ventas: 121,
      descripcion: 'Control total del balón. Zonas de agarre en la capellada para '
          'efecto y potencia, y una placa de tapones mixtos para césped natural firme.',
    ),
    _producto(
      nombre: 'Adidas F50 League MG',
      marca: 'Adidas',
      superficie: 'MG',
      sku: 'AD-F50L-MG',
      precio: 189999,
      colores: ['Amarillo', 'Negro'],
      stock: [2, 4, 6, 6, 6, 4, 2, 1],
      nuevo: true,
      ventas: 76,
      descripcion: 'Liviano y rápido. Capellada delgada para sentir la pelota y suela '
          'multisuperficie para jugar en natural o sintético.',
    ),
    _producto(
      nombre: 'Adidas Copa Pure 2 Club TF',
      marca: 'Adidas',
      superficie: 'TF',
      sku: 'AD-COPA2C-TF',
      precio: 94999,
      precioAnterior: 109999,
      colores: ['Blanco', 'Negro'],
      stock: [3, 5, 7, 8, 7, 5, 3, 2],
      oferta: true,
      ventas: 205,
      descripcion: 'Estilo clásico para canchas de sintético corto. Ajuste cómodo, '
          'plantilla acolchada y suela de goma con tacos.',
    ),
    _producto(
      nombre: 'Adidas Predator Club IC',
      marca: 'Adidas',
      superficie: 'IC',
      sku: 'AD-PREDC-IC',
      precio: 89999,
      colores: ['Negro', 'Rojo'],
      stock: [2, 3, 3, 4, 4, 3, 2, 0],
      ventas: 58,
      descripcion: 'Agarre y control en fútbol sala. Suela de goma que no marca el piso '
          'y capellada sintética resistente.',
    ),
    _producto(
      nombre: 'Adidas X Crazyfast League AG',
      marca: 'Adidas',
      superficie: 'AG',
      sku: 'AD-XCFL-AG',
      precio: 159999,
      precioAnterior: 189999,
      colores: ['Celeste', 'Blanco'],
      stock: [0, 2, 3, 4, 4, 3, 1, 0],
      oferta: true,
      ventas: 83,
      descripcion: 'Velocidad en césped artificial. Diseño aerodinámico y tapones '
          'pensados para no trabarse en el sintético.',
    ),
    // ----------------------------- PUMA -----------------------------
    _producto(
      nombre: 'Puma Future 8 Match MG',
      marca: 'Puma',
      superficie: 'MG',
      sku: 'PU-FUT8M-MG',
      precio: 169999,
      colores: ['Naranja', 'Negro'],
      stock: [2, 3, 5, 6, 5, 4, 2, 1],
      destacado: true,
      ventas: 91,
      descripcion: 'Ajuste adaptable con cuello tejido elástico. Para jugadores '
          'creativos que necesitan libertad de movimiento en cualquier cancha.',
    ),
    _producto(
      nombre: 'Puma Ultra 5 Pro FG',
      marca: 'Puma',
      superficie: 'FG',
      sku: 'PU-ULT5P-FG',
      precio: 289999,
      colores: ['Celeste', 'Naranja'],
      stock: [1, 2, 3, 4, 4, 3, 2, 1],
      nuevo: true,
      ventas: 40,
      descripcion: 'Uno de los botines más livianos de la marca. Capellada fina y suela '
          'con tapones afilados para arrancar rápido en pasto natural.',
    ),
    _producto(
      nombre: 'Puma King Match TF',
      marca: 'Puma',
      superficie: 'TF',
      sku: 'PU-KINGM-TF',
      precio: 129999,
      precioAnterior: 149999,
      colores: ['Negro', 'Blanco'],
      stock: [3, 4, 5, 6, 6, 4, 2, 1],
      oferta: true,
      ventas: 110,
      descripcion: 'El clásico King renovado para sintético corto. Capellada suave, '
          'lengüeta plegada y suela de goma con tacos.',
    ),
    _producto(
      nombre: 'Puma Truco III IC',
      marca: 'Puma',
      superficie: 'IC',
      sku: 'PU-TRUC3-IC',
      precio: 79999,
      colores: ['Blanco', 'Gris'],
      stock: [3, 4, 4, 5, 5, 3, 2, 1],
      ventas: 67,
      descripcion: 'Botín de futsal resistente y económico. Suela de goma plana con '
          'buena tracción en parquet.',
    ),
    // -------------------------- NEW BALANCE --------------------------
    _producto(
      nombre: 'New Balance Furon Dispatch V8 FG',
      marca: 'New Balance',
      superficie: 'FG',
      sku: 'NB-FURD8-FG',
      precio: 199999,
      colores: ['Verde flúor', 'Negro'],
      stock: [1, 2, 3, 4, 4, 3, 1, 0],
      nuevo: true,
      ventas: 22,
      descripcion: 'Velocidad y estabilidad. Horma cómoda con buena contención del pie '
          'y tapones cónicos y laminados para césped natural.',
    ),
    _producto(
      nombre: 'New Balance Tekela Magique AG',
      marca: 'New Balance',
      superficie: 'AG',
      sku: 'NB-TEKM-AG',
      precio: 219999,
      precioAnterior: 249999,
      colores: ['Violeta', 'Blanco'],
      stock: [0, 1, 2, 3, 3, 2, 1, 0],
      oferta: true,
      ventas: 31,
      descripcion: 'Botín sin cordones aparentes para un toque limpio. Suela AG con '
          'tapones cortos y numerosos.',
    ),
    _producto(
      nombre: 'New Balance Audazo Command IC',
      marca: 'New Balance',
      superficie: 'IC',
      sku: 'NB-AUDC-IC',
      precio: 119999,
      colores: ['Negro', 'Naranja'],
      stock: [1, 2, 3, 3, 3, 2, 1, 0],
      ventas: 18,
      descripcion: 'Pensado para el futsal de nivel. Puntera reforzada, buena '
          'amortiguación y suela de goma con agarre multidireccional.',
    ),
    // ----------------------------- MIZUNO -----------------------------
    _producto(
      nombre: 'Mizuno Morelia Neo IV Pro FG',
      marca: 'Mizuno',
      superficie: 'FG',
      sku: 'MZ-MORN4P-FG',
      precio: 349999,
      colores: ['Blanco', 'Azul'],
      stock: [1, 2, 3, 3, 3, 2, 1, 1],
      destacado: true,
      ventas: 44,
      descripcion: 'Capellada de cuero suave que se adapta al pie. Un botín de '
          'tradición japonesa para quien prioriza el toque y la comodidad.',
    ),
    _producto(
      nombre: 'Mizuno Monarcida Neo III Select AG',
      marca: 'Mizuno',
      superficie: 'AG',
      sku: 'MZ-MONN3-AG',
      precio: 149999,
      colores: ['Negro', 'Blanco'],
      stock: [2, 3, 4, 4, 4, 3, 2, 1],
      ventas: 29,
      descripcion: 'Horma ancha y cómoda, ideal para pies anchos. Suela con tapones '
          'cortos para césped artificial.',
    ),
    _producto(
      nombre: 'Mizuno Morelia Sala Classic IC',
      marca: 'Mizuno',
      superficie: 'IC',
      sku: 'MZ-MORSC-IC',
      precio: 139999,
      precioAnterior: 159999,
      colores: ['Azul', 'Blanco'],
      stock: [1, 2, 2, 3, 3, 2, 1, 0],
      oferta: true,
      ventas: 26,
      descripcion: 'Cuero sintético suave y suela de goma plana. Un clásico del '
          'fútbol sala.',
    ),
  ];

  static final List<Map<String, dynamic>> cupones = [
    {
      'codigo': 'BIENVENIDA10',
      'tipo': 'porcentaje',
      'valor': 10.0,
      'minimo': 0.0,
      'activo': true,
      'vence': null,
      'usosMax': null,
    },
    {
      'codigo': 'PROKICKS15K',
      'tipo': 'monto',
      'valor': 15000.0,
      'minimo': 150000.0,
      'activo': true,
      'vence': null,
      'usosMax': null,
    },
    {
      'codigo': 'FINDE20',
      'tipo': 'porcentaje',
      'valor': 20.0,
      'minimo': 300000.0,
      'activo': true,
      'vence': null,
      'usosMax': 50,
    },
  ];
}
