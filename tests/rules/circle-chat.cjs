const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDocFromServer, collection, getDocs, writeBatch, serverTimestamp, updateDoc, onSnapshot} = require('firebase/firestore');
(async () => {
  const env = await initializeTestEnvironment({projectId: 'demo-village',
    firestore: {rules: readFileSync('app/firestore.rules', 'utf8')}});
  try {
    await env.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), 'circles/chat-alice/members/chat-bob'), {username:'bob'});
      await setDoc(doc(ctx.firestore(), 'circles/chat-bob/members/chat-alice'), {username:'alice'});
    });
    const alice = env.authenticatedContext('chat-alice').firestore();
    const bob = env.authenticatedContext('chat-bob').firestore();
    const outsider = env.authenticatedContext('chat-outsider').firestore();
    const guest = env.unauthenticatedContext().firestore();
    const path = 'conversations/chat-alice_chat-bob';
    const send = (db, senderUid, recipientUid, id, text) => {
      const batch = writeBatch(db);
      batch.set(doc(db, path), {members:['chat-alice','chat-bob'], updatedAt:serverTimestamp()}, {merge:true});
      batch.set(doc(db, path+'/messages/'+id), {senderUid,recipientUid,text,createdAt:serverTimestamp(),readAt:null});
      return batch.commit();
    };
    // A brand-new conversation and its first message must commit atomically.
    await assertSucceeds(send(alice,'chat-alice','chat-bob','first','Hello Bob'));
    const received = new Promise((resolve,reject) => {
      const timer = setTimeout(() => {stop(); reject(Error('Realtime update timed out'));},10000);
      const stop = onSnapshot(collection(alice,path+'/messages'), snap => {
        if(snap.docs.some(d => d.id === 'reply')) {clearTimeout(timer);stop();resolve();}
      },reject);
    });
    await assertSucceeds(send(bob,'chat-bob','chat-alice','reply','Hello Alice'));
    await received;
    await assertSucceeds(updateDoc(doc(bob,path+'/messages/first'),{readAt:serverTimestamp()}));
    await assertFails(updateDoc(doc(alice,path+'/messages/first'),{readAt:serverTimestamp()}));
    await assertFails(send(alice,'chat-alice','chat-bob','first','Duplicate retry'));
    await assertFails(setDoc(doc(outsider,path+'/messages/injected'), {
      senderUid:'chat-outsider',recipientUid:'chat-bob',text:'Intrusion',createdAt:serverTimestamp(),readAt:null}));
    await assertFails(send(alice,'chat-bob','chat-alice','spoof','Spoof'));
    await assertFails(send(alice,'chat-alice','chat-alice','self','Self'));
    await assertFails(send(alice,'chat-alice','chat-bob','empty',''));
    await assertFails(send(alice,'chat-alice','chat-bob','long','x'.repeat(1001)));
    await assertFails(getDocs(collection(outsider,path+'/messages')));
    await assertFails(getDocs(collection(guest,path+'/messages')));
    await assertFails(updateDoc(doc(alice,path),{members:['chat-alice','chat-outsider']}));
    // A separate authenticated client sees durable history and read receipts.
    const bobAgain = env.authenticatedContext('chat-bob').firestore();
    const history = await assertSucceeds(getDocs(collection(bobAgain,path+'/messages')));
    if(history.size !== 2) throw Error('History lost or duplicate persisted');
    if(!(await getDocFromServer(doc(bobAgain,path+'/messages/first'))).data().readAt) throw Error('Read receipt lost');
    console.log('Circle chat: atomic first send, two-member realtime exchange, history, read receipts, duplicate rejection and access isolation passed.');
  } finally {await env.cleanup();}
})().catch(e => {console.error(e);process.exit(1);});
