/// Valores fijos del catálogo de botines.
class Catalogo {
  static const List<String> marcas = [
    'Nike',
    'Adidas',
    'Puma',
    'New Balance',
    'Mizuno',
  ];

  /// Tipos de superficie (código → nombre).
  static const Map<String, String> superficies = {
    'FG': 'Césped natural firme',
    'AG': 'Césped artificial',
    'MG': 'Múltiples superficies',
    'TF': 'Sintético corto',
    'IC': 'Fútbol sala',
  };

  /// Descripción corta de cada superficie (para la home).
  static const Map<String, String> superficiesDetalle = {
    'FG': 'Tapones para canchas de pasto natural en buen estado.',
    'AG': 'Tapones cortos y numerosos para césped artificial.',
    'MG': 'Versátiles: pasto natural y sintético.',
    'TF': 'Suela de goma con tacos para fútbol 5 y 7.',
    'IC': 'Suela plana de goma para piso de parquet o cemento.',
  };

  /// Talles argentinos que maneja la tienda.
  static const List<String> talles = ['38', '39', '40', '41', '42', '43', '44', '45'];

  static String nombreSuperficie(String codigo) => superficies[codigo] ?? codigo;
}
