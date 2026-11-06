import 'producto.dart';

enum OrdenCatalogo { relevancia, precioMenor, precioMayor, popularidad, novedades }

extension NombreOrden on OrdenCatalogo {
  String get nombre {
    switch (this) {
      case OrdenCatalogo.relevancia:
        return 'Relevancia';
      case OrdenCatalogo.precioMenor:
        return 'Menor precio';
      case OrdenCatalogo.precioMayor:
        return 'Mayor precio';
      case OrdenCatalogo.popularidad:
        return 'Más vendidos';
      case OrdenCatalogo.novedades:
        return 'Novedades';
    }
  }
}

/// Todos los filtros del catálogo juntos.
///
/// Como el catálogo es chico (decenas de productos), se descarga entero
/// desde Firestore y se filtra en la app: así el buscador responde en
/// tiempo real, letra por letra, sin hacer una consulta por cada tecla.
class FiltrosCatalogo {
  final String texto;
  final Set<String> marcas;
  final Set<String> superficies;
  final Set<String> talles;
  final double? precioMin;
  final double? precioMax;
  final bool soloOfertas;
  final bool soloNuevos;
  final bool soloDestacados;
  final OrdenCatalogo orden;

  const FiltrosCatalogo({
    this.texto = '',
    this.marcas = const {},
    this.superficies = const {},
    this.talles = const {},
    this.precioMin,
    this.precioMax,
    this.soloOfertas = false,
    this.soloNuevos = false,
    this.soloDestacados = false,
    this.orden = OrdenCatalogo.relevancia,
  });

  static const _sinCambio = Object();

  FiltrosCatalogo copyWith({
    String? texto,
    Set<String>? marcas,
    Set<String>? superficies,
    Set<String>? talles,
    Object? precioMin = _sinCambio,
    Object? precioMax = _sinCambio,
    bool? soloOfertas,
    bool? soloNuevos,
    bool? soloDestacados,
    OrdenCatalogo? orden,
  }) {
    return FiltrosCatalogo(
      texto: texto ?? this.texto,
      marcas: marcas ?? this.marcas,
      superficies: superficies ?? this.superficies,
      talles: talles ?? this.talles,
      precioMin: identical(precioMin, _sinCambio) ? this.precioMin : precioMin as double?,
      precioMax: identical(precioMax, _sinCambio) ? this.precioMax : precioMax as double?,
      soloOfertas: soloOfertas ?? this.soloOfertas,
      soloNuevos: soloNuevos ?? this.soloNuevos,
      soloDestacados: soloDestacados ?? this.soloDestacados,
      orden: orden ?? this.orden,
    );
  }

  /// Saca los filtros pero conserva el texto buscado y el orden.
  FiltrosCatalogo limpiar() => FiltrosCatalogo(texto: texto, orden: orden);

  int get cantidadActivos =>
      marcas.length +
      superficies.length +
      talles.length +
      (precioMin != null || precioMax != null ? 1 : 0) +
      (soloOfertas ? 1 : 0) +
      (soloNuevos ? 1 : 0) +
      (soloDestacados ? 1 : 0);

  List<Producto> aplicar(List<Producto> todos) {
    final palabras = normalizar(texto).split(' ').where((p) => p.isNotEmpty).toList();

    final resultado = todos.where((p) {
      if (!p.activo) return false;

      if (palabras.isNotEmpty) {
        final dondeBuscar = normalizar(
          '${p.nombre} ${p.marca} ${p.superficie} ${p.sku} ${p.colores.join(' ')}',
        );
        if (!palabras.every(dondeBuscar.contains)) return false;
      }
      if (marcas.isNotEmpty && !marcas.contains(p.marca)) return false;
      if (superficies.isNotEmpty && !superficies.contains(p.superficie)) return false;
      if (talles.isNotEmpty && !talles.any((t) => p.stockDe(t) > 0)) return false;

      final min = precioMin;
      final max = precioMax;
      if (min != null && p.precio < min) return false;
      if (max != null && p.precio > max) return false;

      if (soloOfertas && !p.enOferta) return false;
      if (soloNuevos && !p.nuevo) return false;
      if (soloDestacados && !p.destacado) return false;
      return true;
    }).toList();

    switch (orden) {
      case OrdenCatalogo.precioMenor:
        resultado.sort((a, b) => a.precio.compareTo(b.precio));
        break;
      case OrdenCatalogo.precioMayor:
        resultado.sort((a, b) => b.precio.compareTo(a.precio));
        break;
      case OrdenCatalogo.popularidad:
        resultado.sort((a, b) => b.ventas.compareTo(a.ventas));
        break;
      case OrdenCatalogo.novedades:
        final viejo = DateTime(2000);
        resultado.sort((a, b) => (b.creadoEn ?? viejo).compareTo(a.creadoEn ?? viejo));
        break;
      case OrdenCatalogo.relevancia:
        // Primero los que tienen stock, después destacados, después más vendidos.
        resultado.sort((a, b) {
          if (a.sinStock != b.sinStock) return a.sinStock ? 1 : -1;
          if (a.destacado != b.destacado) return a.destacado ? -1 : 1;
          return b.ventas.compareTo(a.ventas);
        });
        break;
    }
    return resultado;
  }

  /// Minúsculas y sin tildes, para que "fútbol" encuentre "futbol".
  static String normalizar(String s) {
    const conTilde = 'áéíóúüñ';
    const sinTilde = 'aeiouun';
    var r = s.toLowerCase();
    for (var i = 0; i < conTilde.length; i++) {
      r = r.replaceAll(conTilde[i], sinTilde[i]);
    }
    return r.trim();
  }
}
