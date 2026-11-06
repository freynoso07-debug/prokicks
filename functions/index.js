/**
 * Cloud Functions de PROKICKS: integración REAL con Mercado Pago.
 *
 * Por qué existe esta carpeta:
 *   El Access Token de Mercado Pago es una clave PRIVADA. Si estuviera en la
 *   app (que corre en el navegador), cualquiera podría verla. Por eso vive
 *   acá, en el servidor, guardada como secreto de Firebase (MP_ACCESS_TOKEN).
 *
 * Funciones:
 *   1. crearPreferencia   → la app le manda el id del pedido; esta función lee
 *                           el pedido de Firestore, arma la preferencia de pago
 *                           y devuelve la URL del checkout de Mercado Pago.
 *   2. webhookMercadoPago → Mercado Pago avisa acá cuando cambia un pago; se
 *                           consulta el pago a la API y se actualiza el pedido.
 *
 * Requiere el plan Blaze de Firebase (ver README, paso 9).
 */

const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

const MP_ACCESS_TOKEN = defineSecret('MP_ACCESS_TOKEN');
const REGION = 'southamerica-east1';
const MP_API = 'https://api.mercadopago.com';

function urlWebhook() {
  const proyecto =
    process.env.GCLOUD_PROJECT || JSON.parse(process.env.FIREBASE_CONFIG || '{}').projectId;
  return `https://${REGION}-${proyecto}.cloudfunctions.net/webhookMercadoPago`;
}

// ---------------------------------------------------------------------------
// 1) Crear la preferencia de pago
// ---------------------------------------------------------------------------
exports.crearPreferencia = onRequest(
  { region: REGION, secrets: [MP_ACCESS_TOKEN], cors: true },
  async (req, res) => {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Método no permitido' });
    }

    try {
      // Seguridad: solo usuarios logueados (token de Firebase Auth).
      const cabecera = req.get('Authorization') || '';
      const idToken = cabecera.startsWith('Bearer ') ? cabecera.slice(7) : null;
      if (!idToken) return res.status(401).json({ error: 'Falta el token de sesión' });
      const usuario = await admin.auth().verifyIdToken(idToken);

      const { pedidoId, urlRetorno } = req.body || {};
      if (!pedidoId) return res.status(400).json({ error: 'Falta pedidoId' });

      const ref = db.collection('pedidos').doc(pedidoId);
      const snap = await ref.get();
      if (!snap.exists) return res.status(404).json({ error: 'El pedido no existe' });

      const pedido = snap.data();
      // Seguridad: solo el dueño del pedido puede pagarlo.
      if (pedido.uid !== usuario.uid) return res.status(403).json({ error: 'No es tu pedido' });
      if (pedido.estado !== 'pendiente_pago' || pedido.pago?.estado === 'aprobado') {
        return res.status(409).json({ error: 'Este pedido no espera pago' });
      }

      // El total sale de Firestore (calculado en la transacción), nunca del navegador.
      const preferencia = {
        items: [
          {
            id: pedidoId,
            title: `Pedido PROKICKS #${pedidoId.slice(0, 8).toUpperCase()}`,
            description: pedido.items.map((i) => `${i.cantidad}x ${i.nombre} T${i.talle}`).join(', '),
            quantity: 1,
            unit_price: Number(pedido.total),
            currency_id: 'ARS',
          },
        ],
        payer: { email: pedido.email },
        external_reference: pedidoId,
        notification_url: urlWebhook(),
        statement_descriptor: 'PROKICKS',
      };

      if (typeof urlRetorno === 'string' && urlRetorno.length > 0) {
        preferencia.back_urls = { success: urlRetorno, pending: urlRetorno, failure: urlRetorno };
        // Mercado Pago solo acepta auto_return con URLs https (no localhost).
        if (urlRetorno.startsWith('https://')) preferencia.auto_return = 'approved';
      }

      const respuesta = await fetch(`${MP_API}/checkout/preferences`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${MP_ACCESS_TOKEN.value()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(preferencia),
      });
      const datos = await respuesta.json();

      if (!respuesta.ok) {
        logger.error('Mercado Pago rechazó la preferencia', datos);
        return res.status(502).json({ error: 'Mercado Pago rechazó la preferencia', detalle: datos });
      }

      await ref.update({
        'pago.preferenciaId': datos.id,
        'pago.modo': 'real',
        actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.json({
        id: datos.id,
        init_point: datos.init_point,
        sandbox_init_point: datos.sandbox_init_point,
      });
    } catch (error) {
      logger.error('Error en crearPreferencia', error);
      return res.status(500).json({ error: 'Error interno' });
    }
  },
);

// ---------------------------------------------------------------------------
// 2) Webhook: Mercado Pago avisa que cambió un pago
// ---------------------------------------------------------------------------
exports.webhookMercadoPago = onRequest(
  { region: REGION, secrets: [MP_ACCESS_TOKEN] },
  async (req, res) => {
    try {
      const tipo = req.query.type || req.query.topic || req.body?.type;
      const pagoId = req.query['data.id'] || req.body?.data?.id || req.query.id;

      // Solo nos interesan las notificaciones de pagos.
      if (tipo !== 'payment' || !pagoId) return res.sendStatus(200);

      // Seguridad: no confiamos en lo que llega en la notificación. Consultamos
      // el pago a la API de Mercado Pago con nuestro token.
      const respuesta = await fetch(`${MP_API}/v1/payments/${pagoId}`, {
        headers: { Authorization: `Bearer ${MP_ACCESS_TOKEN.value()}` },
      });
      if (!respuesta.ok) {
        logger.error('No se pudo consultar el pago', pagoId, respuesta.status);
        return res.sendStatus(500); // Mercado Pago reintenta más tarde
      }
      const pago = await respuesta.json();
      const pedidoId = pago.external_reference;
      if (!pedidoId) return res.sendStatus(200);

      const estadoPago =
        pago.status === 'approved'
          ? 'aprobado'
          : pago.status === 'rejected' || pago.status === 'cancelled'
            ? 'rechazado'
            : 'pendiente';

      const cambios = {
        'pago.estado': estadoPago,
        'pago.referencia': String(pago.id),
        'pago.detalle': pago.status_detail || null,
        actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (estadoPago === 'aprobado') cambios.estado = 'pagado';

      await db.collection('pedidos').doc(pedidoId).update(cambios);
      logger.info(`Pedido ${pedidoId}: pago ${estadoPago}`);
      return res.sendStatus(200);
    } catch (error) {
      logger.error('Error en webhookMercadoPago', error);
      return res.sendStatus(500);
    }
  },
);
