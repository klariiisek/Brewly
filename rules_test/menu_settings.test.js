// Menu, kategorie, nastavení podniku a stoly: mění jen admin
// (obsluha jen Otevřeno / Zavřeno).
const { describe, it, before, beforeEach, after } = require('node:test');
const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');
const { createEnv, seed, dbAs } = require('./helpers');

const product = (overrides = {}) => ({
  name: 'Espresso',
  price: 55,
  categoryId: 'kava',
  description: 'Silná káva',
  icon: '',
  available: true,
  ...overrides,
});

describe('Menu a kategorie', () => {
  let env;
  before(async () => { env = await createEnv(); });
  beforeEach(async () => { await env.clearFirestore(); await seed(env); });
  after(async () => { await env.cleanup(); });

  it('menu si přečte i nepřihlášený návštěvník', async () => {
    await assertSucceeds(getDoc(doc(dbAs(env, null), 'categories', 'kava')));
  });

  it('admin přidá produkt', async () => {
    await assertSucceeds(setDoc(doc(dbAs(env, 'admin'), 'products', 'p1'), product()));
  });

  it('zákazník ani obsluha produkt NEpřidají', async () => {
    await assertFails(setDoc(doc(dbAs(env, 'klara'), 'products', 'p1'), product()));
    await assertFails(setDoc(doc(dbAs(env, 'obsluha'), 'products', 'p1'), product()));
  });

  it('produkt NEjde uložit s neexistující kategorií (cizí klíč)', async () => {
    await assertFails(setDoc(doc(dbAs(env, 'admin'), 'products', 'p1'), product({ categoryId: 'neni' })));
  });

  it('produkt NEprojde s příliš dlouhým názvem, popisem nebo cenou', async () => {
    const db = dbAs(env, 'admin');
    await assertFails(setDoc(doc(db, 'products', 'p1'), product({ name: 'K'.repeat(61) })));
    await assertFails(setDoc(doc(db, 'products', 'p1'), product({ description: 'a'.repeat(301) })));
    await assertFails(setDoc(doc(db, 'products', 'p1'), product({ price: 10001 })));
    await assertFails(setDoc(doc(db, 'products', 'p1'), product({ price: 0 })));
  });

  it('kategorie mění jen admin', async () => {
    await assertSucceeds(updateDoc(doc(dbAs(env, 'admin'), 'categories', 'kava'), { name: 'Kávy' }));
    await assertFails(updateDoc(doc(dbAs(env, 'obsluha'), 'categories', 'kava'), { name: 'Pivo' }));
    await assertFails(deleteDoc(doc(dbAs(env, 'klara'), 'categories', 'kava')));
  });
});

describe('Možnosti produktů (mléko, sirup…)', () => {
  let env;
  before(async () => { env = await createEnv(); });
  beforeEach(async () => { await env.clearFirestore(); await seed(env); });
  after(async () => { await env.cleanup(); });

  const milk = (overrides = {}) => ({
    name: 'Mléko',
    choices: [{ name: 'Kravské', price: 0 }, { name: 'Ovesné', price: 15 }],
    ...overrides,
  });

  it('admin vytvoří skupinu možností, zákazník ji jen vidí', async () => {
    await assertSucceeds(setDoc(doc(dbAs(env, 'admin'), 'optionGroups', 'mleko'), milk()));
    await assertSucceeds(getDoc(doc(dbAs(env, null), 'optionGroups', 'mleko')));
    await assertFails(setDoc(doc(dbAs(env, 'klara'), 'optionGroups', 'mleko2'), milk()));
    await assertFails(setDoc(doc(dbAs(env, 'obsluha'), 'optionGroups', 'mleko2'), milk()));
  });

  it('skupina NEprojde bez názvu, bez voleb nebo s 21 volbami', async () => {
    const db = dbAs(env, 'admin');
    const many = Array.from({ length: 21 }, (_, i) => ({ name: `V${i}`, price: 0 }));
    await assertFails(setDoc(doc(db, 'optionGroups', 'x'), milk({ name: '' })));
    await assertFails(setDoc(doc(db, 'optionGroups', 'x'), milk({ choices: [] })));
    await assertFails(setDoc(doc(db, 'optionGroups', 'x'), milk({ choices: many })));
  });

  it('produkt nabízí nejvýš 10 skupin možností', async () => {
    const db = dbAs(env, 'admin');
    await assertSucceeds(setDoc(doc(db, 'products', 'p1'), product({ optionGroupIds: ['mleko'] })));
    const eleven = Array.from({ length: 11 }, (_, i) => `g${i}`);
    await assertFails(setDoc(doc(db, 'products', 'p2'), product({ optionGroupIds: eleven })));
  });
});

describe('Nastavení podniku', () => {
  let env;
  before(async () => { env = await createEnv(); });
  beforeEach(async () => { await env.clearFirestore(); await seed(env); });
  after(async () => { await env.cleanup(); });

  it('obsluha přepne Otevřeno / Zavřeno', async () => {
    await assertSucceeds(updateDoc(doc(dbAs(env, 'obsluha'), 'settings', 'venue'), { isOpen: false }));
  });

  it('obsluha NEzmění nic jiného (název, razítkovou kartu)', async () => {
    const db = dbAs(env, 'obsluha');
    await assertFails(updateDoc(doc(db, 'settings', 'venue'), { name: 'Můj bar' }));
    await assertFails(updateDoc(doc(db, 'settings', 'venue'), { loyaltyGoal: 3 }));
  });

  it('zákazník NEzmění ani Otevřeno', async () => {
    await assertFails(updateDoc(doc(dbAs(env, 'klara'), 'settings', 'venue'), { isOpen: false }));
  });

  it('admin změní název, otevírací dobu a razítkovou kartu', async () => {
    await assertSucceeds(updateDoc(doc(dbAs(env, 'admin'), 'settings', 'venue'), {
      name: 'Kavárna U Lípy',
      loyaltyGoal: 8,
      openingDays: ['08:00-20:00', '08:00-20:00', '08:00-20:00', '08:00-20:00',
        '08:00-22:00', '10:00-22:00', ''],
    }));
  });

  it('admin NEuloží neplatné hodnoty', async () => {
    const db = dbAs(env, 'admin');
    await assertFails(updateDoc(doc(db, 'settings', 'venue'), { color: 'neonova' }));
    await assertFails(updateDoc(doc(db, 'settings', 'venue'), { loyaltyGoal: 50 }));
    await assertFails(updateDoc(doc(db, 'settings', 'venue'), { openingDays: ['08:00-20:00'] }));
    await assertFails(updateDoc(doc(db, 'settings', 'venue'), { name: '' }));
  });
});

describe('Stoly a QR kódy', () => {
  let env;
  before(async () => { env = await createEnv(); });
  beforeEach(async () => { await env.clearFirestore(); await seed(env); });
  after(async () => { await env.cleanup(); });

  it('zákazník tajný kód stolu NEvidí', async () => {
    await assertFails(getDoc(doc(dbAs(env, 'klara'), 'tables', '4')));
  });

  it('obsluha kódy vidí, ale NEmění', async () => {
    await assertSucceeds(getDoc(doc(dbAs(env, 'obsluha'), 'tables', '4')));
    await assertFails(setDoc(doc(dbAs(env, 'obsluha'), 'tables', '4'), { code: 'NOVY12' }));
  });

  it('admin vygeneruje nový kód', async () => {
    await assertSucceeds(setDoc(doc(dbAs(env, 'admin'), 'tables', '4'), { code: 'NOVY12' }));
  });
});
