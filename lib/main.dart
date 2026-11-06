import 'dart:ui' show PointerDeviceKind;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/tema.dart';
// Datos de conexión con el proyecto de Firebase PROKICKS (README, paso 3).
import 'firebase_options.dart';
import 'models/producto.dart';
import 'providers/carrito_provider.dart';
import 'providers/cotizacion_provider.dart';
import 'providers/sesion_provider.dart';
import 'screens/home_screen.dart';
import 'services/productos_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // El carrito se crea una sola vez y se comparte con la sesión, que lo
  // vincula con el perfil del usuario cuando inicia sesión.
  final carrito = CarritoProvider();
  runApp(ProKicksApp(carrito: carrito));
}

class ProKicksApp extends StatelessWidget {
  const ProKicksApp({super.key, required this.carrito});

  final CarritoProvider carrito;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: carrito),
        ChangeNotifierProvider(create: (_) => SesionProvider(carrito), lazy: false),
        ChangeNotifierProvider(create: (_) => CotizacionProvider()..cargar()),
        // Catálogo completo en tiempo real. null = todavía cargando.
        StreamProvider<List<Producto>?>(
          create: (_) => ProductosService().productos(),
          initialData: null,
          catchError: (_, error) {
            debugPrint('Error al leer productos: $error');
            return const <Producto>[];
          },
        ),
      ],
      child: MaterialApp(
        title: 'PROKICKS — Botines de fútbol',
        debugShowCheckedModeBanner: false,
        theme: Tema.claro,
        // Permite arrastrar con el mouse las filas horizontales de productos.
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
