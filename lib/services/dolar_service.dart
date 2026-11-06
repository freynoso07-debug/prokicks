import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/cotizacion.dart';

/// DolarAPI: cotización del dólar oficial. Se usa para mostrar un precio de
/// referencia en dólares y para guardar en cada pedido el dólar de ese día.
class DolarService {
  Future<Cotizacion> obtenerOficial() async {
    final respuesta = await http
        .get(Uri.parse(ApiConfig.dolarOficialUrl))
        .timeout(const Duration(seconds: 15));
    if (respuesta.statusCode != 200) {
      throw Exception('DolarAPI respondió ${respuesta.statusCode}');
    }
    final json = jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    return Cotizacion.fromJson(json);
  }
}
