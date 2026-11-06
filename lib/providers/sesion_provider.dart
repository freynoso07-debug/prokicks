import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/usuarios_service.dart';
import 'carrito_provider.dart';

/// Sesión actual: usuario de Firebase Auth + su perfil de Firestore
/// (rol, favoritos, dirección). Lo usan todas las pantallas.
class SesionProvider extends ChangeNotifier {
  SesionProvider(this._carrito) {
    _subAuth = FirebaseAuth.instance.authStateChanges().listen(_alCambiarSesion);
  }

  final CarritoProvider _carrito;
  final UsuariosService _usuarios = UsuariosService();

  StreamSubscription<User?>? _subAuth;
  StreamSubscription<PerfilUsuario?>? _subPerfil;
  bool _carritoVinculado = false;

  User? usuario;
  PerfilUsuario? perfil;

  bool get logueado => usuario != null;
  bool get esAdmin => perfil?.esAdmin ?? false;
  String get nombre => perfil?.nombre ?? usuario?.displayName ?? usuario?.email ?? '';

  void _alCambiarSesion(User? nuevo) {
    _subPerfil?.cancel();
    usuario = nuevo;
    perfil = null;
    _carritoVinculado = false;

    if (nuevo == null) {
      _carrito.desvincular();
      notifyListeners();
      return;
    }

    _subPerfil = _usuarios.streamPerfil(nuevo.uid).listen(
      (p) {
        perfil = p;
        if (p != null && !_carritoVinculado) {
          _carritoVinculado = true;
          _carrito.vincular(nuevo.uid, p.carrito);
        }
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Error al leer el perfil: $e'),
    );
    notifyListeners();
  }

  bool esFavorito(String productoId) => perfil?.favoritos.contains(productoId) ?? false;

  Future<void> alternarFavorito(String productoId) async {
    final u = usuario;
    if (u == null) return;
    await _usuarios.alternarFavorito(u.uid, productoId, agregar: !esFavorito(productoId));
  }

  @override
  void dispose() {
    _subAuth?.cancel();
    _subPerfil?.cancel();
    super.dispose();
  }
}
