# PROKICKS — E-commerce de botines de fútbol (Flutter Web + Firebase)

Tienda online de botines con home, catálogo con filtros, carrito con cupones, checkout,
pagos con Mercado Pago, favoritos, historial de pedidos y panel de administración con
estadísticas.

## Qué usa la app

| Servicio | Para qué | ¿Cuenta / key? |
|---|---|---|
| **Firebase Authentication** | Registro, ingreso y recuperación de contraseña | Proyecto de Firebase |
| **Cloud Firestore** | Productos, usuarios, carritos, favoritos, pedidos y cupones | Proyecto de Firebase |
| **Georef (Gobierno de Argentina)** | Provincias y localidades para la dirección de envío | No |
| **DolarAPI** | Dólar oficial: precio de referencia en USD y dólar del día en cada pedido | No |
| **EmailJS** | Mail de confirmación cuando se aprueba un pago | Sí: Service ID, Template ID, Public Key |
| **Cloudinary** | Subir fotos de productos desde el panel admin | Sí: Cloud name y Upload preset |
| **Mercado Pago** | Cobro con Checkout Pro (vía Cloud Function) | Sí: Access Token (secreto, en el servidor) |

> **Sin credenciales de Mercado Pago la app funciona en MODO PRUEBA**: el pago se simula
> (aprobado / pendiente / rechazado) y la pantalla lo indica claramente. No se cobra dinero.

> **Este zip trae:** la carpeta `lib/`, las reglas `firestore.rules`, la carpeta `functions/`
> (Mercado Pago) y esta guía. El proyecto Flutter se crea con `flutter create` y los paquetes
> con `flutter pub add`, así se instalan las versiones actuales.

---

## Antes de empezar: bitácora para el informe

El informe pide detallar **qué hicieron ustedes además de pedirle código a la IA**.
Mientras siguen esta guía, anoten en un archivo:

- Cada cuenta creada (Firebase, EmailJS, Cloudinary, Mercado Pago) y qué datos sacaron de cada una.
- Cada comando que corrieron y para qué.
- Cada error: mensaje exacto, qué probaron y cómo se resolvió.
- Capturas de los pasos importantes.
- La documentación que leyeron (links).

---

## Paso 1 — Crear el proyecto

Requisitos: Flutter 3.29 o más nuevo (`flutter --version`), Google Chrome y Node.js 20 o más nuevo.

```bash
flutter create prokicks --platforms web
cd prokicks
```

## Paso 2 — Instalar los paquetes

```bash
flutter pub add firebase_core firebase_auth cloud_firestore http provider google_fonts image_picker url_launcher
```

| Paquete | Para qué |
|---|---|
| `firebase_core` | Conectar la app con Firebase |
| `firebase_auth` | Usuarios |
| `cloud_firestore` | Base de datos |
| `http` | Llamadas a Georef, DolarAPI, EmailJS, Cloudinary y la Cloud Function |
| `provider` | Estado compartido (sesión, carrito, catálogo, cotización) |
| `google_fonts` | Tipografías deportivas (Barlow Condensed e Inter) |
| `image_picker` | Elegir fotos para subir desde el panel admin |
| `url_launcher` | Abrir el checkout de Mercado Pago y el mail de contacto |

## Paso 3 — Firebase (YA CONFIGURADO)

Proyecto: **PROKICKS** · ID `prokicks-df2b8` · plan Spark (gratis). Lo que ya está hecho en la consola:

| Qué | Dónde | Configuración |
|---|---|---|
| Cloud Firestore | Firestore Database | Edición Standard, `(default)`, ubicación `southamerica-east1 (São Paulo)`, modo producción |
| Reglas de seguridad | Firestore Database → Reglas | Contenido de `firestore.rules`, publicadas |
| Inicio de sesión | Authentication → Método de acceso | Correo electrónico/contraseña habilitado |
| Registro de usuarios | Authentication → Configuración → Acciones del usuario | "Habilitar la creación (registro)" activado |
| App web | Configuración del proyecto → Tus apps | "PROKICKS Web" registrada |
| Conexión app ↔ Firebase | `lib/firebase_options.dart` (incluido en el zip) | Datos de la app web "PROKICKS Web" |

