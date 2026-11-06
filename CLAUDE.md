# PROKICKS — contexto completo para seguir el proyecto

Este archivo resume todo lo hecho en el chat de Claude (claude.ai, proyecto "api juansito", 05/11/2026)
para que Claude Code pueda continuar y terminar el trabajo. Hablale al usuario en español rioplatense.

---

## 1. Qué es esto (la consigna de la facultad)

Proyecto **grupal** de clase. Hay que entregar una app **Flutter** que integre **APIs externas** y
**Firebase**. El uso de IA para generar código era obligatorio: la evaluación no mira cuánto código
tipearon, sino **cómo integraron las APIs, cómo estructuraron los datos y cuánto entienden** lo que construyeron.

**Opción elegida: E-Commerce.** (La otra opción era "Central Deportiva".)

**Entrega: alrededor del 12/11/2026** (una semana desde el 05/11/2026). Tres cosas:

1. **Código fuente:** `.zip` del proyecto Flutter o link a un repo de GitHub.
2. **Documento de proceso (OBLIGATORIO)**, informe técnico con:
   - **Opción elegida:** E-Commerce.
   - **Esquema de integración:** explicar con sus palabras cómo se conectó cada API externa y qué función cumple en la app.
   - **Trabajo de arquitectura:** qué hicieron ellos por fuera de pedirle código a la IA (crear cuentas de
     desarrollador, obtener API Keys y tokens, leer documentación, instalar paquetes en `pubspec.yaml`,
     configurar permisos, adaptar los JSON, resolver errores que la IA no pudo resolver sola).
3. **Evidencia de Firebase:** capturas de la consola donde se vea que la app guardó registros en la base.

**Importante sobre el informe:** tiene que reflejar lo que realmente hizo el grupo. Parte de la
configuración de Firebase la hizo Claude desde el navegador del usuario, a pedido suyo (ver sección 4);
el informe lo tiene que contar así, sin atribuírselo al grupo. El README pide llevar una **bitácora**
(cuentas, comandos, errores con mensaje exacto y solución, documentación leída): usala como base del informe.

---

## 2. El producto: PROKICKS

Tienda online de **botines de fútbol**. El usuario trajo un prompt pensado para Next.js + PostgreSQL +
Prisma + Auth.js + Mercado Pago SDK + Cloudinary. **Decisión tomada con el usuario:** como el profe exige
Flutter + Firebase, se hizo **todo el alcance de ese prompt pero en Flutter Web + Firebase**.

- **Plataforma:** Flutter **web**, se prueba con `flutter run -d chrome`. El usuario tiene Flutter instalado.
- **Identidad:** nombre PROKICKS, lema "ELEVÁ TU JUEGO". Colores: negro `#0B0B0B`, blanco, verde eléctrico
  `#C6FF00` y naranja `#FF5A1F`. Tipografías Barlow Condensed (títulos, itálica, peso 800) e Inter (texto), vía `google_fonts`.
- **Marcas:** Nike, Adidas, Puma, New Balance, Mizuno.
- **Superficies:** FG (césped natural firme), AG (césped artificial), MG (múltiples superficies),
  TF (sintético corto), IC (fútbol sala).
- **Talles:** AR 38 a 45, con stock por talle.
- **Fotos:** se suben desde el panel admin a Cloudinary (o por URL). Sin fotos, la app dibuja un botín
  genérico con `CustomPainter` (`widgets/botin_imagen.dart`) usando los colores del producto y una suela
  distinta según la superficie. No se usan fotos ni logos reales de las marcas.
- **Pagos:** Mercado Pago. Sin credenciales, la app funciona en **MODO PRUEBA** (marcado en pantalla): el
  pago se simula como aprobado, pendiente o rechazado. La integración real queda armada con Cloud Functions
  (necesita plan Blaze, que el grupo no tiene).

### Funcionalidades implementadas

- **Home:** navbar (logo, categorías, buscador, favoritos, usuario, carrito con contador), banner principal
  animado con "ELEVÁ TU JUEGO" y "COMPRAR AHORA", franja de beneficios (envíos, cuotas, cambios), destacados,
  compra por superficie, nuevos lanzamientos, banner de ofertas, ofertas, marcas destacadas y footer completo
  (categorías, ayuda en diálogos, contacto mailto, redes de ejemplo).
