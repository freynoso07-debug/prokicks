// Conexión de la app con el proyecto de Firebase "PROKICKS" (prokicks-df2b8).
//
// Los valores salen de la app web "PROKICKS Web" registrada en
// Consola de Firebase → Configuración del proyecto → Tus apps.
// Es el mismo archivo que genera `flutterfire configure`.
//
// Estos datos NO son secretos: identifican al proyecto y siempre viajan al
// navegador. Lo que protege la base de datos son las reglas de Firestore.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'PROKICKS está configurado solo para web. '
      'Para Android o iOS, correr `flutterfire configure` y agregar esas plataformas.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyANbg2zSFdkD0iAqgzMoSBvevod6kKlNmQ',
    appId: '1:684679317536:web:a2077725c3f14c4102d445',
    messagingSenderId: '684679317536',
    projectId: 'prokicks-df2b8',
    authDomain: 'prokicks-df2b8.firebaseapp.com',
    storageBucket: 'prokicks-df2b8.firebasestorage.app',
    measurementId: 'G-EYCH41WL40',
  );
}
