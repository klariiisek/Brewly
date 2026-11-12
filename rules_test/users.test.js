// Uživatelé a role: nikdo si sám nepřidělí obsluhu nebo admina.
const { describe, it, before, beforeEach, after } = require('node:test');
const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, serverTimestamp } = require('firebase/firestore');
const { createEnv, seed, dbAs } = require('./helpers');

describe('Uživatelé a role', () => {
  let env;
  before(async () => { env = await createEnv(); });
  beforeEach(async () => { await env.clearFirestore(); await seed(env); });
  after(async () => { await env.cleanup(); });

  const newProfile = (role) => ({
    name: 'Nová', email: 'nova@test.cz', role, createdAt: serverTimestamp(),
  });

  it('nový uživatel si založí profil jako zákazník', async () => {
    await assertSucceeds(setDoc(doc(dbAs(env, 'nova'), 'users', 'nova'), newProfile('zakaznik')));
  });

  it('nový uživatel si NEzaloží profil jako admin ani obsluha', async () => {
    await assertFails(setDoc(doc(dbAs(env, 'nova'), 'users', 'nova'), newProfile('admin')));
    await assertFails(setDoc(doc(dbAs(env, 'nova'), 'users', 'nova'), newProfile('obsluha')));
  });

  it('nikdo nezaloží profil za někoho jiného', async () => {
    await assertFails(setDoc(doc(dbAs(env, 'nova'), 'users', 'jiny'), newProfile('zakaznik')));
  });

  it('zákazník si změní jméno, avatar, vzhled a oblíbené', async () => {
    await assertSucceeds(updateDoc(doc(dbAs(env, 'klara'), 'users', 'klara'), {
      name: 'Klára', avatarIcon: 'coffee', avatarColor: 'hneda',
      themeMode: 'dark', favorites: ['p1', 'p2'],
    }));
  });

  it('zákazník si NEzmění roli', async () => {
    await assertFails(updateDoc(doc(dbAs(env, 'klara'), 'users', 'klara'), { role: 'admin' }));
  });

  it('zákazník NEuloží neplatný vzhled ani nepovolené pole', async () => {
    await assertFails(updateDoc(doc(dbAs(env, 'klara'), 'users', 'klara'), { themeMode: 'ruzova' }));
    await assertFails(updateDoc(doc(dbAs(env, 'klara'), 'users', 'klara'), { sleva: 100 }));
  });

  it('zákazník NEvidí cizí profil, obsluha ano', async () => {
    await assertFails(getDoc(doc(dbAs(env, 'klara'), 'users', 'petr')));
    await assertSucceeds(getDoc(doc(dbAs(env, 'obsluha'), 'users', 'petr')));
  });

  it('admin změní zákazníka na obsluhu a zpět', async () => {
    const db = dbAs(env, 'admin');
    await assertSucceeds(updateDoc(doc(db, 'users', 'petr'), { role: 'obsluha' }));
    await assertSucceeds(updateDoc(doc(db, 'users', 'petr'), { role: 'zakaznik' }));
  });

  it('admin NEudělá z nikoho admina a NEmění sám sebe', async () => {
    await assertFails(updateDoc(doc(dbAs(env, 'admin'), 'users', 'petr'), { role: 'admin' }));
    await assertFails(updateDoc(doc(dbAs(env, 'admin'), 'users', 'admin'), { role: 'obsluha' }));
  });

  it('admin NEmění u ostatních nic jiného než roli', async () => {
    await assertFails(updateDoc(doc(dbAs(env, 'admin'), 'users', 'petr'), { name: 'Hacker' }));
  });

  it('obsluha NEmění role', async () => {
    await assertFails(updateDoc(doc(dbAs(env, 'obsluha'), 'users', 'petr'), { role: 'obsluha' }));
  });
});