- **Catálogo:** buscador en tiempo real (sin tildes, por modelo, marca, superficie, SKU o color), filtros por
  marca, superficie, talle con stock, rango de precio, ofertas, nuevos y destacados; orden por relevancia,
  precio menor o mayor, más vendidos y novedades; chips de filtros activos; panel lateral en desktop y hoja
  inferior en celular.
- **Producto:** galería, etiquetas (nuevo, % de descuento), precio anterior tachado, cuotas, referencia en USD,
  colores, selector de talle (agotados tachados), aviso de últimas unidades, selector de cantidad limitado al
  stock, favorito, guía de talles, descripción y relacionados por superficie.
- **Carrito:** cambiar cantidad, eliminar, aplicar o quitar cupón, subtotal, descuento, aviso de envío gratis;
  detecta productos sin stock o desactivados. Se guarda en el perfil del usuario en Firestore.
- **Checkout:** datos de contacto, envío a domicilio (provincia y localidad desde Georef, costo por zona) o
  retiro en el local, opción de guardar los datos en el perfil, resumen y "PAGAR CON MERCADO PAGO".
- **Pedido:** se crea en una **transacción de Firestore** que relee precio y stock reales, valida cupón y stock
  por talle, descuenta stock, suma ventas, cuenta el uso del cupón y crea el pedido.
- **Pago de prueba:** pantalla de pago simulado. Un pago aprobado pasa el pedido a "pagado" y manda mail por EmailJS.
- **Mis pedidos y detalle:** en tiempo real, línea de tiempo de estados, reintentar pago, cancelar (devuelve el stock).
- **Favoritos, perfil** (datos y dirección), **login, registro y recuperación de contraseña**.
- **Panel admin** (rol `admin`):
  - **Resumen:** métricas (ventas totales, pedidos, ticket promedio, stock) y gráficos hechos con widgets (ingresos de 6 meses, más vendidos, stock por marca, pedidos por estado).
  - **Productos:** listado, búsqueda, alta, edición (precios, descuento, stock por talle, estados, visible u oculto, fotos por Cloudinary o URL) y borrado.
  - **Pedidos:** filtro por estado y cambio de estado; cancelar devuelve el stock.
  - **Cupones:** crear (porcentaje o monto, mínimo, usos máximos, vencimiento), activar, desactivar y eliminar.
  - **Usuarios:** lista y cambio de rol cliente/admin (no podés cambiarte el tuyo).
  - **Datos de ejemplo:** botón "Cargar datos de ejemplo" con 20 botines y 3 cupones.

---

## 3. Archivos creados (zip `PROKICKS_codigo.zip`, 63 archivos)

