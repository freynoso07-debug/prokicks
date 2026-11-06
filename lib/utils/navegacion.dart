import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/filtros.dart';
import '../providers/sesion_provider.dart';
import '../screens/catalogo_screen.dart';
import '../screens/login_screen.dart';
import '../screens/producto_screen.dart';

/// Si no hay sesión, abre el login. Devuelve true si al final hay sesión.
Future<bool> asegurarSesion(BuildContext context) async {
  if (context.read<SesionProvider>().logueado) return true;
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return ok == true;
}

void irACatalogo(
  BuildContext context, {
  FiltrosCatalogo filtros = const FiltrosCatalogo(),
  bool enfocarBuscador = false,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CatalogoScreen(
        filtrosIniciales: filtros,
        enfocarBuscador: enfocarBuscador,
      ),
    ),
  );
}

void irAProducto(BuildContext context, String productoId) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ProductoScreen(productoId: productoId)),
  );
}

void mostrarMensaje(BuildContext context, String texto, {SnackBarAction? accion}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    // persist: false → desde Flutter 3.29, un SnackBar con botón (por ejemplo
    // "VER CARRITO") no se cierra solo; así se va a los 4 segundos igual.
    ..showSnackBar(SnackBar(content: Text(texto), action: accion, persist: false));
}
