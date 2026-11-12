// Společné věci pro testy bezpečnostních pravidel.
//
// Testy běží proti EMULÁTORU Firestore – kopii databáze na tomto počítači,
// která používá naše pravidla z firestore.rules. Skutečná databáze
// (brewly-9e944) se nikdy nezmění: projekt v testech se jmenuje
// "demo-brewly" a takový na internetu neexistuje.
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { doc, setDoc, Timestamp, setLogLevel } = require('firebase/firestore');

// Odmítnuté zápisy (PERMISSION_DENIED) jsou v testech schválně – nevypisujeme je.
setLogLevel('silent');

// Spustí testovací prostředí s našimi pravidly.
function createEnv() {
  return initializeTestEnvironment({
    projectId: 'demo-brewly',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
}

// Testovací uživatelé (uid → role).
const users = {
  admin: 'admin',
  obsluha: 'obsluha',
  klara: 'zakaznik',
  petr: 'zakaznik',
};

// Tajný kód stolu 4.
const TABLE_CODE = 'ABC123';

// Naplní prázdnou databázi výchozími daty – bez kontroly pravidel
// (jako by je tam dal programátor v konzoli).
async function seed(env, { isOpen = true } = {}) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [uid, role] of Object.entries(users)) {
      await setDoc(doc(db, 'users', uid), {
        name: uid,
        email: `${uid}@test.cz`,
        role,
        createdAt: Timestamp.now(),
      });
    }
    await setDoc(doc(db, 'settings', 'venue'), {
      name: 'Brewly',
      slogan: '',
      color: 'kava',
      type: 'kavarna',
      isOpen,
      loyaltyEnabled: true,
      loyaltyCategoryId: 'kava',
      loyaltyGoal: 10,
    });
    await setDoc(doc(db, 'tables', '4'), { code: TABLE_CODE });
    await setDoc(doc(db, 'categories', 'kava'), { name: 'Káva', order: 0 });
  });
}

// Databáze tak, jak ji vidí přihlášený uživatel (nebo nepřihlášený).
function dbAs(env, uid) {
  return uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
}

// Dnešní den jako číslo (20261112) v čase UTC – stejně jako v pravidlech.
function todayKey() {
  const now = new Date();
  return now.getUTCFullYear() * 10000 + (now.getUTCMonth() + 1) * 100 + now.getUTCDate();
}

// Čas za/před zadaný počet hodin od teď.
function hoursFromNow(hours) {
  return Timestamp.fromMillis(Date.now() + hours * 60 * 60 * 1000);
}

module.exports = { createEnv, seed, dbAs, todayKey, hoursFromNow, TABLE_CODE };