```
prokicks/
├── CLAUDE.md                     este archivo
├── README.md                     guía paso a paso para el grupo (instalación, cuentas, capturas, arquitectura, errores comunes)
├── firestore.rules               reglas de seguridad (YA PUBLICADAS en Firebase)
├── .firebaserc                   proyecto por defecto: prokicks-df2b8
├── functions/                    Cloud Functions de Mercado Pago (Node 20). NO desplegadas.
│   ├── index.js                  crearPreferencia + webhookMercadoPago
│   └── package.json              firebase-functions ^6, firebase-admin ^13
└── lib/
    ├── main.dart                 Firebase.initializeApp + MultiProvider (carrito, sesión, cotización, StreamProvider del catálogo) + tema + scroll con mouse
    ├── firebase_options.dart     conexión con el proyecto PROKICKS (app web "PROKICKS Web")
    ├── config/
    │   ├── api_config.dart       URLs y claves PÚBLICAS de las APIs (placeholders de EmailJS y Cloudinary; URL de Mercado Pago vacía = modo prueba)
    │   └── tema.dart             colores, tipografías y ThemeData
    ├── data/datos_ejemplo.dart   seed: 20 productos (4 por marca, todas las superficies) y 3 cupones
    ├── models/
    │   ├── catalogo.dart         marcas, superficies (código y descripción), talles
    │   ├── producto.dart         Producto.fromFirestore, descuento %, stock por talle, buscarProducto()
    │   ├── item_carrito.dart     producto + talle + cantidad; clave "productoId-talle"; toMap/fromMap
    │   ├── cupon.dart            validación (activo, vencimiento, usos, mínimo) y cálculo de descuento
    │   ├── usuario.dart          PerfilUsuario (rol, favoritos, carrito, dirección) + Direccion
    │   ├── envio.dart            OpcionEnvio (retiro o domicilio, costo, demora)
    │   ├── pedido.dart           Pedido + EstadosPedido + EstadosPago
    │   ├── cotizacion.dart       JSON de DolarAPI
    │   └── filtros.dart          FiltrosCatalogo (búsqueda normalizada, filtros y orden) + OrdenCatalogo
    ├── services/
    │   ├── auth_service.dart          registro (crea usuarios/{uid} con rol 'cliente'), login, recuperar contraseña, errores en español
    │   ├── usuarios_service.dart      perfil en tiempo real, datos, favoritos, carrito; admin: listar y cambiar rol
    │   ├── productos_service.dart     stream del catálogo, crear, actualizar, eliminar, cargarDatosDeEjemplo (batch)
    │   ├── pedidos_service.dart       crearPedido (TRANSACCIÓN), registrarPago, cancelar (transacción que devuelve stock), streams; admin: todos y cambiarEstado
    │   ├── cupones_service.dart       validar (equivale a /api/coupons/validate); admin: crear, activar, eliminar
    │   ├── envio_service.dart         tabla de costos por provincia (aislada para cambiarla por una API de logística)
    │   ├── georef_service.dart        provincias y localidades con caché y lista de respaldo
    │   ├── dolar_service.dart         DolarAPI
    │   ├── email_service.dart         POST a EmailJS
    │   ├── notificaciones_service.dart  arma el mail de confirmación y marca emailEnviado
    │   ├── cloudinary_service.dart    subida multipart sin firma
    │   └── pago_service.dart          modo prueba o llamada a la Cloud Function y redirección al checkout (url_launcher, _self)
    ├── providers/
    │   ├── carrito_provider.dart      carrito en memoria + guardado en Firestore, cupón aplicado, sincroniza precios
    │   ├── sesion_provider.dart       usuario de Auth + perfil de Firestore; vincula o desvincula el carrito
    │   └── cotizacion_provider.dart   dólar oficial (se pide una sola vez)
    ├── screens/
    │   ├── home_screen.dart           home completa; detecta ?pedido=ID al volver de Mercado Pago
    │   ├── catalogo_screen.dart       catálogo + PanelFiltros
    │   ├── producto_screen.dart       página de producto
    │   ├── carrito_screen.dart        carrito y cupones
    │   ├── checkout_screen.dart       checkout (Georef y envío) y creación del pedido
    │   ├── pago_prueba_screen.dart    pago simulado (MODO PRUEBA)
    │   ├── pedido_detalle_screen.dart detalle, reintentar pago, cancelar
    │   ├── pedidos_screen.dart        historial + TarjetaPedido (también la usa el admin)
    │   ├── favoritos_screen.dart
    │   ├── perfil_screen.dart
    │   ├── login_screen.dart          ingresar, registrar, recuperar; devuelve true con pop
    │   └── admin/
    │       ├── admin_screen.dart      shell con NavigationRail o NavigationBar; protegido por rol; TarjetaMetrica y TarjetaGrafico
    │       ├── admin_resumen.dart     estadísticas y gráficos
    │       ├── admin_productos.dart
    │       ├── producto_form_screen.dart  alta y edición con image_picker + Cloudinary
    │       ├── admin_pedidos.dart
    │       ├── admin_cupones.dart
    │       └── admin_usuarios.dart
    ├── widgets/
    │   ├── barra_navegacion.dart      AppBar de la tienda (menú de categorías, buscador, íconos)
    │   ├── producto_card.dart         tarjeta con hover, etiquetas y favorito
    │   ├── seccion_productos.dart     fila horizontal con "VER TODO"
    │   ├── botin_imagen.dart          Image.network con fallback al dibujo (BotinPainter) + colorDesdeNombre
    │   ├── comunes.dart               LogoProKicks, EtiquetaChica, ChipSuperficie, EstadoChip, EstadoVacio, TituloSeccion, FilaResumen
    │   ├── dialogos_info.dart         guía de talles y ayuda (envíos, cambios, pagos)
    │   ├── pie_de_pagina.dart         footer
    │   └── graficos.dart              BarrasVerticales y BarrasHorizontales (sin librerías)
    └── utils/
        ├── formato.dart               precios ARS y USD en formato argentino, fechas
        └── navegacion.dart            asegurarSesion, irACatalogo, irAProducto, mostrarMensaje
```

Hay una versión anterior descartada, **MiTienda** (`MiTienda_codigo.zip`: Flutter + Fake Store API +
DolarAPI + EmailJS + Firebase). PROKICKS la reemplazó; ignorala.

