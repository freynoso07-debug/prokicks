# Bitácora de PROKICKS

Registro de lo que se hizo, quién lo hizo, comandos, errores y soluciones. Es la base del
informe técnico (sección "Trabajo de arquitectura").

**Quién hizo cada cosa:**
- **Grupo**: lo hicieron ustedes a mano.
- **Claude (claude.ai)**: chat del 05/11, código y configuración de Firebase desde el Chrome del usuario, a su pedido.
- **Claude Code**: esta etapa, armado del proyecto y corrección de errores, a pedido del usuario.

---

## 05/11/2026 — Firebase (Claude desde el Chrome del usuario, a su pedido)

- Proyecto `PROKICKS` (`prokicks-df2b8`), plan Spark.
- Firestore Standard `(default)` en `southamerica-east1`, modo producción.
- Reglas de `firestore.rules` publicadas.
- Authentication: Correo electrónico/contraseña habilitado.
- App web "PROKICKS Web" registrada; sus datos se pasaron a `lib/firebase_options.dart`.

## 05/11/2026 — Armado del proyecto Flutter (Claude Code)

Entorno: Flutter 3.47.7 (stable), Dart 3.13.5, Windows 10.

| Comando | Para qué |
|---|---|
| `flutter create . --platforms web --project-name prokicks --org com.prokicks` | Crea `pubspec.yaml`, `web/`, `test/`, `.gitignore`, etc. alrededor del `lib/` existente, sin pisarlo (se comprobó comparando el hash de `main.dart` antes y después). |
| `flutter pub add firebase_core firebase_auth cloud_firestore http provider google_fonts image_picker url_launcher` | Agrega los 8 paquetes a `pubspec.yaml`. |
| `flutter pub add "google_fonts:^8.0.0"` | Baja `google_fonts` a la 8 (ver error 1). |
| `flutter analyze` | Análisis estático: 4 errores y 13 avisos la primera vez; al final, `No issues found!`. |
| `flutter test` | 7 tests de cupones y envío: todos pasan. |
| `flutter build web` | Compila para web: `√ Built build\web`. |
| `flutter run -d web-server --web-port 5000` | Se abrió la home y Firebase se inicializó sin errores en la consola. |

Versiones instaladas: `firebase_core ^5.1.0`, `firebase_auth ^7.0.1`, `cloud_firestore ^7.1.0`,
`http ^1.6.0`, `provider ^6.1.5+1`, `google_fonts ^8.0.0`, `image_picker ^1.2.4`, `url_launcher ^6.3.3`.

### Errores de `flutter analyze` y cómo se resolvieron

**Error 1 — `lib/config/tema.dart:57`**
```
error - The argument type 'TextTheme' can't be assigned to the parameter type 'TextTheme?'. - argument_type_not_assignable
```
- **Causa:** `flutter pub add` instaló `google_fonts 9.0.0`, la última versión. Según su CHANGELOG
  ("Migrates to `material_ui` and `cupertino_ui` packages"), pasó a usar el paquete nuevo
  `material_ui`, que tiene su propia clase `TextTheme`. Nuestra app usa la de `flutter/material.dart`.
  Son dos clases con el mismo nombre pero distintas, así que no se pueden mezclar.
- **Solución:** fijar `google_fonts: ^8.0.0` en `pubspec.yaml`. Esa versión usa `flutter/material.dart`.
  La otra opción era migrar toda la app a `material_ui`, que era un cambio mucho más grande y riesgoso.
- **Lección:** no fijar versiones instala siempre la última, y a veces la última trae cambios que rompen el código.

**Error 2 — `lib/widgets/barra_navegacion.dart:44`**
```
error - The constructor being called isn't a const constructor. - const_with_non_const
```
- **Causa:** había `const Flexible(child: ConstrainedBox(...))`, pero en Flutter 3.47 `ConstrainedBox` ya no tiene constructor `const`.
- **Solución:** se sacó el `const` de afuera y se dejó solo en `BoxConstraints` y `_BuscadorBarra`, que sí lo admiten.