`lib/firebase_options.dart` es el archivo que normalmente genera `flutterfire configure`. Ya viene
completo, así que **no hace falta correr ese comando**. (Si algún día lo corren, va a regenerar el
mismo archivo para el mismo proyecto.)

Solo para el **paso 9** (Mercado Pago real) necesitan la Firebase CLI:

```bash
npm install -g firebase-tools
firebase login
```

El archivo `.firebaserc` del zip ya apunta al proyecto `prokicks-df2b8`.

## Paso 4 — Copiar el código

Copiar la carpeta `lib/` del zip dentro de `prokicks/`, reemplazando la que creó Flutter
(incluye `main.dart` y `firebase_options.dart`). Copiar también `firestore.rules`, `.firebaserc`
y la carpeta `functions/` a la raíz de `prokicks/`.

## Paso 5 — Primera ejecución y usuario administrador

```bash
flutter run -d chrome
```

1. Arriba a la derecha, ícono de persona → **Ingresar o registrarme** → **Registrate**.
2. En la consola de Firebase: **Firestore → usuarios → (su documento) → campo `rol`** → cambiar
   `cliente` por `admin`. *(Las reglas no dejan que nadie se haga admin desde la app: el primero
   se nombra a mano. Desde el panel, un admin puede nombrar a otros.)*
3. En la app aparece el ícono del panel. Entrar → **Resumen → CARGAR DATOS DE EJEMPLO**
   (20 botines de 5 marcas y 5 superficies, más 3 cupones: `BIENVENIDA10`, `PROKICKS15K`, `FINDE20`).

## Paso 6 — EmailJS (mail de confirmación)

1. Cuenta en <https://www.emailjs.com>.
2. **Email Services → Add New Service → Gmail** → anotar **Service ID**.
3. **Email Templates → Create New Template**:
   - **To Email:** `{{to_email}}`
   - **Subject:** `PROKICKS · Pedido {{order_id}} confirmado`
   - **Content:**
     ```
     ¡Hola {{to_name}}! Tu pago fue aprobado.

     Pedido: {{order_id}}

     {{order_detail}}

     Entrega: {{order_delivery}}
     Total: {{order_total}}
     ```
   - Anotar el **Template ID**.
4. **Account → General** → **Public Key**.
5. Pegar los tres valores en `lib/config/api_config.dart`.

## Paso 7 — Cloudinary (fotos de productos)

1. Cuenta en <https://cloudinary.com>. En el Dashboard está el **Cloud name**.
2. **Settings → Upload → Upload presets → Add upload preset**:
   - **Signing mode: Unsigned** (así la app no necesita el API Secret).
   - Folder: `prokicks` → guardar y anotar el **nombre del preset**.
3. Pegar Cloud name y preset en `lib/config/api_config.dart`.
4. Panel admin → Productos → editar un botín → **SUBIR FOTO (CLOUDINARY)**.

Sin Cloudinary, se pueden agregar fotos con **Agregar por URL**, o dejar el dibujo automático.

## Paso 8 — Probar la tienda completa

1. Home: banner, destacados, superficies, lanzamientos, ofertas, marcas, footer.
2. Catálogo: buscar escribiendo (filtra en tiempo real), filtrar por marca, precio, talle y superficie, ordenar.
3. Producto: elegir talle (los agotados aparecen tachados), cantidad, favorito, agregar al carrito.
4. Carrito: cambiar cantidades, eliminar, aplicar `BIENVENIDA10`.
5. Checkout: provincia y localidad (vienen de Georef), costo de envío, **PAGAR CON MERCADO PAGO**.
6. Modo prueba: elegir *Pago aprobado* → llega el mail → **Mis pedidos**.
7. Repetir con *Pago rechazado* y *Pago pendiente*; cancelar un pedido y ver que el stock vuelve.
8. Panel admin: cambiar estados de pedidos, crear un cupón, crear/editar un producto, ver los gráficos.

## Paso 9 (opcional) — Mercado Pago real

Requiere el **plan Blaze** de Firebase (pago por uso, con cuota gratis; pide tarjeta) porque usa Cloud Functions.

