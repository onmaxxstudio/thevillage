const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, getDoc, setDoc, updateDoc, deleteDoc, collection, getDocs, Timestamp, serverTimestamp} = require('firebase/firestore');

(async () => {
  const env = await initializeTestEnvironment({projectId:'demo-village',firestore:{rules:readFileSync('app/firestore.rules','utf8')}});
  try {
    const future = Timestamp.fromDate(new Date(Date.now()+86400000));
    const past = Timestamp.fromDate(new Date(Date.now()-86400000));
    await env.withSecurityRulesDisabled(async c => {
      const db = c.firestore();
      await setDoc(doc(db,'admins/owner'),{active:true});
      await setDoc(doc(db,'admin_events/draft'),{kind:'monthly_gathering',title:'Draft',published:false,status:'draft',access:'plus'});
      await setDoc(doc(db,'admin_events/gathering'),{kind:'monthly_gathering',title:'Letting Go & Starting Fresh',published:true,status:'scheduled',access:'plus',startsAt:future});
      await setDoc(doc(db,'admin_events/gathering/private/details'),{meetingUrl:'https://meeting.invalid/private',recordingPath:'monthly_recordings/gathering/a.mp4'});
      await setDoc(doc(db,'village_plus_memberships/paid'),{villagePlus:true,status:'active',currentPeriodEnd:future});
      await setDoc(doc(db,'village_plus_memberships/expired'),{villagePlus:true,status:'active',currentPeriodEnd:past});
      await setDoc(doc(db,'village_plus_memberships/canceled'),{villagePlus:false,status:'canceled',currentPeriodEnd:future});
    });
    const owner=env.authenticatedContext('owner').firestore();
    const paid=env.authenticatedContext('paid').firestore();
    const free=env.authenticatedContext('free').firestore();
    const expired=env.authenticatedContext('expired').firestore();
    const canceled=env.authenticatedContext('canceled').firestore();
    const eventPath='admin_events/gathering';
    const privatePath=eventPath+'/private/details';
    const reg=(db,uid)=>doc(db,eventPath+'/registrations/'+uid);
    await assertFails(getDoc(doc(free,'admin_events/draft')));
    await assertSucceeds(getDoc(doc(owner,'admin_events/draft')));
    for (const db of [free,paid,expired,canceled]) await assertSucceeds(getDoc(doc(db,eventPath)));
    for (const db of [free,paid,expired,canceled]) await assertFails(getDoc(doc(db,privatePath)));
    await assertFails(setDoc(reg(free,'free'),{uid:'free',createdAt:serverTimestamp()}));
    await assertFails(setDoc(reg(expired,'expired'),{uid:'expired',createdAt:serverTimestamp()}));
    await assertFails(setDoc(reg(canceled,'canceled'),{uid:'canceled',createdAt:serverTimestamp()}));
    await assertFails(setDoc(reg(paid,'free'),{uid:'free',createdAt:serverTimestamp()}));
    await assertSucceeds(setDoc(reg(paid,'paid'),{uid:'paid',createdAt:serverTimestamp()}));
    await assertFails(setDoc(reg(paid,'paid'),{uid:'paid',createdAt:serverTimestamp()}));
    await assertSucceeds(getDoc(doc(paid,privatePath)));
    await env.withSecurityRulesDisabled(async c=>setDoc(doc(c.firestore(),'village_plus_memberships/paid'),{status:'canceled',villagePlus:false},{merge:true}));
    await assertFails(getDoc(doc(paid,privatePath)));
    await env.withSecurityRulesDisabled(async c=>setDoc(doc(c.firestore(),'village_plus_memberships/paid'),{status:'active',villagePlus:true},{merge:true}));
    await assertFails(getDocs(collection(paid,eventPath+'/registrations')));
    await assertSucceeds(getDocs(collection(owner,eventPath+'/registrations')));
    await assertFails(updateDoc(reg(paid,'paid'),{joinedAt:serverTimestamp()}));
    await env.withSecurityRulesDisabled(async c=>setDoc(doc(c.firestore(),eventPath),{startsAt:Timestamp.fromDate(new Date(Date.now()-300000))},{merge:true}));
    await assertSucceeds(updateDoc(reg(paid,'paid'),{joinedAt:serverTimestamp()}));
    await assertFails(updateDoc(reg(free,'paid'),{joinedAt:serverTimestamp()}));
    await assertSucceeds(deleteDoc(reg(paid,'paid')));
    await assertFails(getDoc(doc(paid,privatePath)));
    await env.withSecurityRulesDisabled(async c=>setDoc(doc(c.firestore(),'admin_events/gathering'),{access:'free'},{merge:true}));
    await env.withSecurityRulesDisabled(async c=>setDoc(doc(c.firestore(),eventPath),{startsAt:future},{merge:true}));
    await assertSucceeds(setDoc(reg(free,'free'),{uid:'free',createdAt:serverTimestamp()}));
    await assertSucceeds(getDoc(doc(free,privatePath)));
    await env.withSecurityRulesDisabled(async c=>setDoc(doc(c.firestore(),'admin_events/gathering'),{status:'canceled'},{merge:true}));
    await assertFails(setDoc(reg(paid,'paid'),{uid:'paid',createdAt:serverTimestamp()}));
    console.log('Monthly Gathering registration and entitlement rules passed');
  } finally { await env.cleanup(); }
})().catch(e=>{console.error(e);process.exitCode=1});
