// Números, precios y fechas en formato argentino
// (punto para miles, coma para decimales).

String formatearNumero(double valor, {int decimales = 0}) {
  final negativo = valor < 0;
  final partes = valor.abs().toStringAsFixed(decimales).split('.');
  final entero = partes[0];

  final buffer = StringBuffer();
  for (var i = 0; i < entero.length; i++) {
    if (i > 0 && (entero.length - i) % 3 == 0) buffer.write('.');
    buffer.write(entero[i]);
  }
  final parteDecimal = decimales > 0 ? ',${partes[1]}' : '';
  return '${negativo ? '-' : ''}$buffer$parteDecimal';
}

/// $ 189.999
String precioArs(double valor) => '\$ ${formatearNumero(valor)}';

/// US$ 121
String precioUsd(double valor) => 'US\$ ${formatearNumero(valor)}';

String dosDigitos(int n) => n.toString().padLeft(2, '0');

/// 05/11/2026 14:30
String fechaHora(DateTime f) =>
    '${dosDigitos(f.day)}/${dosDigitos(f.month)}/${f.year} ${dosDigitos(f.hour)}:${dosDigitos(f.minute)}';

/// 05/11/2026
String fechaCorta(DateTime f) => '${dosDigitos(f.day)}/${dosDigitos(f.month)}/${f.year}';

const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// "nov 26"
String mesCorto(DateTime f) => '${_meses[f.month - 1]} ${f.year % 100}';
