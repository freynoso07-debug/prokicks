import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Envía mails con la API REST de EmailJS.
/// EmailJS funciona desde el navegador, sin servidor propio.
class EmailService {
  /// Devuelve true si EmailJS aceptó el envío. Nunca tira excepción.
  Future<bool> enviar(Map<String, String> parametros) async {
    if (!ApiConfig.emailJsConfigurado) {
      debugPrint('EmailJS sin configurar: no se envía el mail.');
      return false;
    }
    try {
      final respuesta = await http
          .post(
            Uri.parse(ApiConfig.emailJsUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'service_id': ApiConfig.emailJsServiceId,
              'template_id': ApiConfig.emailJsTemplateId,
              'user_id': ApiConfig.emailJsPublicKey,
              // Las claves tienen que coincidir con las variables {{...}}
              // del template de EmailJS.
              'template_params': parametros,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode != 200) {
        debugPrint('EmailJS respondió ${respuesta.statusCode}: ${respuesta.body}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error al llamar a EmailJS: $e');
      return false;
    }
  }
}
