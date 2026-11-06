import 'package:flutter/foundation.dart';

import '../models/cotizacion.dart';
import '../services/dolar_service.dart';

/// Cotización del dólar, pedida una sola vez al abrir la app.
class CotizacionProvider extends ChangeNotifier {
  final DolarService _servicio = DolarService();

  Cotizacion? cotizacion;
  bool cargando = true;
  String? error;

  Future<void> cargar() async {
    try {
      cotizacion = await _servicio.obtenerOficial();
      error = null;
    } catch (e) {
      debugPrint('Error al pedir la cotización: $e');
      error = 'No se pudo obtener la cotización del dólar.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Pesos → dólares. null si no hay cotización.
  double? enUsd(double pesos) {
    final c = cotizacion;
    return c == null ? null : pesos / c.venta;
  }
}
