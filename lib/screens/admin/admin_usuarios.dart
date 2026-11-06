import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/tema.dart';
import '../../models/usuario.dart';
import '../../providers/sesion_provider.dart';
import '../../services/usuarios_service.dart';
import '../../utils/formato.dart';
import '../../utils/navegacion.dart';
import '../../widgets/comunes.dart';

/// Usuarios registrados y gestión de roles (cliente / admin).
class AdminUsuarios extends StatefulWidget {
  const AdminUsuarios({super.key});

  @override
  State<AdminUsuarios> createState() => _AdminUsuariosState();
}

class _AdminUsuariosState extends State<AdminUsuarios> {
  final _servicio = UsuariosService();
  late final Stream<List<PerfilUsuario>> _stream = _servicio.todos();

  Future<void> _cambiarRol(PerfilUsuario u, String rol) async {
    try {
      await _servicio.cambiarRol(u.uid, rol);
      if (mounted) mostrarMensaje(context, '${u.nombre} ahora es $rol.');
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo cambiar el rol: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final miUid = context.watch<SesionProvider>().usuario?.uid;

    return StreamBuilder<List<PerfilUsuario>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final usuarios = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TituloSeccion('USUARIOS (${usuarios.length})', tamanio: 40),
            for (final u in usuarios)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Tema.grisBorde),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: u.esAdmin ? Tema.verde : Tema.grisFondo,
                      child: Text(
                        u.nombre.isEmpty ? '?' : u.nombre[0].toUpperCase(),
                        style: const TextStyle(color: Tema.negro, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.uid == miUid ? '${u.nombre} (vos)' : u.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${u.email}'
                            '${u.creadoEn == null ? '' : ' · desde ${fechaCorta(u.creadoEn!)}'}'
                            ' · ${u.favoritos.length} favoritos',
                            style: const TextStyle(fontSize: 13, color: Tema.grisTexto),
                          ),
                        ],
                      ),
                    ),
                    DropdownButton<String>(
                      value: u.rol == 'admin' ? 'admin' : 'cliente',
                      items: const [
                        DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      // No te podés sacar el rol a vos mismo (te quedarías afuera).
                      onChanged: u.uid == miUid
                          ? null
                          : (v) {
                              if (v != null && v != u.rol) _cambiarRol(u, v);
                            },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
