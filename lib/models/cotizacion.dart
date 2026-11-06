/// Cotización del dólar que devuelve DolarAPI.
///
/// Ejemplo de https://dolarapi.com/v1/dolares/oficial :
/// { "moneda": "USD", "casa": "oficial", "nombre": "Oficial",
///   "compra": 1520, "venta": 1570, "fechaActualizacion": "2026-11-04T18:00:00.000Z" }
class Cotizacion {
  final double compra;
  final double venta;
  final DateTime? actualizada;

  const Cotizacion({required this.compra, required this.venta, this.actualizada});

  factory Cotizacion.fromJson(Map<String, dynamic> json) {
    return Cotizacion(
      compra: (json['compra'] as num).toDouble(),
      venta: (json['venta'] as num).toDouble(),
      actualizada:
          DateTime.tryParse(json['fechaActualizacion'] as String? ?? '')?.toLocal(),
    );
  }
}
