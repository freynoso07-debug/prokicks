/// Opción de entrega elegida en el checkout.
class OpcionEnvio {
  final String metodo; // 'retiro' o 'domicilio'
  final String descripcion;
  final double costo;
  final String demora;

  const OpcionEnvio({
    required this.metodo,
    required this.descripcion,
    required this.costo,
    required this.demora,
  });

  bool get esRetiro => metodo == 'retiro';

  Map<String, dynamic> toMap() => {
        'metodo': metodo,
        'descripcion': descripcion,
        'costo': costo,
        'demora': demora,
      };

  factory OpcionEnvio.fromMap(Map<String, dynamic>? m) {
    return OpcionEnvio(
      metodo: m?['metodo'] as String? ?? 'retiro',
      descripcion: m?['descripcion'] as String? ?? '',
      costo: (m?['costo'] as num?)?.toDouble() ?? 0,
      demora: m?['demora'] as String? ?? '',
    );
  }
}
