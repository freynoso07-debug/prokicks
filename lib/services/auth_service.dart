import 'package:firebase_auth/firebase_auth.dart';

import 'usuarios_service.dart';

/// Registro, inicio de sesión y recuperación de contraseña con
/// Firebase Authentication (email y contraseña).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UsuariosService _usuarios = UsuariosService();

  Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final usuario = credencial.user!;
    await usuario.updateDisplayName(nombre);
    // Además de la cuenta en Auth, creamos el documento del perfil.
    await _usuarios.crearPerfil(uid: usuario.uid, nombre: nombre, email: email);
  }

  Future<void> iniciarSesion({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> recuperarPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> cerrarSesion() => _auth.signOut();

  /// Traduce los códigos de error de Firebase a mensajes en español.
  static String mensajeDeError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El email no tiene un formato válido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese email.';
      case 'weak-password':
        return 'La contraseña tiene que tener al menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'El ingreso con email no está activado en Firebase '
            '(Authentication → Sign-in method → Correo electrónico/contraseña).';
      case 'network-request-failed':
        return 'Sin conexión. Revisá internet e intentá de nuevo.';
      case 'too-many-requests':
        return 'Demasiados intentos. Esperá un rato y probá de nuevo.';
      default:
        return 'Error de autenticación (${e.code}).';
    }
  }
}
