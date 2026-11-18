'use strict';
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');
const admin = require('firebase-admin');
const Stripe = require('stripe');
admin.initializeApp();
const db = admin.firestore();
const stripeSecret = defineSecret('STRIPE_SECRET_KEY');
const webhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');
const priceId = defineString('VILLAGE_PLUS_PRICE_ID');
const siteUrl = 'https://askthevillage.app';
const stripeClient = () => new Stripe(stripeSecret.value());

exports.createVillagePlusCheckout = onCall({region:'us-east1',secrets:[stripeSecret],enforceAppCheck:false},async(request)=>{
  if(!request.auth) throw new HttpsError('unauthenticated','Sign in before subscribing.');
  const uid=request.auth.uid;
  const user=await admin.auth().getUser(uid);
  if(!user.email) throw new HttpsError('failed-precondition','An email address is required for billing.');
  const ref=db.collection('village_plus_memberships').doc(uid);
  const current=await ref.get();
  if(current.exists && ['active','trialing'].includes(current.get('status')))
    throw new HttpsError('already-exists','Membership is already active.');
  const stripe=stripeClient();
  let customerId=current.exists ? current.get('stripeCustomerId') : null;
  if(!customerId){
    const customer=await stripe.customers.create({email:user.email,metadata:{firebaseUid:uid}});
    customerId=customer.id;
    await ref.set({stripeCustomerId:customerId,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
  }
  const session=await stripe.checkout.sessions.create({
    mode:'subscription',customer:customerId,
    line_items:[{price:priceId.value(),quantity:1}],
    success_url:siteUrl+'/\u0023/village-plus?checkout=success',
    cancel_url:siteUrl+'/\u0023/village-plus?checkout=cancelled',
    client_reference_id:uid,
    subscription_data:{metadata:{firebaseUid:uid}},
    allow_promotion_codes:false,
  });
  return {url:session.url};
});

exports.createVillagePlusPortal = onCall({region:'us-east1',secrets:[stripeSecret]},async(request)=>{
  if(!request.auth) throw new HttpsError('unauthenticated','Sign in first.');
  const snap=await db.collection('village_plus_memberships').doc(request.auth.uid).get();
  const customerId=snap.get('stripeCustomerId');
  if(!customerId) throw new HttpsError('failed-precondition','No billing account found.');
  const portal=await stripeClient().billingPortal.sessions.create({customer:customerId,return_url:siteUrl});
  return {url:portal.url};
});

async function syncSubscription(subscription){
  const customerId=typeof subscription.customer==='string'?subscription.customer:subscription.customer.id;
  const matches=await db.collection('village_plus_memberships').where('stripeCustomerId','==',customerId).limit(1).get();
  if(matches.empty) throw new Error('Unknown Stripe customer; manual reconciliation required: '+customerId);
  const ref=matches.docs[0].ref;
  const uid=ref.id;
  const active=['active','trialing'].includes(subscription.status);
  const periodEnd=subscription.items?.data?.[0]?.current_period_end ?? subscription.current_period_end ?? null;
  // Custom claims are the authorization source for premium features.
  const user=await admin.auth().getUser(uid);
  await admin.auth().setCustomUserClaims(uid,{...user.customClaims,villagePlus:active});
  await ref.set({stripeCustomerId:customerId,stripeSubscriptionId:subscription.id,
    status:subscription.status,villagePlus:active,
    currentPeriodEnd:periodEnd ? admin.firestore.Timestamp.fromMillis(periodEnd*1000) : null,
    cancelAtPeriodEnd:!!subscription.cancel_at_period_end,
    updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
}

exports.stripeVillagePlusWebhook=onRequest({region:'us-east1',secrets:[stripeSecret,webhookSecret]},async(req,res)=>{
  let event;
  try {event=stripeClient().webhooks.constructEvent(req.rawBody,req.get('stripe-signature'),webhookSecret.value());}
  catch(e){res.status(400).send('Invalid signature');return;}
  const supported=['customer.subscription.created','customer.subscription.updated','customer.subscription.deleted'];
  if(!supported.includes(event.type)){res.status(200).send('Ignored');return;}
  const eventRef=db.collection('stripe_processed_events').doc(event.id);
  try{
    if((await eventRef.get()).exists){res.status(200).send('Already processed');return;}
    // Retrieve latest subscription state: out-of-order webhook events cannot revert access.
    const subscription=await stripeClient().subscriptions.retrieve(event.data.object.id);
    await syncSubscription(subscription);
    await eventRef.create({type:event.type,processedAt:admin.firestore.FieldValue.serverTimestamp()});
    res.status(200).send('OK');
  }catch(e){console.error('Stripe event processing failed',event.id,e);res.status(500).send('Retry later');}
});
