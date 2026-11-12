// Objednávky: kód stolu, číslo z počítadla, otevřeno, stav jen o krok dopředu.
const { describe, it, before, beforeEach, after } = require('node:test');
const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp,
} = require('firebase/firestore');
const { createEnv, seed, dbAs, todayKey, TABLE_CODE } = require('./helpers');

// Platná objednávka (každý test si v ní změní to, co zkouší).
function validOrder(overrides = {}) {
  return {
    number: 1,
    items: [{ productId: 'p1', name: 'Espresso', price: 55, quantity: 1 }],
    totalPrice: 55,
    tableNumber: 4,
    tableCode: TABLE_CODE,
    status: 'prijata',
    userId: 'klara',
    customerName: 'Klára',
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

// Uloží objednávku stejně jako aplikace: spolu s počítadlem čísel
// (aplikace používá transakci, tady stačí hromadný zápis – pravidla
// kontrolují totéž).
function placeOrder(db, order, counter = { last: 1, day: todayKey() }) {
  const batch = writeBatch(db);
  batch.set(doc(db, 'orderNumbers', 'today'), counter);
  batch.set(doc(db, 'orders', 'o1'), order);
  return batch.commit();
}

describe('Objednávky', () => {
  let env;
  before(async () => { env = await createEnv(); });
  beforeEach(async () => { await env.clearFirestore(); await seed(env); });
  after(async () => { await env.cleanup(); });

  it('zákazník u stolu odešle platnou objednávku', async () => {
    await assertSucceeds(placeOrder(dbAs(env, 'klara'), validOrder()));
  });

  it('nepřihlášený NEobjedná', async () => {
    await assertFails(placeOrder(dbAs(env, null), validOrder()));
  });

  it('objednávka se špatným kódem stolu NEprojde', async () => {
    await assertFails(placeOrder(dbAs(env, 'klara'), validOrder({ tableCode: 'XXXXXX' })));
  });

  it('nikdo NEobjedná za někoho jiného', async () => {
    await assertFails(placeOrder(dbAs(env, 'klara'), validOrder({ userId: 'petr' })));
  });

  it('číslo objednávky musí pocházet z počítadla', async () => {
    await assertFails(placeOrder(dbAs(env, 'klara'), validOrder({ number: 99 })));
  });

  it('počítadlo NEjde nastavit na jiný den', async () => {
    await assertFails(placeOrder(dbAs(env, 'klara'), validOrder(), { last: 1, day: 20200101 }));
  });

  it('objednávka NEmůže začít v jiném stavu než Přijata', async () => {
    await assertFails(placeOrder(dbAs(env, 'klara'), validOrder({ status: 'dokoncena' })));
  });

  it('objednávka NEsmí mít pole navíc ani nulovou cenu bez odměny', async () => {
    await assertFails(placeOrder(dbAs(env, 'klara'), validOrder({ sleva: 50 })));
    await assertFails(placeOrder(dbAs(env, 'klara'), validOrder({ totalPrice: 0 })));
  });

  it('odměna z razítkové karty musí stát správný počet razítek', async () => {
    const reward = { totalPrice: 0, rewardProductId: 'p1', rewardDiscount: 55 };
    await assertFails(placeOrder(dbAs(env, 'klara'), validOrder({ ...reward, rewardStamps: 3 })));
    await assertSucceeds(placeOrder(dbAs(env, 'klara'), validOrder({ ...reward, rewardStamps: 9 })));
  });

  it('když má podnik zavřeno, objednat NEjde', async () => {
    await env.clearFirestore();
    await seed(env, { isOpen: false });
    await assertFails(placeOrder(dbAs(env, 'klara'), validOrder()));
  });

  it('obsluha a admin NEobjednávají', async () => {
    await assertFails(placeOrder(dbAs(env, 'obsluha'), validOrder({ userId: 'obsluha' })));
    await assertFails(placeOrder(dbAs(env, 'admin'), validOrder({ userId: 'admin' })));
  });

  describe('existující objednávka', () => {
    beforeEach(async () => {
      await placeOrder(dbAs(env, 'klara'), validOrder());
    });

    it('zákazník vidí svou objednávku, cizí NE', async () => {
      await assertSucceeds(getDoc(doc(dbAs(env, 'klara'), 'orders', 'o1')));
      await assertFails(getDoc(doc(dbAs(env, 'petr'), 'orders', 'o1')));
    });

    it('obsluha posune stav o jeden krok', async () => {
      await assertSucceeds(updateDoc(doc(dbAs(env, 'obsluha'), 'orders', 'o1'), { status: 'pripravujeSe' }));
    });

    it('obsluha NEpřeskočí stav ani nezmění cenu', async () => {
      const db = dbAs(env, 'obsluha');
      await assertFails(updateDoc(doc(db, 'orders', 'o1'), { status: 'dokoncena' }));
      await assertFails(updateDoc(doc(db, 'orders', 'o1'), { totalPrice: 1 }));
    });

    it('zákazník si NEdokončí objednávku sám (razítka)', async () => {
      await assertFails(updateDoc(doc(dbAs(env, 'klara'), 'orders', 'o1'), { status: 'pripravujeSe' }));
    });

    it('objednávky NEjde smazat ani přepsat', async () => {
      await assertFails(deleteDoc(doc(dbAs(env, 'admin'), 'orders', 'o1')));
      await assertFails(setDoc(doc(dbAs(env, 'klara'), 'orders', 'o1'), validOrder({ totalPrice: 1 })));
    });
  });
});
