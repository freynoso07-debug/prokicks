import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/formato.dart';

/// Cupón de descuento, guardado en `cupones/{CODIGO}`.
class Cupon {
  final String codigo;
  final String tipo; // 'porcentaje' o 'monto'
  final double valor;
  final double minimo; // compra mínima para poder usarlo
  final bool activo;
  final DateTime? vence;
  final int usos;
  final int? usosMax; // null = ilimitado

  const Cupon({
    required this.codigo,
    required this.tipo,
    required this.valor,
    required this.minimo,
    required this.activo,
    required this.vence,
    required this.usos,
    required this.usosMax,
  });

  bool get esPorcentaje => tipo == 'porcentaje';

  String get descripcion =>
      esPorcentaje ? '${valor.round()}% OFF' : '${precioArs(valor)} OFF';

  /// Devuelve el motivo por el que el cupón NO se puede usar, o null si se puede.
  String? motivoInvalido(double subtotal) {
    if (!activo) return 'El cupón $codigo no está activo.';
    final fin = vence;
    if (fin != null && DateTime.now().isAfter(fin)) return 'El cupón $codigo está vencido.';
    final maximo = usosMax;
    if (maximo != null && usos >= maximo) return 'El cupón $codigo ya se usó el máximo de veces.';
    if (subtotal < minimo) {
      return 'El cupón $codigo requiere una compra mínima de ${precioArs(minimo)}.';
    }
    return null;
  }

  /// Monto a descontar para un subtotal dado (0 si no aplica).
  double descuentoPara(double subtotal) {
    if (motivoInvalido(subtotal) != null) return 0;
    final descuento = esPorcentaje ? subtotal * valor / 100 : valor;
    return descuento > subtotal ? subtotal : descuento.roundToDouble();
  }

  factory Cupon.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Cupon(
      codigo: doc.id,
      tipo: d['tipo'] as String? ?? 'porcentaje',
      valor: (d['valor'] as num?)?.toDouble() ?? 0,
      minimo: (d['minimo'] as num?)?.toDouble() ?? 0,
      activo: d['activo'] as bool? ?? false,
      vence: (d['vence'] as Timestamp?)?.toDate(),
      usos: (d['usos'] as num?)?.toInt() ?? 0,
      usosMax: (d['usosMax'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'tipo': tipo,
        'valor': valor,
        'minimo': minimo,
        'activo': activo,
        'vence': vence == null ? null : Timestamp.fromDate(vence!),
        'usos': usos,
        'usosMax': usosMax,
      };
}
