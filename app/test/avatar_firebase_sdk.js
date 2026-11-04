import * as core from 'firebase/app';
import * as auth from 'firebase/auth';
import * as firestore from 'firebase/firestore';

// The Chrome test runs against local emulators, including when gstatic is
// unreachable. These are the module names FlutterFire normally loads from CDN.
Object.assign(globalThis, {
  firebase_core: core,
  firebase_auth: auth,
  firebase_firestore: firestore,
});