**Error 3 — `test/widget_test.dart:16`**
```
error - The name 'MyApp' isn't a class. - creation_with_non_type
```
- **Causa:** `flutter create` genera un test del contador de ejemplo que busca `MyApp`, y en PROKICKS la app se llama `ProKicksApp`.
- **Solución:** se reemplazó por 7 tests de lógica pura sin Firebase. 4 son de cupones: porcentaje,
  tope del monto, mínimo, y vencido, inactivo o sin usos. 3 son de envío: Santa Fe, CABA y gratis desde $200.000.

### Avisos (`info`) corregidos

| Aviso | Dónde | Cambio |
|---|---|---|
| `'value' is deprecated ... Use initialValue instead` | `admin_cupones`, `producto_form_screen` (×2) | `value:` → `initialValue:` |
| Ídem | `checkout_screen`, `perfil_screen` (provincia) | `initialValue:` + `key: ValueKey('prov-${_provincias.length}-$_provincia')`. `initialValue` se lee una sola vez y la lista de Georef llega después, así que la `key` hace que el campo se rearme cuando cambia. |
| `unnecessary_underscores` | 5 `separatorBuilder` | `(_, __)` → `(_, _)` (Dart 3.7+) |
| `use_null_aware_elements` | `pedidos_screen`, `pie_de_pagina` | `if (extra != null) extra!` → `?extra` |
| `dangling_library_doc_comments` | `utils/formato.dart` | `///` → `//` en el comentario inicial |

---

## 05/11/2026 — Primer usuario (Grupo)

- Felipe se registró en la app (`reynosofelipe542@gmail.com`) y completó sus datos en el perfil.
- Cambió a mano su `rol` de `cliente` a `admin` en la consola de Firestore. Las reglas no permiten hacerlo desde la app.
- Felipe encontró el primer error de uso: después de "GUARDAR CAMBIOS" el perfil no volvía al inicio (error 4).

## 05/11/2026 — Prueba manual completa (Claude Code, con la sesión de admin de Felipe)

Se probó la versión compilada (`flutter build web`, servida en `localhost:5050`) en el navegador de Claude.
Felipe inició sesión, porque Claude no escribe contraseñas en Firebase Auth. Desde el panel se cargaron
los datos de ejemplo (20 botines y 3 cupones).

**Qué se probó y anduvo bien:** home y tarjetas con el dibujo del botín; buscador (Enter → catálogo);
filtros por marca y talle con chips; orden por precio; página de producto (aviso si no hay talle elegido,
talle agotado tachado, "quedan solo 3 unidades", referencia en USD con DolarAPI); favorito; carrito;
cupón inexistente (mensaje de error), `FINDE20` en minúsculas (-$200.000) y `BIENVENIDA10`
(10% de $94.999 = $9.500); envío gratis desde $200.000, Mendoza $8.900 y retiro gratis;
Georef (provincias y localidades: "godoy" → "Godoy Cruz"); los datos del checkout quedan guardados en el
perfil; pago aprobado, rechazado, reintento y pendiente; el pedido descuenta stock (Predator Elite
25 → 23, ventas 121 → 123) y la cancelación lo devuelve (Copa Pure 40 → 39 → 40); admin: cambio de estado de pedido, alta y
borrado de cupón, edición de precio y stock por talle, usuarios (tu propio rol bloqueado), gráficos;
vista de celular con la hoja de filtros.

**Esperado, no es error:** el mail no sale porque falta configurar EmailJS (la pantalla lo avisa).
La referencia en USD tarda unos segundos en aparecer, mientras responde DolarAPI.

### Errores encontrados en las pruebas y cómo se resolvieron

