/// Configuración de las APIs externas que usa PROKICKS.
///
/// Firebase NO se configura acá: sus datos están en `firebase_options.dart`
/// (el archivo que genera `flutterfire configure`).
///
/// Acá solo van datos PÚBLICOS (pensados para estar en el navegador).
/// Las claves privadas (por ejemplo el Access Token de Mercado Pago) NUNCA
/// van en la app: viven como secreto en la Cloud Function (carpeta functions/).
class ApiConfig {
  // ---------------------------------------------------------------------------
  // 1) Georef (Gobierno de Argentina) — provincias y localidades para el envío.
  //    Pública, sin key. https://www.argentina.gob.ar/georef
  // ---------------------------------------------------------------------------
  static const String georefBaseUrl = 'https://apis.datos.gob.ar/georef/api/v2.0';

  // ---------------------------------------------------------------------------
  // 2) DolarAPI — cotización del dólar oficial (precio de referencia en USD).
  //    Pública, sin key. https://dolarapi.com
  // ---------------------------------------------------------------------------
  static const String dolarOficialUrl = 'https://dolarapi.com/v1/dolares/oficial';

  // ---------------------------------------------------------------------------
  // 3) EmailJS — mail de confirmación cuando un pago se aprueba.
  //    Necesita cuenta (README, paso 6).
  // ---------------------------------------------------------------------------
  static const String emailJsUrl = 'https://api.emailjs.com/api/v1.0/email/send';
  static const String emailJsServiceId = 'service_dnxv91u'; // Email Services → Gmail
  static const String emailJsTemplateId = 'template_7s4i8tz'; // Email Templates
  static const String emailJsPublicKey = 'SU18j-tyE18VY-qBX'; // Account → General → API keys (pública)

  // ---------------------------------------------------------------------------
  // 4) Cloudinary — subida de fotos de productos desde el panel admin.
  //    Necesita cuenta y un "upload preset" sin firma (README, paso 7).
  // ---------------------------------------------------------------------------
  static const String cloudinaryCloudName = 'olvmfcyl'; // Dashboard / API Keys
  static const String cloudinaryUploadPreset = 'prokicks_unsigned'; // Settings → Upload → Upload presets (Unsigned)

  // ---------------------------------------------------------------------------
  // 5) Mercado Pago — URL PÚBLICA de la Cloud Function que crea la preferencia.
  //    Vacía = MODO PRUEBA (el pago se simula y no se cobra dinero).
  //    El Access Token NO va acá: se guarda como secreto en Firebase
  //    (README, paso 9).
  // ---------------------------------------------------------------------------
  static const String mpCrearPreferenciaUrl = '';

  /// true = usar el checkout de prueba (sandbox) de Mercado Pago cuando la
  /// Cloud Function devuelve las dos URLs.
  static const bool mpUsarSandbox = true;

  static bool get emailJsConfigurado =>
      !emailJsServiceId.startsWith('TU_') &&
      !emailJsTemplateId.startsWith('TU_') &&
      !emailJsPublicKey.startsWith('TU_');

  static bool get cloudinaryConfigurado =>
      !cloudinaryCloudName.startsWith('TU_') &&
      !cloudinaryUploadPreset.startsWith('TU_');

  static bool get mercadoPagoConfigurado => mpCrearPreferenciaUrl.isNotEmpty;
}
