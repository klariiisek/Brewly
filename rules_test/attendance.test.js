// Docházka: čas serveru, směna vzniká jen spolu s odchodem a nejde ji měnit.
const { describe, it, before, beforeEach, after } = require('node:test');
const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, setDoc, updateDoc, writeBatch, serverTimestamp,
} = require('firebase/firestore');
const { createEnv, seed, dbAs, hoursFromNow } = require('./helpers');

describe('Docházka', () => {
  let env;
  before(async () => { env = await createEnv(); });
  beforeEach(async () => { await env.clearFirestore(); await seed(env); });
  after(async () => { await env.cleanup(); });

  const clockIn = (overrides = {}) => ({
    userId: 'obsluha', userName: 'Obsluha', start: serverTimestamp(), ...overrides,
  });

  it('obsluha dá Příchod s časem serveru', async () => {
    await assertSucceeds(setDoc(doc(dbAs(env, 'obsluha'), 'activeShifts', 'obsluha'), clockIn()));
  });

  it('Příchod s vlastním časem (např. o 2 hodiny dřív) NEprojde', async () => {
    await assertFails(setDoc(doc(dbAs(env, 'obsluha'), 'activeShifts', 'obsluha'),
      clockIn({ start: hoursFromNow(-2) })));
  });

  it('zákazník NEdá Příchod a obsluha NEdá Příchod za kolegu', async () => {
    await assertFails(setDoc(doc(dbAs(env, 'klara'), 'activeShifts', 'klara'),
      clockIn({ userId: 'klara' })));
    await assertFails(setDoc(doc(dbAs(env, 'obsluha'), 'activeShifts', 'admin'),
      clockIn({ userId: 'admin' })));
  });

  describe('zaměstnanec je v práci', () => {
    // Příchod před 3 hodinami (vložený bez pravidel, aby šel čas posunout).
    const start = hoursFromNow(-3);
    beforeEach(async () => {
      await env.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'activeShifts', 'obsluha'),
          { userId: 'obsluha', userName: 'Obsluha', start });
      });
    });

    // Odchod jako v aplikaci: hotová směna + smazání „v práci“ v jednom zápisu.
    function clockOut(db, shift, deleteActive = true) {
      const batch = writeBatch(db);
      batch.set(doc(db, 'shifts', 's1'), shift);
      if (deleteActive) batch.delete(doc(db, 'activeShifts', 'obsluha'));
      return batch.commit();
    }
    const shift = (overrides = {}) => ({
      userId: 'obsluha', userName: 'Obsluha', start, end: serverTimestamp(), edited: false,
      ...overrides,
    });

    it('čas příchodu NEjde změnit', async () => {
      await assertFails(updateDoc(doc(dbAs(env, 'obsluha'), 'activeShifts', 'obsluha'),
        { start: hoursFromNow(-8) }));
    });

    it('obsluha dá Odchod – vznikne hotová směna', async () => {
      await assertSucceeds(clockOut(dbAs(env, 'obsluha'), shift()));
    });

    it('směna NEvznikne bez smazání záznamu „v práci“ (nešla by vyrobit dvakrát)', async () => {
      await assertFails(clockOut(dbAs(env, 'obsluha'), shift(), false));
    });

    it('směna NEsmí mít jiný příchod, než byl zapsaný', async () => {
      await assertFails(clockOut(dbAs(env, 'obsluha'), shift({ start: hoursFromNow(-10) })));
    });

    it('obsluha si NEzadá vlastní čas odchodu', async () => {
      await assertFails(clockOut(dbAs(env, 'obsluha'), shift({ end: hoursFromNow(5) })));
    });

    it('admin ukončí zapomenutou směnu s časem v minulosti', async () => {
      await assertSucceeds(clockOut(dbAs(env, 'admin'),
        shift({ end: hoursFromNow(-1), edited: true })));
    });

    it('admin NEzadá odchod v budoucnosti ani před příchodem', async () => {
      const db = dbAs(env, 'admin');
      await assertFails(clockOut(db, shift({ end: hoursFromNow(2), edited: true })));
      await assertFails(clockOut(db, shift({ end: hoursFromNow(-5), edited: true })));
    });

    it('hotovou směnu NEjde změnit a cizí směny zaměstnanec NEvidí', async () => {
      await clockOut(dbAs(env, 'obsluha'), shift());
      await assertFails(updateDoc(doc(dbAs(env, 'obsluha'), 'shifts', 's1'), { end: hoursFromNow(5) }));
      await assertFails(updateDoc(doc(dbAs(env, 'admin'), 'shifts', 's1'), { end: hoursFromNow(-2) }));
      await assertSucceeds(getDoc(doc(dbAs(env, 'admin'), 'shifts', 's1')));
      await assertFails(getDoc(doc(dbAs(env, 'klara'), 'shifts', 's1')));
    });
  });
});
