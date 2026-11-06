const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, updateDoc, deleteDoc, runTransaction, serverTimestamp, getDocFromServer, collection, getDocs} = require('firebase/firestore');

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

    // Two devices signed into the same profile share the same bookmarks.
    const alicePhone = env.authenticatedContext('alice').firestore();
    const guest = env.unauthenticatedContext().firestore();
    const bookmarkPath = 'users/alice/saved_resources/fl-wic';
    await assertSucceeds(setDoc(doc(alice, bookmarkPath),
      {resourceId: 'fl-wic', savedAt: serverTimestamp()}));
    const fromPhone = await assertSucceeds(getDocFromServer(doc(alicePhone, bookmarkPath)));
    if (!fromPhone.exists()) throw Error('Same-profile second device cannot see saved resource');
    const phoneList = await assertSucceeds(getDocs(collection(alicePhone, 'users/alice/saved_resources')));
    if (phoneList.size !== 1) throw Error('Saved-resource library did not sync across devices');
    await assertFails(getDoc(doc(bob, bookmarkPath)));
    await assertFails(getDocs(collection(bob, 'users/alice/saved_resources')));
    await assertFails(getDoc(doc(guest, bookmarkPath)));
    await assertFails(setDoc(doc(bob, bookmarkPath),
      {resourceId: 'fl-wic', savedAt: serverTimestamp()}));
    await assertFails(setDoc(doc(alice, bookmarkPath),
      {resourceId: 'wrong-id', savedAt: serverTimestamp()}));
    await assertFails(setDoc(doc(alice, bookmarkPath),
      {resourceId: 'fl-wic', savedAt: serverTimestamp(), public: true}));
    await assertFails(setDoc(doc(alice, bookmarkPath),
      {resourceId: 'fl-wic', savedAt: new Date(0)}));
    await assertFails(deleteDoc(doc(bob, bookmarkPath)));
    await assertSucceeds(deleteDoc(doc(alicePhone, bookmarkPath)));
    if ((await getDocFromServer(doc(alice, bookmarkPath))).exists())
      throw Error('Removing a saved resource on a second device did not sync');
    console.log('Resource bookmarks: cross-device reads/removal, private listing, ownership, schema and timestamps passed.');

    console.log('Support rules: duplicate/concurrent support, distinct users, count tampering, receipt privacy, immutable receipts, and replies passed.');
  } finally {
    await env.cleanup();
  }
})().catch(e => {console.error(e); process.exit(1);});
