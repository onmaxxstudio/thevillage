const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, updateDoc, deleteDoc, runTransaction, serverTimestamp, getDocFromServer} = require('firebase/firestore');

(async () => {
  const env = await initializeTestEnvironment({
    projectId: 'demo-village',
    firestore: {rules: readFileSync('app/firestore.rules', 'utf8')},
  });
  try {
    await env.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), 'village_posts/post'), {
        author: 'QuietWillow', supportCount: 0, replies: [],
      });
    });
    const alice = env.authenticatedContext('alice').firestore();
    const bob = env.authenticatedContext('bob').firestore();
    const support = db => runTransaction(db, async tx => {
      const post = doc(db, 'village_posts/post');
      const uid = db === alice ? 'alice' : 'bob';
      const vote = doc(db, 'users/' + uid + '/village_support/post');
      const p = await tx.get(post);
      const v = await tx.get(vote);
      if (v.exists()) return;
      tx.set(vote, {createdAt: serverTimestamp()});
      tx.update(post, {supportCount: p.data().supportCount + 1});
    }).catch(async error => {
      const uid = db === alice ? 'alice' : 'bob';
      const receipt = await getDocFromServer(doc(db, 'users/' + uid + '/village_support/post'));
      if (!receipt.exists()) throw error;
    });
    await assertFails(updateDoc(doc(alice, 'village_posts/post'), {supportCount: 1}));
    await assertFails(setDoc(doc(alice, 'users/alice/village_support/post'), {createdAt: serverTimestamp()}));
    await assertSucceeds(Promise.all([support(alice), support(alice)]));
    if ((await getDoc(doc(alice, 'village_posts/post'))).data().supportCount !== 1) throw Error('Duplicate support counted');
    await assertSucceeds(support(alice));
    await assertSucceeds(support(bob));
    if ((await getDoc(doc(bob, 'village_posts/post'))).data().supportCount !== 2) throw Error('Distinct profiles not counted');
    await assertFails(deleteDoc(doc(alice, 'users/alice/village_support/post')));
    await assertFails(getDoc(doc(bob, 'users/alice/village_support/post')));
    await assertFails(setDoc(doc(bob, 'users/alice/village_support/other'), {createdAt: serverTimestamp()}));
    await assertFails(updateDoc(doc(alice, 'village_posts/post'), {supportCount: 99, replies: []}));
    await assertSucceeds(updateDoc(doc(alice, 'village_posts/post'), {replies: [{text: 'Thank you'}]}));
    await assertSucceeds(updateDoc(doc(alice, 'village_posts/post'), {
      replies: [{id: 'reply', text: 'Thanks', supportCount: 0}],
    }));
    const replySupport = (db, token) => runTransaction(db, async tx => {
      const ref = doc(db, 'village_posts/post');
      const snapshot = await tx.get(ref);
      const replies = snapshot.data().replies;
      const reply = replies[0];
      const tokens = reply.supportTokens || [];
      if (tokens.includes(token)) return;
      reply.supportTokens = [...tokens, token];
      reply.supportCount += 1;
      tx.update(ref, {replies});
    });
    await assertSucceeds(Promise.all([replySupport(alice, 'alice-token'), replySupport(alice, 'alice-token')]));
    await assertSucceeds(replySupport(alice, 'alice-token'));
    let reply = (await getDocFromServer(doc(alice, 'village_posts/post'))).data().replies[0];
    if (reply.supportCount !== 1 || reply.supportTokens.length !== 1) throw Error('Repeated comment support counted');
    await assertSucceeds(replySupport(bob, 'bob-token'));
    reply = (await getDocFromServer(doc(bob, 'village_posts/post'))).data().replies[0];
    if (reply.supportCount !== 2 || reply.supportTokens.length !== 2) throw Error('Distinct comment supporters lost');
    console.log('Support rules: duplicate/concurrent support, distinct users, count tampering, receipt privacy, immutable receipts, and replies passed.');
  } finally {
    await env.cleanup();
  }
})().catch(e => {console.error(e); process.exit(1);});