1. Cuenta en <https://www.mercadopago.com.ar/developers> → **Tus integraciones → Crear aplicación** (Checkout Pro).
2. En la aplicación → **Credenciales de prueba** → copiar el **Access Token** de prueba.
3. En la carpeta del proyecto:
   ```bash
   firebase init functions        # elegir el proyecto, JavaScript y sin ESLint
   ```
   Reemplazar `functions/index.js` y `functions/package.json` por los del zip, y después:
   ```bash
   cd functions
   npm install firebase-functions@latest firebase-admin@latest
   cd ..
   firebase functions:secrets:set MP_ACCESS_TOKEN     # pegar el Access Token cuando lo pida
   firebase deploy --only functions
   ```
4. El deploy muestra la URL de `crearPreferencia`. Pegarla en `ApiConfig.mpCrearPreferenciaUrl`.
5. Probar con los usuarios y tarjetas de prueba que indica la documentación de Mercado Pago.

El Access Token **nunca** está en la app: queda como secreto en Firebase y solo lo usa la función.

---

## Capturas de Firebase para la entrega

1. **Authentication → Users** con los usuarios registrados.
2. **Firestore → `productos`** → un botín abierto con el mapa `talles` (stock por talle) y `ventas`.
3. **Firestore → `usuarios`** → un documento con `rol`, `favoritos`, `carrito` y `direccion`.
4. **Firestore → `pedidos`** → un pedido abierto con `items`, `envio`, `pago` (estado y modo), `estado`, `total`, `cotizacionDolar`.
5. **Firestore → `cupones`** → un cupón con `usos` > 0 (prueba de que la transacción lo contó).
6. **Firestore → Reglas** publicadas.
7. Extra: el mail recibido, el panel Email History de EmailJS y la Media Library de Cloudinary.

---

## Arquitectura

```
lib/
├── main.dart                 Inicializa Firebase y los providers
├── config/
│   ├── api_config.dart       URLs y claves PÚBLICAS de las APIs
│   └── tema.dart             Colores, tipografías y estilos
├── models/                   JSON / documentos de Firestore → objetos Dart
│   ├── producto.dart  item_carrito.dart  pedido.dart  cupon.dart
│   ├── usuario.dart   envio.dart  cotizacion.dart  catalogo.dart
│   └── filtros.dart          Búsqueda, filtros y orden del catálogo
├── data/datos_ejemplo.dart   Seed: 20 botines y 3 cupones
├── services/                 Todo lo que habla con el exterior
│   ├── auth_service.dart  usuarios_service.dart  productos_service.dart
│   ├── pedidos_service.dart   (transacción de stock)  cupones_service.dart
│   ├── georef_service.dart  dolar_service.dart  email_service.dart
│   ├── cloudinary_service.dart  pago_service.dart  envio_service.dart
│   └── notificaciones_service.dart
├── providers/                Estado compartido: sesión, carrito, cotización
├── screens/                  Home, catálogo, producto, carrito, checkout, pago,
│   │                         pedidos, favoritos, perfil, login
│   └── admin/                Resumen, productos, pedidos, cupones, usuarios
├── widgets/                  Barra, tarjetas, gráficos, footer, dibujo del botín
└── utils/                    Formato de precios/fechas y navegación
functions/                    Cloud Functions de Mercado Pago (Node.js)
```

### Los endpoints del prompt, resueltos con Firebase

En vez de un backend Node + PostgreSQL propio, el "backend" es Firebase: Firestore es la base
de datos y las **reglas de seguridad** son la capa que protege los "endpoints". Las únicas
operaciones que necesitan un servidor de verdad (las que usan claves privadas) están en Cloud Functions.

| Endpoint pedido | Cómo se hace acá |
|---|---|
| `GET /api/products`, `/:id` | `ProductosService.productos()` (stream en tiempo real) |
| `POST/PUT/DELETE /api/products` | `ProductosService.crear/actualizar/eliminar` (solo admin, por reglas) |
| `POST /api/auth/register`, `/login` | `AuthService.registrar/iniciarSesion` (Firebase Auth) |
| `GET /api/users/me` | `UsuariosService.streamPerfil(uid)` |
| `GET/POST/PUT/DELETE /api/cart` | `CarritoProvider` + `UsuariosService.guardarCarrito` |
| `POST /api/orders` | `PedidosService.crearPedido` (transacción: valida y descuenta stock) |
| `GET /api/orders`, `/:id` | `PedidosService.pedidosDe(uid)` y `pedido(id)` |
| `POST /api/coupons/validate` | `CuponesService.validar` (y se revalida dentro de la transacción) |
| Checkout Mercado Pago | Cloud Function `crearPreferencia` + `webhookMercadoPago` |

