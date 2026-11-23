// Security rules tests (Firestore + Storage emulators, no real project).
//   cd firebase/tests && npm ci && npm test      (needs Java 21 + Node 24)
// CI runs them on every PR that touches firebase/. Every new collection gets
// cases here: what a signed-out user, the owner and another user can and
// can't do.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
// @@if auth
import { deleteDoc, doc, getDoc, setDoc } from 'firebase/firestore';
// @@else
import { doc, getDoc, setDoc } from 'firebase/firestore';
// @@endif
import { ref, uploadString } from 'firebase/storage';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-rules-test',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
    storage: { rules: readFileSync('../storage.rules', 'utf8') },
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'app_versions/android'), {
      latest_version: '1.0.0',
      min_supported_version: '1.0.0',
      store_url: 'https://play.google.com/store/apps/details?id=x',
    });
  });
});
after(async () => {
  await env.cleanup();
});

test('anyone can read app_versions', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(db, 'app_versions/android')));
});

test('nobody can change app_versions from the app', async () => {
  const anon = env.unauthenticatedContext().firestore();
  const user = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(anon, 'app_versions/android'), { latest_version: '9.9.9' }));
  await assertFails(setDoc(doc(user, 'app_versions/android'), { latest_version: '9.9.9' }));
  await assertFails(setDoc(doc(user, 'app_versions/web'), { latest_version: '1.0.0' }));
});

test('unknown collections are closed', async () => {
  const user = env.authenticatedContext('alice').firestore();
  await assertFails(getDoc(doc(user, 'anything/else')));
  await assertFails(setDoc(doc(user, 'anything/else'), { a: 1 }));
});

// @@if auth
test('a user reads and writes only their own users/{uid}', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(doc(alice, 'users/alice'), { display_name: 'Alice' }));
  await assertSucceeds(getDoc(doc(alice, 'users/alice')));
  await assertSucceeds(deleteDoc(doc(alice, 'users/alice')));
  await assertFails(getDoc(doc(alice, 'users/bob')));
  await assertFails(setDoc(doc(alice, 'users/bob'), { display_name: 'hacked' }));
  await assertFails(deleteDoc(doc(alice, 'users/bob')));
});

test('signed-out users cannot read users/{uid}', async () => {
  const anon = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(anon, 'users/alice')));
  await assertFails(setDoc(doc(anon, 'users/alice'), { display_name: 'x' }));
});

test('users/{uid} only takes known, bounded fields', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(alice, 'users/alice'), { is_admin: true }));
  await assertFails(setDoc(doc(alice, 'users/alice'), { display_name: 'x'.repeat(81) }));
  await assertFails(setDoc(doc(alice, 'users/alice'), { display_name: 42 }));
});

// @@endif
test('storage is closed until a feature opens it', async () => {
  const storage = env.authenticatedContext('alice').storage();
  await assertFails(uploadString(ref(storage, 'users/alice/a.txt'), 'hi'));
});
