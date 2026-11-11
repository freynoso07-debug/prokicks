// Tests de la lógica de negocio que no depende de Firebase.
// Se corren con: flutter test
//
// (flutter create generaba un test del contador de ejemplo, que no existe
// en PROKICKS; lo reemplazamos por pruebas de cupones y envío.)

import 'package:flutter_test/flutter_test.dart';

import 'package:prokicks/models/cupon.dart';
import 'package:prokicks/services/envio_service.dart';

Cupon _cupon({
  String tipo = 'porcentaje',
  double valor = 10,
  double minimo = 0,
  bool activo = true,
  DateTime? vence,
  int usos = 0,
  int? usosMax,
}) =>
    Cupon(
      codigo: 'TEST',
      tipo: tipo,
      valor: valor,
      minimo: minimo,
      activo: activo,
      vence: vence,
      usos: usos,
      usosMax: usosMax,
    );

void main() {
  group('Cupones', () {
    test('BIENVENIDA10 descuenta el 10%', () {
      expect(_cupon().descuentoPara(100000), 10000);
    });

    test('un cupón de monto no descuenta más que el subtotal', () {
      expect(_cupon(tipo: 'monto', valor: 15000).descuentoPara(9000), 9000);
    });

    test('no aplica si no se llega al mínimo', () {
      final c = _cupon(tipo: 'monto', valor: 15000, minimo: 150000);
      expect(c.motivoInvalido(100000), isNotNull);
      expect(c.descuentoPara(100000), 0);
    });

    test('no aplica si está vencido, inactivo o sin usos', () {
      expect(_cupon(vence: DateTime(2020)).descuentoPara(100000), 0);
      expect(_cupon(activo: false).descuentoPara(100000), 0);
      expect(_cupon(usos: 50, usosMax: 50).descuentoPara(100000), 0);
    });
  });

  group('Envío', () {
    final envio = EnvioService();

    test('Santa Fe cuesta \$4.500', () {
      expect(envio.cotizarDomicilio(provincia: 'Santa Fe', subtotal: 100000).costo, 4500);
    });

    test('CABA entra en la zona de \$6.500', () {
      expect(
        envio.cotizarDomicilio(provincia: 'Ciudad Autónoma de Buenos Aires', subtotal: 100000).costo,
        6500,
      );
    });

    test('desde \$200.000 el envío es gratis', () {
      expect(envio.cotizarDomicilio(provincia: 'Salta', subtotal: 200000).costo, 0);
    });
  });
}