### Modelo de datos (Firestore)

```
productos/{id}   nombre, marca, superficie, sku, precio, precioAnterior, descripcion,
                 colores[], imagenes[], talles{"40": 5, ...}, nuevo, destacado, oferta,
                 activo, ventas, creadoEn
usuarios/{uid}   nombre, email, rol, telefono, direccion{...}, favoritos[], carrito[], creadoEn
pedidos/{id}     uid, email, nombre, telefono, items[], subtotal, descuento, cuponCodigo,
                 envio{metodo, costo, demora}, direccion{...}, total, cotizacionDolar, totalUsd,
                 estado, pago{metodo, modo, estado, referencia}, emailEnviado, creadoEn
cupones/{CODIGO} tipo, valor, minimo, activo, vence, usos, usosMax
```

En una base relacional (PostgreSQL) esto serían tablas separadas (ProductVariants, OrderItems,
CartItems…). En Firestore se **embeben**: el stock por talle vive dentro del producto y los ítems
dentro del pedido, porque siempre se leen juntos.

### Seguridad

- Las claves de `api_config.dart` son públicas por diseño (EmailJS Public Key, Cloudinary preset sin firma).
- El Access Token de Mercado Pago es privado: solo existe como secreto de la Cloud Function.
- Reglas de Firestore: catálogo público para leer; productos y cupones solo los edita un admin;
  cada usuario ve solo lo suyo; nadie se asigna el rol admin.
- El precio de cada ítem y el stock se leen de Firestore **dentro de la transacción**:
  no se confía en lo que manda el navegador.
- Limitación conocida: en modo prueba el propio navegador registra el resultado del pago, y las
  reglas permiten a un cliente modificar stock/ventas (lo necesita la transacción). En producción
  estas dos cosas se moverían a Cloud Functions (como ya hace el webhook de Mercado Pago real).

---

## Problemas comunes

| Error | Solución |
|---|---|
| `Target of URI doesn't exist: 'firebase_options.dart'` | Falta copiar `lib/firebase_options.dart` del zip (paso 4). |
| `permission-denied` / `Missing or insufficient permissions` | Las reglas tardan hasta un minuto en aplicarse después de publicarlas. Para el panel admin, el usuario tiene que tener `rol: admin`. |
| Registrarse dice "El ingreso con email no está activado" | Revisar Authentication → Método de acceso → Correo electrónico/contraseña (paso 3). |
| No aparece el ícono del panel admin | Cambiar el `rol` a `admin` en Firestore (paso 5) y recargar. En celular, el acceso está en **Mi cuenta**. |
| `No named parameter with the name 'webHtmlElementStrategy'` | Flutter viejo: `flutter upgrade`, o borrar esa línea en `widgets/botin_imagen.dart`. |
| La provincia se carga pero la localidad no sugiere nada | Georef puede tardar. Se puede escribir la localidad a mano igual. |
| Pago aprobado pero no llega el mail | Revisar los 3 valores de EmailJS y que **To Email** sea `{{to_email}}`. Ver la consola de Chrome (F12). |
| Error al subir foto | Revisar Cloud name, que el preset sea **Unsigned** y su nombre exacto. |
| `crearPreferencia` responde 401/403 | Hay que estar logueado y el pedido tiene que ser del usuario. |
| Mercado Pago no vuelve solo a la tienda | `auto_return` solo funciona con https: publicar la app en Firebase Hosting (`flutter build web` + `firebase deploy --only hosting`). |

---

## Entrega del código

- **Zip:** comprimir `prokicks/` **sin** `build/`, `.dart_tool/` ni `functions/node_modules/`.
- **GitHub:**
  ```bash
  git init && git add . && git commit -m "PROKICKS: e-commerce de botines en Flutter + Firebase"
  git branch -M main
  git remote add origin https://github.com/USUARIO/prokicks.git
  git push -u origin main
  ```
