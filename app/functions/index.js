'use strict';
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret, defineString } = require('firebase-functions/params');
const admin = require('firebase-admin');
const Stripe = require('stripe');
admin.initializeApp();
const db = admin.firestore();
const stripeSecret = defineSecret('STRIPE_SECRET_KEY');
const webhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');
const priceId = defineString('VILLAGE_PLUS_PRICE_ID');
const siteUrl = defineString('VILLAGE_PLUS_RETURN_URL');
const productionProject = 'the-village-d7af4';
const productionEnabled = defineString('VILLAGE_PLUS_PRODUCTION_ENABLED', {default:'false'});
function requirePaymentProject() {
  const project = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
  if (!project || (project === productionProject && productionEnabled.value() !== 'true'))
    throw new HttpsError('failed-precondition', 'Village Plus payments are not enabled for this project.');
  return project === productionProject;
}
function returnUrl() {
  const url = new URL(siteUrl.value());
  const production = requirePaymentProject();
  if (url.protocol !== 'https:' || (url.hostname === 'askthevillage.app') !== production)
    throw new HttpsError('failed-precondition', 'Configure the correct HTTPS return URL for this project.');
  return url.origin + url.pathname.replace(/\/$/, '');
}
const stripeClient = () => new Stripe(stripeSecret.value());