| # | Error | Causa | Solución | Archivo |
|---|---|---|---|---|
| 4 | Al guardar los datos del perfil no volvía al inicio | `_guardar` solo mostraba "Datos guardados." | `Navigator.popUntil((r) => r.isFirst)` después de guardar | `screens/perfil_screen.dart` |
| 5 | El aviso "Agregaste… al carrito / VER CARRITO" no se cerraba nunca | Desde Flutter 3.29, un SnackBar con botón (`action`) no se cierra solo | `persist: false` en `mostrarMensaje` | `utils/navegacion.dart` |
| 6 | "Cargar datos de ejemplo" duplicaba los 20 botines cada vez y reiniciaba los usos de los cupones | Creaba los productos con ID automático (`_col.doc()`) y pisaba los cupones con `set` | Saltea los productos cuyo SKU ya existe y los cupones que ya están; el mensaje dice cuántos agregó | `services/productos_service.dart`, `admin_resumen.dart`, `admin_productos.dart` |
| 7 | Al reintentar un pago quedaban dos pantallas de detalle apiladas (había que tocar "atrás" dos veces) | El detalle abría el pago con `push` y el pago abría otro detalle | `pushReplacement` en "Reintentar / Pagar ahora" | `screens/pedido_detalle_screen.dart` |
| 8 | Al cancelar un pedido con cupón, el uso del cupón no se devolvía | La transacción de cancelación solo devolvía stock | Lee el cupón dentro de la transacción y hace `usos - 1` si todavía existe | `services/pedidos_service.dart` |
| 9 | En el panel, las secciones cortas (Cupones, Usuarios) aparecían centradas verticalmente con un hueco arriba | Un `Row` centra a sus hijos en vertical por defecto | `crossAxisAlignment: CrossAxisAlignment.stretch` | `screens/admin/admin_screen.dart` |
| 10 | Los gráficos del resumen ocupaban la mitad de la pantalla, uno por fila | Ancho fijo de 520 px: dos no entraban en 1280 | Ancho calculado: dos columnas si entran, una si no | `screens/admin/admin_resumen.dart` |
| 11 | El tachito de un cupón lo borraba sin preguntar | Faltaba confirmación (Productos sí la tenía) | Diálogo "¿Eliminar el cupón…?" | `screens/admin/admin_cupones.dart` |

Después de los arreglos: `flutter analyze` → `No issues found!`, `flutter test` → 7 tests OK,
`flutter build web` → OK. Cada arreglo se volvió a probar en el navegador.

**Detalles menores que quedan (se pueden mencionar como mejoras):**
- Los datos de ejemplo traen `ventas` inventadas (para ordenar por "más vendidos"), por eso
  "Productos más vendidos" muestra cientos de unidades aunque haya un solo pedido real.
- Un pedido cancelado conserva la etiqueta de pago ("Pago pendiente"), porque solo cambia el estado del pedido.
- El buscador de la barra busca al apretar Enter, no mientras escribís. El del catálogo sí filtra en tiempo real.

---

## 05/11/2026 — EmailJS (Grupo, con guía de Claude Code)

- **Grupo (Felipe):** creó la cuenta en EmailJS (plan gratis) y conectó Gmail en *Email Services*
  (Service ID `service_dnxv91u`). Creó el template a partir de "Contact Us", borró el contenido de ejemplo y
  cargó las 6 variables (Template ID `template_7s4i8tz`). Copió la Public Key de *Account → General → API keys*.
- **Error al crear el servicio:** con "Send test email to verify configuration" tildado, EmailJS respondió:
  ```
  412 Gmail_API: Not found the sessional location
  ```
  Es un error de la conexión entre EmailJS y Google, no de la app. Se recomendó reconectar Gmail tildando
  el permiso "Enviar correo en tu nombre" o crear el servicio sin el mail de prueba. *(Completar: cuál de
  las dos funcionó.)*
- **Claude Code:** pegó las 3 claves en `lib/config/api_config.dart`. También cambió
  `notificaciones_service.dart` para separar los productos con `<br>` en vez de `\n`, porque el template es HTML
  y los saltos de línea se pierden. En el template esa variable va con tres llaves: `{{{order_detail}}}`.
- **Prueba:** compra de 2 productos (F50 League MG + Predator Club IC, $279.998) con pago aprobado. La app
  mostró "Te enviamos el detalle a reynosofelipe542@gmail.com", o sea que EmailJS respondió 200.
  Felipe confirmó que el mail llegó bien, con cada producto en su renglón. *(Completar: captura del mail y de Email History.)*
- La Public Key es pública por diseño (se usa desde el navegador). La Private Key no se usa.

---

## 05/11/2026 — Cloudinary (Grupo, con guía de Claude Code)