---

## 4. Estado de Firebase (configurado el 05/11/2026)

**Proyecto:** `PROKICKS`. **ID:** `prokicks-df2b8`. **Número:** `684679317536`. **Plan:** Spark (gratis).
Cuenta de Google del usuario: Felipe.

Lo que hizo Claude desde el Chrome del usuario (con la extensión Claude in Chrome), a pedido suyo:

| Qué | Configuración |
|---|---|
| Cloud Firestore | Edición Standard, base `(default)`, ubicación `southamerica-east1 (São Paulo)` (no se puede cambiar), modo producción. Copias de seguridad sin activar (piden Blaze). |
| Reglas | Contenido de `firestore.rules`, publicadas a las 10:10 del 05/11. |
| Authentication | Proveedor Correo electrónico/contraseña habilitado (sin vínculo por email). En Configuración → Acciones del usuario están activados creación (registro), eliminación y protección de enumeración de emails. |
| App web | "PROKICKS Web" registrada en Configuración del proyecto → Tus apps. Sin Hosting vinculado. |

**Todavía no hay:** usuarios, documentos en Firestore, Hosting, Cloud Functions, Storage ni flujo de Analytics.

### Configuración de la app web (está en `lib/firebase_options.dart`)

Estos valores **no son secretos** (son públicos en cualquier app web de Firebase); la seguridad la dan las reglas.

```
apiKey:            AIzaSyANbg2zSFdkD0iAqgzMoSBvevod6kKlNmQ
authDomain:        prokicks-df2b8.firebaseapp.com
projectId:         prokicks-df2b8
storageBucket:     prokicks-df2b8.firebasestorage.app
messagingSenderId: 684679317536
appId:             1:684679317536:web:a2077725c3f14c4102d445
measurementId:     G-EYCH41WL40
```

`firebase_options.dart` se escribió a mano con esos datos (mismo formato que `flutterfire configure`,
solo plataforma web), así que no hace falta correr FlutterFire.

---

## 5. APIs externas y claves

| Servicio | Uso | Endpoint | Clave / estado |
|---|---|---|---|
| Firebase Auth + Firestore | usuarios y base de datos | SDK | configurado (sección 4) |
| **Georef** (Gobierno de Argentina) | provincias y localidades del checkout | `GET https://apis.datos.gob.ar/georef/api/v2.0/provincias?campos=id,nombre&max=30` y `/localidades?provincia=X&campos=nombre&max=5000` → `{provincias:[{id,nombre}]}` / `{localidades:[{nombre}]}` | sin key |
| **DolarAPI** | dólar oficial: referencia en USD y `cotizacionDolar` guardada en cada pedido | `GET https://dolarapi.com/v1/dolares/oficial` → `{compra, venta, fechaActualizacion, ...}` (el 04/11/2026: venta 1570) | sin key |
| **EmailJS** | mail de confirmación cuando un pago se aprueba | `POST https://api.emailjs.com/api/v1.0/email/send` con `{service_id, template_id, user_id (Public Key), template_params}` | **FALTA:** `TU_SERVICE_ID`, `TU_TEMPLATE_ID`, `TU_PUBLIC_KEY` en `api_config.dart` |
| **Cloudinary** | subir fotos desde el panel | `POST https://api.cloudinary.com/v1_1/<cloud_name>/image/upload` multipart con `file` y `upload_preset` → `secure_url` | **FALTA:** `TU_CLOUD_NAME`, `TU_UPLOAD_PRESET` (preset en modo **Unsigned**) |
| **Mercado Pago** | Checkout Pro | Cloud Function `crearPreferencia` → `POST https://api.mercadopago.com/checkout/preferences`; webhook → `GET /v1/payments/{id}` | **No configurado → MODO PRUEBA.** `ApiConfig.mpCrearPreferenciaUrl = ''`. El Access Token iría como secreto `MP_ACCESS_TOKEN` (`firebase functions:secrets:set MP_ACCESS_TOKEN`), nunca en la app. Requiere plan Blaze. |

**Variables del template de EmailJS** (tienen que coincidir exactamente):
`{{to_email}}` (en el campo To Email), `{{to_name}}`, `{{order_id}}`, `{{order_detail}}`, `{{order_delivery}}`, `{{order_total}}`.