exports.createVillagePlusCheckout = onCall({region:'us-east1',secrets:[stripeSecret],enforceAppCheck:false},async(request)=>{
  const production=requirePaymentProject();
  if(!request.auth) throw new HttpsError('unauthenticated','Sign in before subscribing.');
  const uid=request.auth.uid;
  const user=await admin.auth().getUser(uid);
  if(!user.email) throw new HttpsError('failed-precondition','An email address is required for billing.');
  const ref=db.collection('village_plus_memberships').doc(uid);
  const current=await ref.get();
  if(current.exists && ['active','trialing'].includes(current.get('status')))
    throw new HttpsError('already-exists','Membership is already active.');
  const stripe=stripeClient();
  const price=await stripe.prices.retrieve(priceId.value());
  if(price.livemode !== production || (production && price.id !== 'price_1UcxxEBo8z3y7mFz8xWCycSi') ||
      !price.active || price.currency !== 'usd' || price.unit_amount !== 499 ||
      price.recurring?.interval !== 'month' || price.recurring?.interval_count !== 1)
    throw new HttpsError('failed-precondition','The configured price must be $4.99 per month in the correct mode.');
  let customerId=current.exists ? current.get('stripeCustomerId') : null;
  if(!customerId){
    const customer=await stripe.customers.create({email:user.email,metadata:{firebaseUid:uid}});
    customerId=customer.id;
    await ref.set({stripeCustomerId:customerId,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
  }
  const session=await stripe.checkout.sessions.create({
    mode:'subscription',customer:customerId,
    line_items:[{price:priceId.value(),quantity:1}],
    success_url:returnUrl()+'/#/village-plus?checkout=success',
    cancel_url:returnUrl()+'/#/village-plus?checkout=cancelled',
    client_reference_id:uid,
    subscription_data:{metadata:{firebaseUid:uid}},
    allow_promotion_codes:false,
  });
  return {url:session.url};
});

exports.createVillagePlusPortal = onCall({region:'us-east1',secrets:[stripeSecret]},async(request)=>{
  requirePaymentProject();
  if(!request.auth) throw new HttpsError('unauthenticated','Sign in first.');
  const snap=await db.collection('village_plus_memberships').doc(request.auth.uid).get();
  const customerId=snap.get('stripeCustomerId');
  if(!customerId) throw new HttpsError('failed-precondition','No billing account found.');
  const portal=await stripeClient().billingPortal.sessions.create({customer:customerId,return_url:returnUrl()});
  return {url:portal.url};
});

async function syncSubscription(subscription){
  if (subscription.livemode !== requirePaymentProject()) throw new Error('Subscription mode does not match project.');
  const matchingPrice=subscription.items?.data?.some(item=>item.price?.id===priceId.value());
  if(!matchingPrice) throw new Error('Subscription does not contain the configured Village Plus price.');
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
  try {requirePaymentProject();} catch(e) {res.status(503).send('Payments not enabled');return;}
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

// Idempotent inbox reminders. Private links never enter notifications.
async function sendGatheringReminder(eventId, event, label) {
  const registrations = db.collection('admin_events').doc(eventId).collection('registrations');
  let last;
  let delivered = 0;
  while (true) {
    let query = registrations.orderBy(admin.firestore.FieldPath.documentId()).limit(200);
    if (last) query = query.startAfter(last);
    const page = await query.get();
    if (page.empty) break;
    for (const registration of page.docs) {
      const ref = db.collection('notifications').doc(registration.id).collection('items').doc(`gathering_${eventId}_${label}`);
      try {
        await ref.create({recipientUid:registration.id,actorUid:'system',type:'event_reminder',
          title: label === 'canceled' ? 'Gathering canceled' : label === 'rescheduled' ? 'Gathering rescheduled' : 'The Monthly Gathering is coming up',
          message:`${event.title}: ${label === '24h' ? 'starts tomorrow' : label === '1h' ? 'starts in one hour' : label === 'canceled' ? 'has been canceled' : 'has a new date'}. Check the event page for details.`,
          destinationIndex:4,postId:'',isRead:false,createdAt:admin.firestore.FieldValue.serverTimestamp()});
        delivered++;
      } catch (error) { if (error.code !== 6 && error.code !== 'already-exists') throw error; }
    }
    last = page.docs[page.docs.length-1];
    if (page.size < 200) break;
  }
  return delivered;
}

exports.sendMonthlyGatheringReminder = onCall({region:'us-east1'},async(request)=>{
  if (!request.auth) throw new HttpsError('unauthenticated','Sign in first.');
  const adminDoc=await db.collection('admins').doc(request.auth.uid).get();
  if (adminDoc.get('active') !== true) throw new HttpsError('permission-denied','Admin access required.');
  const eventId=request.data?.eventId;
  const label=request.data?.label;
  if (typeof eventId !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(eventId) || !['24h','1h','canceled','rescheduled'].includes(label))
    throw new HttpsError('invalid-argument','Invalid reminder request.');
  const event=await db.collection('admin_events').doc(eventId).get();
  if (!event.exists || event.get('kind') !== 'monthly_gathering') throw new HttpsError('not-found','Gathering not found.');
  if (label !== 'canceled' && (!event.get('published') || event.get('status') !== 'scheduled'))
    throw new HttpsError('failed-precondition','Only scheduled gatherings can send reminders.');
  return {delivered:await sendGatheringReminder(eventId,event.data(),label)};
});

exports.scheduledMonthlyGatheringReminders = onSchedule({schedule:'every 15 minutes',timeZone:'America/New_York',region:'us-east1'},async()=>{
  const now=Date.now();
  const events=await db.collection('admin_events').where('published','==',true).get();
  for (const event of events.docs) {
    if (event.get('kind') !== 'monthly_gathering' || event.get('status') !== 'scheduled') continue;
    const start=event.get('startsAt')?.toMillis?.();
    if (!start) continue;
    for (const [label,hours] of [['24h',24],['1h',1]]) {
      const remaining=start-now;
      if (remaining>0 && remaining<=hours*3600000 && remaining>(hours*3600000-15*60000))
        await sendGatheringReminder(event.id,event.data(),label);
    }
  }
});

exports.getGatheringRecording = onCall({region:'us-east1'},async(request)=>{
  if (!request.auth) throw new HttpsError('unauthenticated','Sign in first.');
  const eventId=request.data?.eventId;
  if (typeof eventId !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(eventId))
    throw new HttpsError('invalid-argument','Invalid event.');
  const event=await db.collection('admin_events').doc(eventId).get();
  if (!event.exists || event.get('kind') !== 'monthly_gathering' || event.get('published') !== true || event.get('recordingAvailable') !== true)
    throw new HttpsError('not-found','Recording unavailable.');
  const registration=await event.ref.collection('registrations').doc(request.auth.uid).get();
  if (!registration.exists) throw new HttpsError('permission-denied','Reserve a spot first.');
  if (event.get('access') === 'plus') {
    const membership=await db.collection('village_plus_memberships').doc(request.auth.uid).get();
    const data=membership.data();
    if (!data || data.villagePlus !== true || !['active','trialing'].includes(data.status) ||
      !data.currentPeriodEnd || data.currentPeriodEnd.toMillis() <= Date.now())
      throw new HttpsError('permission-denied','An active Village Plus membership is required.');
  } else if (event.get('access') !== 'free') throw new HttpsError('permission-denied','Invalid event access.');
  const details=await event.ref.collection('private').doc('details').get();
  const path=details.get('recordingPath');
  if (typeof path !== 'string' || !path.startsWith(`monthly_recordings/${eventId}/`) || path.includes('..'))
    throw new HttpsError('not-found','Recording unavailable.');
  const [url]=await admin.storage().bucket().file(path).getSignedUrl({version:'v4',action:'read',expires:Date.now()+60000,
    responseDisposition:'attachment; filename="monthly-gathering.mp4"'});
  return {url};
});