- **Grupo (Felipe):** creó la cuenta en Cloudinary (plan gratis). Sacó el Cloud name (`olvmfcyl`) del
  recuadro de arriba a la izquierda / *View API Keys*. Creó el upload preset `prokicks_unsigned` en
  *Settings → Upload → Upload Presets → Add Upload Preset* con **Signing mode: Unsigned**.
- **Por qué Unsigned:** con un preset Signed, la app tendría que firmar cada subida con el API Secret, y esa
  clave no puede estar en el navegador. Con Unsigned las reglas las define el preset y la app solo manda su nombre.
  El API Key y el API Secret no se usan.
- **Claude Code:** pegó Cloud name y preset en `lib/config/api_config.dart`. `flutter analyze` → sin problemas.
- **Cómo funciona:** `cloudinary_service.dart` hace un POST multipart a
  `https://api.cloudinary.com/v1_1/olvmfcyl/image/upload` con `file` y `upload_preset`. Del JSON de respuesta
  usa `secure_url` y la guarda en `imagenes[]` del producto en Firestore.
- *(Completar: prueba de subida desde el panel y captura de la Media Library.)*

---

## 06/11/2026 — Fotos de productos por URL (Claude Code, a pedido del grupo)

**Decisión:** las fotos salen solo de bancos con licencia libre (Unsplash y Pexels). Se descartó un álbum
de Yupoo (`wanlian123`) que propuso el grupo: es un vendedor de réplicas y las fotos tienen derechos de las
marcas. Regla para elegir: tiene que coincidir el color y, si se puede, el tipo de suela, y **nunca se pone una
foto con el logo de otra marca** (por ejemplo, una foto de Nike en un Puma). Donde no hubo una foto que
coincida, queda el dibujo automático (`BotinPainter`).

Se revisaron unas 70 fotos con una hoja de contactos y se cargaron 8 con **Agregar por URL** en el panel admin.
Antes se comprobó que cada URL respondiera `200 image/jpeg`. Después se verificó en Firestore
(`productos/*.imagenes`) y en la tienda.

| Producto | Fuente | Foto |
|---|---|---|
| Nike Mercurial Vapor 16 Elite FG | Unsplash | `photo-1633306603064-582250e68a1a` (botín Nike verde neón) |
| Nike Mercurial Vapor 16 Academy MG | Pexels | `27299916` (botines Nike rosas con pelota) |
| Nike Phantom GX 2 Club TF | Pexels | `19882423` (botines Nike naranja y gris; tienen tapones, no suela TF) |
| Nike Tiempo Legend 10 Academy AG | Unsplash | `photo-1684355412785-e05594831b0c` (botín negro y dorado) |
| Nike Streetgato IC | Unsplash | `photo-1768696082282-df2812a4f7d8` (Nike negro con suela azul) |
| Adidas Copa Pure 2 Club TF | Unsplash | `photo-1552066344-c9babee39cd0` (Adidas blanco de caña baja) |
| Adidas Predator Club IC | Unsplash | `photo-1511886929837-354d827aae26` (Adidas negro y rojo sobre pelota) |
| Puma Ultra 5 Pro FG | Pexels | `32574010` (botín turquesa, sin logo visible) |

Licencias: [Unsplash License](https://unsplash.com/license) y [Pexels License](https://www.pexels.com/license/).
Las dos permiten uso gratuito, comercial y no comercial, sin pedir permiso.

**Quedan con el dibujo (11):** Adidas F50 League y X Crazyfast (las fotos de esos colores tenían logo de Nike),
Puma Future 8, King y Truco, los 3 New Balance y los 3 Mizuno (casi no hay fotos libres de esas marcas).

**Adidas Predator Elite FG:** tiene una foto cargada por URL desde `photo.yupoo.com/wanlian123/...`.
No la cargó Claude. Claude recomendó reemplazarla por una foto libre: es de un vendedor de réplicas y el
servidor bloquea las peticiones por CORS. El grupo decidió dejarla.

---

## Pendiente (completar el grupo)
- [x] Cuenta de EmailJS: Service ID, Template ID y Public Key. Docs: https://www.emailjs.com/docs/rest-api/send/
- [ ] Cuenta de Cloudinary: Cloud name y preset Unsigned. Docs: https://cloudinary.com/documentation/upload_images#unsigned_upload
- [ ] Documentación leída (links).
