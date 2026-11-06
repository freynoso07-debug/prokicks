import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/tema.dart';
import '../services/auth_service.dart';
import '../widgets/comunes.dart';

enum _Modo { ingresar, registrar, recuperar }

/// Ingreso, registro y recuperación de contraseña (Firebase Authentication).
/// Al terminar bien, cierra la pantalla devolviendo true.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  _Modo _modo = _Modo.ingresar;
  bool _cargando = false;
  bool _verPassword = false;
  String? _error;
  String? _aviso;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _cambiarModo(_Modo modo) => setState(() {
        _modo = modo;
        _error = null;
        _aviso = null;
      });

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
      _aviso = null;
    });

    try {
      switch (_modo) {
        case _Modo.ingresar:
          await _auth.iniciarSesion(email: _email.text.trim(), password: _password.text);
          break;
        case _Modo.registrar:
          await _auth.registrar(
            nombre: _nombre.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
          break;
        case _Modo.recuperar:
          await _auth.recuperarPassword(_email.text.trim());
          if (!mounted) return;
          setState(() => _aviso = 'Te enviamos un mail para restablecer la contraseña.');
          return;
      }
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = AuthService.mensajeDeError(e));
    } catch (e) {
      if (mounted) setState(() => _error = 'Ocurrió un error: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = switch (_modo) {
      _Modo.ingresar => 'INGRESÁ',
      _Modo.registrar => 'CREÁ TU CUENTA',
      _Modo.recuperar => 'RECUPERÁ TU CONTRASEÑA',
    };
    final textoBoton = switch (_modo) {
      _Modo.ingresar => 'INGRESAR',
      _Modo.registrar => 'CREAR CUENTA',
      _Modo.recuperar => 'ENVIAR MAIL',
    };

    return Scaffold(
      appBar: AppBar(title: const LogoProKicks(tamanio: 24)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(titulo, style: Tema.titulo(48)),
                  const SizedBox(height: 8),
                  const Text(
                    'Comprá más rápido, guardá favoritos y seguí tus pedidos.',
                    style: TextStyle(color: Tema.grisTexto),
                  ),
                  const SizedBox(height: 24),
                  if (_modo == _Modo.registrar) ...[
                    TextFormField(
                      controller: _nombre,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre y apellido',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v ?? '').trim().length < 3 ? 'Ingresá tu nombre' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Ingresá tu email';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  if (_modo != _Modo.recuperar) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: !_verPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_cargando) _enviar();
                      },
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _verPassword ? 'Ocultar' : 'Mostrar',
                          icon: Icon(_verPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() => _verPassword = !_verPassword),
                        ),
                      ),
                      validator: (v) => (v ?? '').length < 6 ? 'Mínimo 6 caracteres' : null,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Tema.rojo)),
                  ],
                  if (_aviso != null) ...[
                    const SizedBox(height: 12),
                    Text(_aviso!, style: const TextStyle(color: Tema.verdeOk)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _cargando ? null : _enviar,
                    child: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(textoBoton),
                  ),
                  const SizedBox(height: 12),
                  if (_modo == _Modo.ingresar) ...[
                    TextButton(
                      onPressed: () => _cambiarModo(_Modo.registrar),
                      child: const Text('¿No tenés cuenta? Registrate'),
                    ),
                    TextButton(
                      onPressed: () => _cambiarModo(_Modo.recuperar),
                      child: const Text('Olvidé mi contraseña'),
                    ),
                  ] else
                    TextButton(
                      onPressed: () => _cambiarModo(_Modo.ingresar),
                      child: const Text('Ya tengo cuenta: ingresar'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
