import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// API Georef del Gobierno argentino: provincias y localidades oficiales.
/// Se usa en el checkout y en el perfil para cargar la dirección de envío.
class GeorefService {
  static List<String>? _provinciasCache;
  static final Map<String, List<String>> _localidadesCache = {};

  /// Por si Georef no responde: la lista fija de las 24 jurisdicciones.
  static const List<String> provinciasRespaldo = [
    'Buenos Aires',
    'Catamarca',
    'Chaco',
    'Chubut',
    'Ciudad Autónoma de Buenos Aires',
    'Corrientes',
    'Córdoba',
    'Entre Ríos',
    'Formosa',
    'Jujuy',
    'La Pampa',
    'La Rioja',
    'Mendoza',
    'Misiones',
    'Neuquén',
    'Río Negro',
    'Salta',
    'San Juan',
    'San Luis',
    'Santa Cruz',
    'Santa Fe',
    'Santiago del Estero',
    'Tierra del Fuego, Antártida e Islas del Atlántico Sur',
    'Tucumán',
  ];

  /// GET /provincias?campos=id,nombre&max=30
  Future<List<String>> provincias() async {
    final cache = _provinciasCache;
    if (cache != null) return cache;

    final uri = Uri.parse('${ApiConfig.georefBaseUrl}/provincias').replace(
      queryParameters: {'campos': 'id,nombre', 'max': '30'},
    );
    final respuesta = await http.get(uri).timeout(const Duration(seconds: 15));
    if (respuesta.statusCode != 200) {
      throw Exception('Georef respondió ${respuesta.statusCode}');
    }

    // Respuesta: { "cantidad": 24, "provincias": [ {"id": "82", "nombre": "Santa Fe"}, ... ] }
    final json = jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    final lista = (json['provincias'] as List)
        .map((p) => (p as Map)['nombre'] as String)
        .toList()
      ..sort();
    _provinciasCache = lista;
    return lista;
  }

  /// GET /localidades?provincia=Santa Fe&campos=nombre&max=5000
  Future<List<String>> localidades(String provincia) async {
    final cache = _localidadesCache[provincia];
    if (cache != null) return cache;

    final uri = Uri.parse('${ApiConfig.georefBaseUrl}/localidades').replace(
      queryParameters: {'provincia': provincia, 'campos': 'nombre', 'max': '5000'},
    );
    final respuesta = await http.get(uri).timeout(const Duration(seconds: 20));
    if (respuesta.statusCode != 200) {
      throw Exception('Georef respondió ${respuesta.statusCode}');
    }

    final json = jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    // Hay localidades con el mismo nombre en distintos departamentos: toSet()
    // saca los repetidos.
    final lista = (json['localidades'] as List)
        .map((l) => (l as Map)['nombre'] as String)
        .toSet()
        .toList()
      ..sort();
    _localidadesCache[provincia] = lista;
    return lista;
  }
}