**Cloud Functions** (`functions/index.js`), región `southamerica-east1`, Node 20:
- `crearPreferencia`: POST con `Authorization: Bearer <ID token de Firebase>` y body `{pedidoId, urlRetorno}`. Verifica el token y que el pedido sea del usuario y espere pago; arma una preferencia con el total leído de Firestore, `external_reference = pedidoId`, `notification_url` al webhook, `back_urls` y `auto_return` solo si la URL es https. Devuelve `{id, init_point, sandbox_init_point}`.
- `webhookMercadoPago`: recibe `type=payment` y `data.id`, consulta el pago a la API y actualiza `pago.estado` (aprobado, pendiente o rechazado), `pago.referencia` y `estado = 'pagado'` si se aprobó.
- `ApiConfig.mpUsarSandbox = true` hace que se use `sandbox_init_point`.

---

## 6. Modelo de datos en Firestore

```
productos/{autoId}
  nombre, marca, superficie ('FG'|'AG'|'MG'|'TF'|'IC'), sku, precio (ARS), precioAnterior (null o mayor),
  descripcion, colores[], imagenes[] (URLs), talles {"38": n, ..., "45": n}, nuevo, destacado, oferta,
  activo, ventas (unidades), creadoEn, actualizadoEn
usuarios/{uid}
  nombre, email, rol ('cliente'|'admin'), telefono, direccion {calle, numero, localidad, provincia, codigoPostal},
  favoritos [productoId], carrito [ItemCarrito.toMap], creadoEn
pedidos/{autoId}
  uid, email, nombre, telefono, items [{productoId, nombre, marca, superficie, talle, sku, imagen, colores, precio, cantidad}],
  cantidadProductos, subtotal, descuento, cuponCodigo, envio {metodo, descripcion, costo, demora},
  direccion {...} o null, total, cotizacionDolar, totalUsd,
  estado ('pendiente_pago'|'pagado'|'preparando'|'enviado'|'entregado'|'cancelado'),
  pago {metodo:'mercadopago', modo:'prueba'|'real', estado:'pendiente'|'aprobado'|'rechazado', referencia, preferenciaId?, detalle?},
  emailEnviado, creadoEn, actualizadoEn
cupones/{CODIGO}
  tipo ('porcentaje'|'monto'), valor, minimo, activo, vence (Timestamp o null), usos, usosMax (null = ilimitado), creadoEn
```

Las consultas por usuario usan solo `where('uid', ==)` y se ordenan en Dart, así no hace falta crear índices compuestos.

**Datos de ejemplo:** 20 botines con precios entre $79.999 y $499.999. Cupones:
- `BIENVENIDA10`: 10%, sin mínimo.
- `PROKICKS15K`: $15.000 de descuento con compra mínima de $150.000.
- `FINDE20`: 20% con compra mínima de $300.000, hasta 50 usos.

**Envío** (`envio_service.dart`):

| Destino | Costo | Demora |
|---|---|---|
| Santa Fe | $4.500 | 1 a 2 días |
| Buenos Aires, CABA, Córdoba y Entre Ríos | $6.500 | 2 a 4 días |
| Resto del país | $8.900 | 4 a 7 días |
| Compras desde $200.000 | gratis | según destino |
| Retiro en el local | gratis | 24 h |

### Reglas (`firestore.rules`, publicadas)

- **`productos`:** lectura pública; crear y borrar solo admin; actualizar admin, o un usuario logueado si solo cambia `talles` y `ventas` (lo necesita la transacción).
- **`usuarios`:** lee el dueño o un admin; crear solo el dueño con `rol == 'cliente'`; el dueño actualiza todo menos `rol`; nadie borra.
- **`pedidos`:** crear el dueño (`uid == auth.uid`); leer el dueño o un admin; el dueño solo cambia `pago`, `estado`, `emailEnviado` y `actualizadoEn`; nadie borra.
- **`cupones`:** leer con sesión iniciada; crear y borrar solo admin; actualizar admin, o un logueado si solo cambia `usos`.
- **`esAdmin()`:** hace `get()` sobre `usuarios/{uid}`.

**Limitación conocida (documentada en el README):** en modo prueba el navegador registra el pago, y las
reglas dejan a cualquier logueado tocar stock y ventas. En producción eso iría a Cloud Functions.

---

## 7. Paquetes

```bash
flutter pub add firebase_core firebase_auth cloud_firestore http provider google_fonts image_picker url_launcher
```

