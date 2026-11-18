'use strict';

// Server-only Stripe integration. Never expose Stripe secret keys in Flutter.
const { onCall, HttpsError, onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const Stripe = require('stripe');

admin.initializeApp();
const db = admin.firestore();
const stripeKey = defineSecret('STRIPE_SECRET_KEY');
const webhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');
const PRICE_ID = 'price_1UcxxEBo8z3y7mFz8xWCycSi';
const SITE = 'https://askthevillage.app';
const stripe = () => new Stripe(stripeKey.value());

exports.createVillagePlusCheckout = onCall(
  { secrets: [stripeKey], enforceAppCheck: true },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
    const uid = request.auth.uid;
    const ref = db.collection('stripeCustomers').doc(uid);
    let customerId = (await ref.get()).data()?.customerId;
    const api = stripe();
    if (!customerId) {
      const customer = await api.customers.create({
        email: request.auth.token.email || undefined,
        metadata: { firebaseUid: uid },
      }, { idempotencyKey: 'village-customer-' + uid });
      customerId = customer.id;
      await ref.set({ customerId }, { merge: true });
    }
    const session = await api.checkout.sessions.create({
      mode: 'subscription',
      customer: customerId,
      client_reference_id: uid,
      line_items: [{ price: PRICE_ID, quantity: 1 }],
      subscription_data: { metadata: { firebaseUid: uid } },
      success_url: SITE + '/?billing=success',
      cancel_url: SITE + '/?billing=cancelled',
      allow_promotion_codes: false,
    });
    return { url: session.url };
  }
);

exports.createVillagePlusPortal = onCall(
  { secrets: [stripeKey], enforceAppCheck: true },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
    const customerId = (await db.collection('stripeCustomers').doc(request.auth.uid).get()).data()?.customerId;
    if (!customerId) throw new HttpsError('failed-precondition', 'No billing account found.');
    const session = await stripe().billingPortal.sessions.create({
      customer: customerId, return_url: SITE,
    });
    return { url: session.url };
  }
);

async function syncSubscription(subscription) {
  const uid = subscription.metadata?.firebaseUid;
  if (!uid) {
    console.error('Subscription missing firebaseUid', subscription.id);
    return;
  }
  const active = ['active', 'trialing'].includes(subscription.status);
  await db.collection('villagePlusEntitlements').doc(uid).set({
    active,
    status: subscription.status,
    stripeSubscriptionId: subscription.id,
    stripeCustomerId: subscription.customer,
    currentPeriodEnd: subscription.items?.data?.[0]?.current_period_end || null,
    cancelAtPeriodEnd: !!subscription.cancel_at_period_end,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

exports.villagePlusStripeWebhook = onRequest(
  { secrets: [stripeKey, webhookSecret], cors: false },
  async (req, res) => {
    if (req.method !== 'POST') { res.status(405).send('Method not allowed'); return; }
    let event;
    try {
      event = stripe().webhooks.constructEvent(
        req.rawBody, req.headers['stripe-signature'], webhookSecret.value());
    } catch (err) { res.status(400).send('Invalid signature'); return; }
    try {
      if (event.type === 'checkout.session.completed') {
        const session = event.data.object;
        if (session.mode === 'subscription' && session.subscription) {
          const sub = await stripe().subscriptions.retrieve(session.subscription);
          await syncSubscription(sub);
        }
      } else if ([
        'customer.subscription.created',
        'customer.subscription.updated',
        'customer.subscription.deleted',
      ].includes(event.type)) {
        await syncSubscription(event.data.object);
      }
      res.status(200).send('ok');
    } catch (err) {
      console.error('Stripe webhook processing failed', err);
      res.status(500).send('Retry');
    }
  }
);
