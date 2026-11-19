const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, getDocs, collection, serverTimestamp} = require('firebase/firestore');

(async () => {
  const env = await initializeTestEnvironment({
    projectId: 'demo-village',
    firestore: {rules: readFileSync('app/firestore.rules', 'utf8')},
  });
  try {
    const member = env.authenticatedContext('member', {villagePlus: true}).firestore();
    const secondDevice = env.authenticatedContext('member', {villagePlus: true}).firestore();
    const other = env.authenticatedContext('other', {villagePlus: true}).firestore();
    const free = env.authenticatedContext('free').firestore();
    const guest = env.unauthenticatedContext().firestore();
    const path = 'users/member/monthlyFocus/2026-11';
    const ref = doc(member, path);
    const entry = {topic: 'Building Boundaries', journal1: 'A private reflection', completedWeeks: [1], updatedAt: serverTimestamp()};
    await assertSucceeds(setDoc(ref, entry));
    const saved = await assertSucceeds(getDoc(doc(secondDevice, path)));
    if (saved.data().journal1 !== entry.journal1) throw Error('Journal did not persist across devices');
    await assertSucceeds(getDocs(collection(secondDevice, 'users/member/monthlyFocus')));
    await assertFails(getDoc(doc(other, path)));
    await assertFails(getDocs(collection(other, 'users/member/monthlyFocus')));
    await assertFails(setDoc(doc(other, path), entry));
    await assertFails(getDoc(doc(free, path)));
    await assertFails(setDoc(doc(free, 'users/free/monthlyFocus/2026-11'), entry));
    await assertFails(getDoc(doc(guest, path)));
    await assertFails(setDoc(ref, {...entry, journal1: 'x'.repeat(20001)}));
    await assertFails(setDoc(ref, {...entry, public: true}));
    await assertFails(setDoc(ref, {...entry, completedWeeks: [5]}));
    await assertFails(setDoc(doc(member, 'users/member/monthlyFocus/2026-10'), entry));
    await assertSucceeds(setDoc(ref, {journal2: 'More reflection', updatedAt: serverTimestamp()}, {merge: true}));
    if ((await getDoc(doc(secondDevice, path))).data().journal1 !== entry.journal1)
      throw Error('Saving a second week erased the first');
    console.log('Monthly Focus membership, privacy, validation, and persistence passed');
  } finally {
    await env.cleanup();
  }
})().catch(error => {console.error(error); process.exitCode = 1;});
