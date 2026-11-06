import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Sube fotos de productos a Cloudinary con un "upload preset" sin firma.
///
/// Sin firma = no hace falta mandar el API Secret desde la app (que no debe
/// estar en el navegador). El preset, configurado en el panel de Cloudinary,
/// define qué se puede subir y a qué carpeta va.
class CloudinaryService {
  Future<String> subirImagen(Uint8List bytes, String nombreArchivo) async {
    if (!ApiConfig.cloudinaryConfigurado) {
      throw Exception('Cloudinary no está configurado (ver README, paso 7).');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${ApiConfig.cloudinaryCloudName}/image/upload',
    );
    final pedido = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = ApiConfig.cloudinaryUploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: nombreArchivo));

    final respuestaStream = await pedido.send().timeout(const Duration(seconds: 60));
    final respuesta = await http.Response.fromStream(respuestaStream);

    if (respuesta.statusCode != 200) {
      throw Exception('Cloudinary respondió ${respuesta.statusCode}: ${respuesta.body}');
    }
    // La respuesta trae, entre otros datos, la URL pública de la imagen.
    final json = jsonDecode(respuesta.body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }
}
