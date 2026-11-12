// Požadavky na obsluhu (Přivolat obsluhu, Chci zaplatit) a rezervace stolů.
const { describe, it, before, beforeEach, after } = require('node:test');
const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp,
} = require('firebase/firestore');
const { createEnv, seed, dbAs, hoursFromNow, TABLE_CODE } = require('./helpers');

const request = (type, overrides = {}) => ({
  type,
  tableNumber: 4,
  tableCode: TABLE_CODE,
  userId: 'klara',
  customerName: 'Klára',
  status: 'cekajici',
  createdAt: serverTimestamp(),
  ...overrides,
});

describe('Požadavky na obsluhu', () => {
  let env;
  before(async () => { env = await createEnv(); });
  beforeEach(async () => { await env.clearFirestore(); await seed(env); });
  after(async () => { await env.cleanup(); });

  it('zákazník u stolu přivolá obsluhu', async () => {
    await assertSucceeds(setDoc(doc(dbAs(env, 'klara'), 'requests', 'klara_obsluha'), request('obsluha')));
  });

  it('se špatným kódem stolu NEprojde', async () => {
    await assertFails(setDoc(doc(dbAs(env, 'klara'), 'requests', 'klara_obsluha'),
      request('obsluha', { tableCode: 'XXXXXX' })));
  });

  it('ID požadavku musí být „uživatel_typ“ (ochrana proti spamu)', async () => {
    await assertFails(setDoc(doc(dbAs(env, 'klara'), 'requests', 'nahodne-id'), request('obsluha')));
  });

  it('dokud požadavek čeká, další stejný NEprojde; po vyřízení ano', async () => {
    const db = dbAs(env, 'klara');
    await assertSucceeds(setDoc(doc(db, 'requests', 'klara_platba'), request('platba')));
    await assertFails(setDoc(doc(db, 'requests', 'klara_platba'), request('platba')));
    await assertSucceeds(updateDoc(doc(dbAs(env, 'obsluha'), 'requests', 'klara_platba'), { status: 'vyrizeno' }));
    await assertSucceeds(setDoc(doc(db, 'requests', 'klara_platba'), request('platba')));
  });

  it('při zavřeno jde zaplatit, ale NE přivolat obsluhu', async () => {
    await env.clearFirestore();
    await seed(env, { isOpen: false });
    const db = dbAs(env, 'klara');
    await assertSucceeds(setDoc(doc(db, 'requests', 'klara_platba'), request('platba')));
    await assertFails(setDoc(doc(db, 'requests', 'klara_obsluha'), request('obsluha')));
  });

  it('obsluha požadavky NEposílá', async () => {
    await assertFails(setDoc(doc(dbAs(env, 'obsluha'), 'requests', 'obsluha_obsluha'),
      request('obsluha', { userId: 'obsluha' })));
  });
});

const reservation = (overrides = {}) => ({
  userId: 'klara',
  customerName: 'Klára',
  time: hoursFromNow(24),
  people: 2,
  note: '',
  status: 'ceka',
  tableNumber: 0,
  createdAt: serverTimestamp(),
  ...overrides,
});

describe('Rezervace', () => {
  let env;
  before(async () => { env = await createEnv(); });
  beforeEach(async () => { await env.clearFirestore(); await seed(env); });
  after(async () => { await env.cleanup(); });

  it('zákazník zarezervuje stůl na zítra', async () => {
    await assertSucceeds(setDoc(doc(dbAs(env, 'klara'), 'reservations', 'r1'), reservation()));
  });

  it('rezervace NEprojde v minulosti ani víc než měsíc dopředu', async () => {
    const db = dbAs(env, 'klara');
    await assertFails(setDoc(doc(db, 'reservations', 'r1'), reservation({ time: hoursFromNow(-1) })));
    await assertFails(setDoc(doc(db, 'reservations', 'r1'), reservation({ time: hoursFromNow(24 * 40) })));
  });

  it('rezervace NEprojde pro 0 nebo 13 osob', async () => {
    const db = dbAs(env, 'klara');
    await assertFails(setDoc(doc(db, 'reservations', 'r1'), reservation({ people: 0 })));
    await assertFails(setDoc(doc(db, 'reservations', 'r1'), reservation({ people: 13 })));
  });

  it('zákazník si NEpotvrdí rezervaci sám ani si nevybere stůl', async () => {
    const db = dbAs(env, 'klara');
    await assertFails(setDoc(doc(db, 'reservations', 'r1'), reservation({ status: 'potvrzena' })));
    await assertFails(setDoc(doc(db, 'reservations', 'r1'), reservation({ tableNumber: 4 })));
  });

  it('nikdo NErezervuje za jiného a obsluha nerezervuje vůbec', async () => {
    await assertFails(setDoc(doc(dbAs(env, 'klara'), 'reservations', 'r1'), reservation({ userId: 'petr' })));
    await assertFails(setDoc(doc(dbAs(env, 'obsluha'), 'reservations', 'r1'),
      reservation({ userId: 'obsluha' })));
  });

  describe('existující rezervace', () => {
    beforeEach(async () => {
      await setDoc(doc(dbAs(env, 'klara'), 'reservations', 'r1'), reservation());
    });

    it('cizí zákazník rezervaci NEvidí, obsluha ano', async () => {
      await assertFails(getDoc(doc(dbAs(env, 'petr'), 'reservations', 'r1')));
      await assertSucceeds(getDoc(doc(dbAs(env, 'obsluha'), 'reservations', 'r1')));
    });

    it('zákazník svou rezervaci zruší, cizí NE', async () => {
      await assertFails(updateDoc(doc(dbAs(env, 'petr'), 'reservations', 'r1'), { status: 'zrusena' }));
      await assertSucceeds(updateDoc(doc(dbAs(env, 'klara'), 'reservations', 'r1'), { status: 'zrusena' }));
    });

    it('zákazník NEzmění čas ani počet osob', async () => {
      await assertFails(updateDoc(doc(dbAs(env, 'klara'), 'reservations', 'r1'), { people: 10 }));
    });

    it('obsluha potvrdí rezervaci se stolem 4', async () => {
      await assertSucceeds(updateDoc(doc(dbAs(env, 'obsluha'), 'reservations', 'r1'),
        { status: 'potvrzena', tableNumber: 4 }));
    });

    it('obsluha NEpřidělí neexistující stůl a NEzmění čas', async () => {
      const db = dbAs(env, 'obsluha');
      await assertFails(updateDoc(doc(db, 'reservations', 'r1'), { status: 'potvrzena', tableNumber: 11 }));
      await assertFails(updateDoc(doc(db, 'reservations', 'r1'), { time: hoursFromNow(48) }));
    });

    it('odmítnutou rezervaci už NEjde potvrdit', async () => {
      const db = dbAs(env, 'obsluha');
      await assertSucceeds(updateDoc(doc(db, 'reservations', 'r1'), { status: 'odmitnuta' }));
      await assertFails(updateDoc(doc(db, 'reservations', 'r1'), { status: 'potvrzena' }));
    });

    it('rezervace NEjde smazat', async () => {
      await assertFails(deleteDoc(doc(dbAs(env, 'klara'), 'reservations', 'r1')));
      await assertFails(deleteDoc(doc(dbAs(env, 'admin'), 'reservations', 'r1')));
    });
  });
});
