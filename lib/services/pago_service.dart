import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

/// Pagos con Mercado Pago.
///
/// La app NUNCA tiene el Access Token de Mercado Pago. El flujo real es:
///
///   App ──(token de Firebase + id del pedido)──▶ Cloud Function `crearPreferencia`
///   Cloud Function ──(Access Token secreto)──▶ API de Mercado Pago
///   Mercado Pago ──▶ devuelve la URL del checkout ──▶ la app redirige ahí
///   Mercado Pago ──(webhook)──▶ Cloud Function `webhookMercadoPago`
///                              └▶ actualiza el pago del pedido en Firestore
///
/// Si `ApiConfig.mpCrearPreferenciaUrl` está vacía, la app trabaja en
/// MODO PRUEBA: el pago se simula en una pantalla propia y no se cobra dinero.
class PagoService {
  bool get modoPrueba => !ApiConfig.mercadoPagoConfigurado;

  /// Pide la preferencia a la Cloud Function y abre el checkout de Mercado Pago.
  Future<void> irAMercadoPago(String pedidoId) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) throw Exception('Tenés que iniciar sesión para pagar.');

    // El token de Firebase le demuestra a la Cloud Function quién está pidiendo.
    final token = await usuario.getIdToken();
    final urlRetorno = '${Uri.base.origin}${Uri.base.path}?pedido=$pedidoId';

    final respuesta = await http
        .post(
          Uri.parse(ApiConfig.mpCrearPreferenciaUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'pedidoId': pedidoId, 'urlRetorno': urlRetorno}),
        )
        .timeout(const Duration(seconds: 20));

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo iniciar el pago (${respuesta.statusCode}): ${respuesta.body}');
    }

    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final url = (ApiConfig.mpUsarSandbox ? datos['sandbox_init_point'] : null) ??
        datos['init_point'];
    if (url is! String || url.isEmpty) {
      throw Exception('Mercado Pago no devolvió la URL del checkout.');
    }

    // '_self' abre el checkout en la misma pestaña (Flutter web).
    final abierto = await launchUrl(Uri.parse(url), webOnlyWindowName: '_self');
    if (!abierto) throw Exception('No se pudo abrir el checkout de Mercado Pago.');
  }
}
