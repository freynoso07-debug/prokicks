import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/tema.dart';
import '../models/producto.dart';
import '../providers/sesion_provider.dart';
import '../utils/navegacion.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/comunes.dart';
import '../widgets/producto_card.dart';

/// Lista de favoritos (se guarda en el perfil del usuario en Firestore).
class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionProvider>();
    final todos = context.watch<List<Producto>?>();

    if (!sesion.logueado) {
      return Scaffold(
        appBar: const BarraNavegacion(),
        body: EstadoVacio(
          icono: Icons.favorite_border,
          titulo: 'INICIÁ SESIÓN',
          texto: 'Ingresá para guardar tus botines favoritos.',
          textoBoton: 'INGRESAR',
          alPresionar: () => asegurarSesion(context),
        ),
      );
    }

    final ids = sesion.perfil?.favoritos ?? const <String>[];
    final favoritos = (todos ?? const <Producto>[])
        .where((p) => p.activo && ids.contains(p.id))
        .toList();

    return Scaffold(
      appBar: const BarraNavegacion(),
      body: todos == null
          ? const Center(child: CircularProgressIndicator())
          : favoritos.isEmpty
              ? EstadoVacio(
                  icono: Icons.favorite_border,
                  titulo: 'NO TENÉS FAVORITOS',
                  texto: 'Tocá el corazón de un botín para guardarlo acá.',
                  textoBoton: 'VER BOTINES',
                  alPresionar: () => irACatalogo(context),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Text('MIS FAVORITOS (${favoritos.length})', style: Tema.titulo(44)),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 290,
                          mainAxisExtent: 400,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: favoritos.length,
                        itemBuilder: (_, i) => ProductoCard(producto: favoritos[i]),
                      ),
                    ),
                  ],
                ),
    );
  }
}
