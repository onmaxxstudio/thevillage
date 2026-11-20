const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, getDocs, collection, serverTimestamp} = require('firebase/firestore');

(async () => {
  const env = await initializeTestEnvironment({projectId: 'demo-village', firestore: {rules: readFileSync('app/firestore.rules', 'utf8')}});
  try {
    const member = env.authenticatedContext('member', {villagePlus: true}).firestore();
    const other = env.authenticatedContext('other', {villagePlus: true}).firestore();
    const free = env.authenticatedContext('free').firestore();
    const path = 'users/member/monthlyChallenges/2026-11/days/01';
    const valid = {journal: 'My private thought', completed: true, updatedAt: serverTimestamp()};
    await assertSucceeds(setDoc(doc(member, path), valid));
    const saved = await assertSucceeds(getDoc(doc(member, path)));
    if (saved.data().journal !== valid.journal) throw Error('Journal did not persist');
    await assertSucceeds(getDocs(collection(member, 'users/member/monthlyChallenges/2026-11/days')));
    await assertFails(getDoc(doc(other, path)));
    await assertFails(setDoc(doc(other, path), valid));
    await assertFails(getDoc(doc(free, path)));
    await assertFails(setDoc(doc(free, 'users/free/monthlyChallenges/2026-11/days/01'), valid));
    await assertFails(setDoc(doc(member, path), {...valid, journal: 'x'.repeat(20001)}));
    await assertFails(setDoc(doc(member, path), {...valid, public: true}));
    await assertFails(setDoc(doc(member, 'users/member/monthlyChallenges/2026-11/days/31'), valid));
    await assertFails(setDoc(doc(member, 'users/member/monthlyChallenges/2026-12/days/01'), valid));
    console.log('Monthly Challenge privacy and validation passed');
  } finally { await env.cleanup(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