No se fijaron versiones a propósito: se instalan las actuales. El código usa Dart 3 (records `$1`,
switch expressions) y `Image.network(webHtmlElementStrategy: ...)`, que pide **Flutter 3.29 o más nuevo**.

---

## 8. IMPORTANTE: el código nunca se compiló

En el entorno de claude.ai no había Flutter. Se revisaron imports, llaves y paréntesis, y tipos a mano y
con scripts, pero **nunca se corrió `flutter analyze` ni `flutter run`**. Puntos a vigilar:

- `DropdownButtonFormField(value: ...)`: en Flutter muy nuevo puede estar deprecado a favor de `initialValue` (sería solo un warning).
- `webHtmlElementStrategy` en `widgets/botin_imagen.dart`: si Flutter es viejo, `flutter upgrade` o borrar esa línea.
- `Autocomplete` en `checkout_screen.dart`: usa `initialValue` y una `key` por provincia para reiniciarse.
- `StreamProvider<List<Producto>?>` en `main.dart` con `catchError`.
- `SesionProvider` se crea con `lazy: false` y recibe el `CarritoProvider` ya construido.
- `Tema.claro` usa `ColorScheme.fromSeed` con overrides y `GoogleFonts.interTextTheme`.
- En los gráficos y el slider de precio hay `clamp(...).toDouble()` y `.toInt()` para evitar problemas de tipos `num`.

---

## 9. Qué falta (orden sugerido)

1. **Armar el proyecto local:** `flutter create prokicks --platforms web` (o `flutter create . --platforms web` en una carpeta que ya tenga estos archivos sin pisar `lib/`). Agregar los paquetes y copiar `lib/`, `firestore.rules`, `.firebaserc`, `functions/`, `README.md` y `CLAUDE.md`.
2. **`flutter analyze`:** corregir los errores. Anotar cada error y su solución para el informe.
3. **`flutter run -d chrome`:** probar el registro.
4. **Usuario admin:** el usuario cambia a mano `usuarios/{su uid}.rol` de `cliente` a `admin` en la consola de Firestore. Las reglas impiden hacerlo desde la app. Después se carga el seed con el botón del panel (Resumen o Productos).
5. **EmailJS y Cloudinary:** el usuario crea las cuentas (Claude no crea cuentas). Después se pegan los valores en `api_config.dart`.
6. **Probar todo:** catálogo, filtros, carrito con cupón, checkout con Georef, pago de prueba aprobado, rechazado y pendiente, cancelación (el stock vuelve), panel admin (estados, cupón nuevo, alta y edición de producto, gráficos).
7. **Capturas para la entrega:**
   - Authentication → Users.
   - `productos` con `talles` y `ventas`.
   - `usuarios` con `rol`, `favoritos`, `carrito` y `direccion`.
   - Un pedido con `items`, `envio`, `pago` y `estado`.
   - Un cupón con `usos` mayor a 0.
   - Las reglas publicadas.
   - Extra: el mail recibido y la Media Library de Cloudinary.
8. **Código para entregar:** un repo en GitHub (el `.gitignore` de Flutter excluye `build/` y `.dart_tool/`; excluir también `functions/node_modules/`) o un zip sin esas carpetas.
9. **Informe técnico** (documento de proceso) con las tres secciones de la sección 1:
   - Explicar cada API: qué hace, endpoint, qué datos manda y recibe, cómo se adaptó el JSON (por ejemplo `num → double`, nombres en inglés traducidos a español, talles como mapa) y en qué archivo está.
   - Explicar la transacción de stock, las reglas y la tabla "endpoint del prompt → solución en Firebase" que está en el README.
   - En "Trabajo de arquitectura", poner solo lo que hizo el grupo y aclarar lo que configuró Claude.
10. **Opcional:** Mercado Pago real (plan Blaze, `firebase init functions`, `npm install`, el secreto `MP_ACCESS_TOKEN`, `firebase deploy --only functions`, pegar la URL en `mpCrearPreferenciaUrl`), y Hosting (`flutter build web` + `firebase deploy --only hosting`) para que funcione `auto_return`.

---

## 10. Reglas para seguir trabajando

- Mantener **Flutter + Firebase**: es requisito del profe. No migrar a otra tecnología.
- No poner claves privadas en la app: Mercado Pago solo en el secreto de Functions, y para Cloudinary nunca el API Secret.
- Mantener el código comentado en español y los nombres en español, como está.
- Ante cada cambio, explicarle al usuario qué se hizo y por qué, porque tiene que entender y defender el proyecto.
