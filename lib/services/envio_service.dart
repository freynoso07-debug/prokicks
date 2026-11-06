import '../models/envio.dart';
import '../utils/formato.dart';

/// Cálculo del costo de envío.
///
/// Hoy usa una tabla propia por provincia. Está aislado en esta clase para
/// que, el día que se contrate un servicio de logística (Andreani, OCA,
/// Correo Argentino, etc.), solo haya que cambiar `cotizarDomicilio` por
/// una llamada a su API, sin tocar las pantallas.
class EnvioService {
  static const double envioGratisDesde = 200000;

  static const OpcionEnvio retiro = OpcionEnvio(
    metodo: 'retiro',
    descripcion: 'Retiro en el local',
    costo: 0,
    demora: 'Listo para retirar en 24 h hábiles',
  );

  static String get textoEnvioGratis => 'Envío gratis desde ${precioArs(envioGratisDesde)}';

  OpcionEnvio cotizarDomicilio({required String provincia, required double subtotal}) {
    final p = provincia.toLowerCase();
    double costo;
    String demora;

    if (p.contains('santa fe')) {
      costo = 4500;
      demora = '1 a 2 días hábiles';
    } else if (p.contains('buenos aires') ||
        p.contains('ciudad autónoma') ||
        p.contains('córdoba') ||
        p.contains('entre ríos')) {
      costo = 6500;
      demora = '2 a 4 días hábiles';
    } else {
      costo = 8900;
      demora = '4 a 7 días hábiles';
    }

    if (subtotal >= envioGratisDesde) costo = 0;

    return OpcionEnvio(
      metodo: 'domicilio',
      descripcion: 'Envío a domicilio',
      costo: costo,
      demora: demora,
    );
  }
}
