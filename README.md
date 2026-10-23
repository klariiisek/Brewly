# ☕ Brewly

**Brewly** je webová aplikace pro objednávání přímo ke stolu: zákazník ji otevře v mobilu přes QR kód, bez instalace. Je to můj maturitní projekt ve **Flutteru** s databází **Firebase**.

Zákazník naskenuje QR kód na stole, prohlédne si menu, objedná a sleduje, jak se jeho objednávka připravuje. Obsluha vidí objednávky i požadavky zákazníků živě. Vedoucí podniku (admin) si v aplikaci sám spravuje menu, vzhled i provoz. Aplikace je navržená pro kavárnu, ale díky nastavení ji může používat i bar, cukrárna nebo restaurace.

🌐 **Vyzkoušet:** [brewly-9e944.web.app](https://brewly-9e944.web.app)

---

## 📋 Obsah

- [💡 Proč Brewly vzniklo](#-proč-brewly-vzniklo)
- [✨ Co aplikace umí](#-co-aplikace-umí)
- [🛠️ Technologie](#️-technologie)
- [🧭 Jak to funguje](#-jak-to-funguje)
- [⚙️ Konfigurace vs. databáze](#️-konfigurace-vs-databáze)
- [🗄️ Databáze](#️-databáze)
- [🔒 Zabezpečení](#-zabezpečení)
- [📁 Struktura projektu](#-struktura-projektu)
- [🚀 Spuštění projektu](#-spuštění-projektu)
- [🧪 Testy](#-testy)
- [🗺️ Plánované funkce](#️-plánované-funkce)

---

## 💡 Proč Brewly vzniklo

Sama pracuji v kavárně a každý den vidím, kolik času zabere obyčejné objednávání. Chodím od stolu ke stolu, zapisuji si objednávky, běhám k baru a zpátky. Když je plno, zákazníci čekají, až si jich někdo všimne. A když chtějí zaplatit, musí mávat přes celou místnost.

Chtěla jsem, aby to šlo jednodušeji, pro zákazníky i pro nás za barem. Proto jsem se rozhodla vytvořit vlastní aplikaci:

- **zákazník** si objedná sám ze stolu, kdy se mu to hodí, a vidí, v jakém stavu jeho objednávka je,
- **obsluha** má všechny objednávky přehledně na jednom místě a hned ví, ke kterému stolu co nést,
- **přivolat obsluhu** nebo **požádat o účet** jde jedním klepnutím,
- **vedoucí** si menu, ceny i vzhled aplikace upraví sám, bez programátora.

Kavárna, ve které pracuji, mi byla inspirací. Aplikaci jsem ale od začátku navrhovala tak, aby si ji mohl přizpůsobit jakýkoli podnik.

---

## ✨ Co aplikace umí

Aplikace rozlišuje čtyři typy uživatelů. Co kdo smí, nehlídá jen aplikace, ale i bezpečnostní pravidla databáze.

### 👤 Návštěvník (nepřihlášený)
- prohlíží si menu podle kategorií a detail produktu,
- vidí informace o podniku (adresa, otevírací doba, Wi-Fi),
- může si naplnit košík. Před objednáním se musí přihlásit.

### ☕ Zákazník
- registrace a přihlášení **e-mailem a heslem** nebo **přes Google**, obnovení zapomenutého hesla,
- **QR kód na stole** otevře **rovnou menu** a aplikace ví, u kterého stolu zákazník sedí (stůl jde zadat i opsaným kódem),
- **košík**: změna množství, hlídání vyprodaných produktů a změn cen,
- **plovoucí lišta košíku** v menu („2 položky · 135 Kč → Do košíku“), takže se nemusí hledat záložka,
- **objednávka ke stolu**: po odeslání se hned otevře **sledování s ukazatelem průběhu** (Přijata → Připravuje se → Připravena → Dokončena),
- **upozornění „Vaše objednávka je připravená! 🎉“**, ať je zákazník v aplikaci kdekoli,
- historie objednávek s detailem,
- **profil**: avatar (ikonka a barva, nebo fotka z Google), změna jména a hesla,
- tlačítka **Přivolat obsluhu** a **Chci zaplatit**.

### 👩‍🍳 Obsluha
- živý přehled v záložkách **Požadavky**, **Aktivní** a **Dokončené**,
- posouvání objednávek do dalšího stavu jedním tlačítkem,
- vyřizování požadavků zákazníků,
- přepínač **Otevřeno / Zavřeno** (když je zavřeno, nejde objednat),
- **QR kódy stolů** k vytištění a jejich obnovení, kdyby kód unikl.

### 🧑‍💼 Admin (vedoucí podniku)
Umí všechno co obsluha, a navíc:
- **správa menu**: přidání, úprava a smazání produktu, přepínač **vyprodáno**, vyhledávání,
- **nahrání celého menu ze souboru CSV** (např. z Excelu) s kontrolou chyb před uložením,
- **kategorie**: přidání, přejmenování, smazání a řazení přetažením,
- **nastavení podniku**:
  - název, slogan a typ podniku (kavárna, cukrárna, bar, pivnice, restaurace),
  - **barva aplikace** z 8 palet: celá aplikace se přebarví živě, i zákazníkům,
  - **oznámení v menu** (např. „Dnes −20 % na dezerty“),
  - informace pro zákazníky: adresa, otevírací doba, Wi-Fi.

### 📸 Ukázky

**Košík a správa menu.** Vlevo košík zákazníka: produkt, který admin mezitím označil jako vyprodaný, se zešedí a objednat nejde, dokud ho zákazník neodebere. Vpravo správa menu s vyhledáváním a přepínačem vyprodáno.

![Košík a správa menu](docs/screenshots/kosik-a-sprava-menu.png)

**Nahrání menu ze souboru CSV.** Návod, jak má soubor vypadat, a výběr souboru (např. uloženého z Excelu).

![Nahrání menu z CSV](docs/screenshots/csv-vyber-souboru.png)

**Kontrola CSV před uložením.** Aplikace soubor zkontroluje řádek po řádku. Chybné řádky ukáže červeně a nenahraje je, správné produkty ukáže v náhledu.

<img src="docs/screenshots/csv-kontrola-chyb.png" alt="Kontrola chyb v CSV" width="600">

**Přizpůsobení podniku.** Admin změní název, typ podniku a barvu. Vpravo živý náhled, vlevo stejná aplikace přebarvená pro cukrárnu „Cukřík“.

![Nastavení podniku](docs/screenshots/nastaveni-podniku.png)

---

## 🛠️ Technologie

| Technologie | K čemu ji používám |
|---|---|
| **Flutter / Dart** | celá aplikace (webová aplikace, funguje v prohlížeči na počítači i v mobilu) |
| **Firebase Authentication** | registrace a přihlášení (e-mail + heslo, Google) |
| **Cloud Firestore** | databáze s živými aktualizacemi |
| **Firestore Security Rules** | kdo smí co číst a měnit (zabezpečení na straně serveru) |
| **Firebase Hosting** | zveřejnění aplikace na webu |
| **CustomPainter** (Flutter) | vlastní ikony nápojů, ilustrace na úvodní obrazovce (s animovanou párou) a vzor v pozadí podle typu podniku – aplikace je sama kreslí a přebarvuje podle barvy podniku |
| písmo **Lexend** | písmo navržené pro snadné čtení, přibalené přímo v aplikaci |
| `qr_flutter` | generování QR kódů stolů |
| `file_picker` | výběr CSV souboru s menu |
| `fake_cloud_firestore`, `firebase_auth_mocks` | falešná databáze a přihlášení pro testy |

---

## 🧭 Jak to funguje

Zákazník, obsluha i admin používají stejnou aplikaci, každý vidí jen svou část podle role. Aplikace je napsaná ve Flutteru a běží v prohlížeči. Data ukládá do Firebase a každý zápis do databáze nejdřív zkontrolují bezpečnostní pravidla.

```mermaid
flowchart LR
    Z["👤 Zákazník<br/>(QR kód na stole)"]
    O["👩‍🍳 Obsluha"]
    A["🧑‍💼 Admin"]

    subgraph App["📱 Aplikace Flutter (v prohlížeči)"]
        Obr["Obrazovky<br/>screens, widgets"] --> Sl["Služby<br/>services"]
    end

    subgraph FB["🔥 Firebase"]
        Host["Hosting<br/>web aplikace"]
        Auth["Authentication<br/>e-mail, Google"]
        Pr{{"Bezpečnostní<br/>pravidla"}} --> DB[("Cloud Firestore")]
    end

    Z --> Obr
    O --> Obr
    A --> Obr
    Obr -. "načte se z" .-> Host
    Sl -- "přihlášení" --> Auth
    Sl <-- "čtení, zápis<br/>a živé změny" --> Pr

    classDef role fill:#F3E9DF,stroke:#6F4E37,color:#3E2723
    class Z,O,A role
```

Aplikace se načte z **Firebase Hosting** (čárkovaná šipka). Obrazovky volají **služby**, které zajišťují přihlášení a práci s databází. Šipka mezi službami a pravidly vede oběma směry: aplikace data čte a zapisuje a databáze jí sama posílá změny, takže se nová objednávka obsluze ukáže hned. Hodnoty, které nastavuje programátor, jsou v konfiguraci (viz [Konfigurace vs. databáze](#️-konfigurace-vs-databáze)).

---

## ⚙️ Konfigurace vs. databáze

Nastavení aplikace je rozdělené na dvě části podle toho, **kdo ho mění a kdy**:

| | **Konfigurační soubor** | **Databáze** (`settings/venue`) |
|---|---|---|
| Kdo mění | programátor | vedoucí podniku (admin) v aplikaci |
| Kdy | při nasazení aplikace pro podnik | kdykoli za provozu |
| Jak se změna projeví | upravit soubor, znovu sestavit a nahrát aplikaci | **hned, všem zákazníkům** |
| Co obsahuje | adresa aplikace, **počet stolů**, délka kódu stolu, **barevné palety**, výchozí vzhled, limity (max. cena, délky textů, počet položek) | název, slogan, typ podniku, vybraná barva, otevřeno/zavřeno, oznámení, adresa, otevírací doba, Wi-Fi |

Konfigurace je v souborech [`lib/config/app_config.dart`](lib/config/app_config.dart) a [`lib/config/palettes.dart`](lib/config/palettes.dart).

**Proč nastavení podniku není taky v souboru?** Vedoucí podniku není programátor. Když ráno zavírá kvůli nemoci, mění akci dne nebo heslo na Wi-Fi, musí to zvládnout sám z mobilu a změna se musí hned projevit všem zákazníkům. To konfigurační soubor neumí, databáze ano.

---

## 🗄️ Databáze

### Proč Firestore (NoSQL)
Používám **Cloud Firestore**. Je to **NoSQL** databáze: data nejsou v tabulkách s řádky, ale v **kolekcích**, které obsahují **dokumenty** (podobné JSONu). Pro mou aplikaci má dvě velké výhody:

- **živé aktualizace**: když zákazník objedná, obsluze se objednávka ukáže okamžitě, bez obnovování stránky,
- **přímé napojení na přihlašování**: bezpečnostní pravidla znají přihlášeného uživatele a jeho roli.

### Diagram databáze
Klasický ER diagram je stavěný pro relační databáze s tabulkami a cizími klíči. Firestore pracuje s **kolekcemi dokumentů**, proto diagram ukazuje kolekce, jednotlivé dokumenty a **odkazy mezi nimi**. Pole každé kolekce jsou v tabulkách pod diagramem.

```mermaid
flowchart TB
    subgraph Single["Samostatné dokumenty"]
        direction LR
        numbers[["orderNumbers/today<br/>čísla objednávek"]]
        settings[["settings/venue<br/>nastavení podniku"]]
    end

    orders[("orders<br/>objednávky")]
    requests[("requests<br/>přivolat obsluhu, zaplatit")]
    items[/"items<br/>položky vnořené v objednávce"/]
    users[("users<br/>uživatelé a role")]
    tables[("tables<br/>stoly a tajné kódy")]
    products[("products<br/>produkty")]
    categories[("categories<br/>kategorie menu")]

    numbers -. "přidělí číslo" .-> orders
    orders --- items
    items -. "kopie produktu" .-> products
    products -- "categoryId" --> categories
    orders -- "userId" --> users
    requests -- "userId" --> users
    orders -- "tableNumber" --> tables
    requests -- "tableNumber" --> tables

    classDef kolekce fill:#F3E9DF,stroke:#6F4E37,color:#3E2723
    classDef dokument fill:#FFF6D6,stroke:#C8894B,color:#3E2723
    classDef vnorene fill:#FFFFFF,stroke:#8D7B6F,stroke-dasharray:4 3,color:#3E2723
    class users,categories,products,orders,requests,tables kolekce
    class numbers,settings dokument
    class items vnorene
```

**Legenda:**
- **válec** = kolekce (mnoho dokumentů, např. všechny objednávky),
- **dvojitý obdélník** = jediný samostatný dokument,
- **kosodélník** = data vnořená uvnitř dokumentu (položky objednávky),
- **plná šipka** = odkaz pomocí ID (jako cizí klíč, správnost hlídají pravidla),
- **čárkovaná šipka** = kopie dat nebo přidělení čísla.

### Jak se ukládá objednávka
Tady je vidět, k čemu slouží `orderNumbers/today` a co všechno kontrolují pravidla:

```mermaid
sequenceDiagram
    actor Z as Zákazník
    participant A as Aplikace
    participant P as Pravidla
    participant DB as Firestore
    actor O as Obsluha

    Z->>A: Objednat (stůl 4)
    A->>DB: transakce: přečti orderNumbers/today
    DB-->>A: last = 11, day = dnes
    A->>P: ulož last = 12 a objednávku č. 12
    Note over P: kód stolu sedí?<br/>číslo je z počítadla?<br/>čas je čas serveru?<br/>podnik má otevřeno?
    P->>DB: vše v pořádku, uložit
    DB-->>A: uloženo
    A-->>Z: Objednávka č. 12 přijata
    DB-->>O: nová objednávka se hned objeví
```

Transakce zaručí, že když objednají dva zákazníci ve stejnou chvíli, jeden dostane č. 12 a druhý č. 13. Nikdy ne oba stejné číslo.

### Kolekce

#### `users`: uživatelé
| Pole | Typ | Popis |
|---|---|---|
| `uid` | text (ID dokumentu) | ID účtu z Firebase Authentication |
| `name` | text | jméno |
| `email` | text | e-mail |
| `role` | text | `zakaznik` / `obsluha` / `admin` |
| `createdAt` | čas | kdy byl profil založen |

#### `categories`: kategorie menu
| Pole | Typ | Popis |
|---|---|---|
| `id` | text (ID dokumentu) | |
| `name` | text | např. Káva, Dezerty |
| `order` | číslo | pořadí v menu |

#### `products`: produkty
| Pole | Typ | Popis |
|---|---|---|
| `id` | text (ID dokumentu) | |
| `name` | text | název |
| `price` | číslo | cena v Kč |
| `categoryId` | text | **odkaz na kategorii** (cizí klíč) |
| `description` | text | popis |
| `available` | ano/ne | `false` = vyprodáno |

#### `orders`: objednávky
| Pole | Typ | Popis |
|---|---|---|
| `id` | text (ID dokumentu) | jedinečné ID objednávky |
| `number` | číslo | číslo pro lidi („dvanáctka je hotová“), každý den od 1 |
| `items` | seznam | položky objednávky (název, cena, kategorie, množství) |
| `totalPrice` | číslo | celková cena |
| `tableNumber` | číslo | **odkaz na stůl** |
| `tableCode` | text | tajný kód stolu z QR kódu |
| `status` | text | `prijata` / `pripravujeSe` / `pripravena` / `dokoncena` |
| `userId` | text | **odkaz na uživatele** |
| `customerName` | text | jméno zákazníka pro obsluhu |
| `createdAt` | čas | čas serveru |

#### `requests`: požadavky na obsluhu
| Pole | Typ | Popis |
|---|---|---|
| `id` | text (ID dokumentu) | `{uid}_{typ}`: každý zákazník má od každého typu jen jeden čekající požadavek (ochrana proti spamu) |
| `type` | text | `obsluha` / `platba` |
| `status` | text | `cekajici` / `vyrizeno` |
| `tableNumber`, `tableCode` | číslo, text | stůl a jeho tajný kód |
| `userId`, `customerName` | text | kdo požadavek poslal |
| `createdAt` | čas | |

#### `tables`: stoly
| Pole | Typ | Popis |
|---|---|---|
| `number` | číslo (ID dokumentu) | 1–10 |
| `code` | text | tajný kód, který je v QR kódu na stole |

#### `orderNumbers/today`: čísla objednávek (náhrada AUTO_INCREMENT)
| Pole | Typ | Popis |
|---|---|---|
| `last` | číslo | poslední přidělené číslo objednávky |
| `day` | číslo | den, ke kterému číslo patří (`YYYYMMDD`) |

V MySQL by objednávky dostávaly čísla 1, 2, 3… samy díky **AUTO_INCREMENT**. **Firestore nic takového nemá**: ID dokumentu je náhodný řetězec (např. `xK8f2mQa…`), který se obsluze špatně vyvolává. Proto si v tomto jediném dokumentu pamatuji poslední přidělené číslo:

1. zákazník odešle objednávku,
2. aplikace v **transakci** přečte `last`, zvýší ho o 1 a stejné číslo uloží do nové objednávky (`orders.number`),
3. když je nový den (`day` se liší od dneška), začne znovu od 1.

Transakce zaručí, že dva zákazníci objednávající ve stejnou chvíli nedostanou stejné číslo. Pravidla navíc hlídají, že číslo objednávky opravdu pochází z počítadla a že den se bere z hodin serveru.

#### `settings/venue`: nastavení podniku
Jediný dokument s tím, co **mění admin přímo v aplikaci**: `name`, `slogan`, `color`, `type`, `isOpen`, `announcement`, `address`, `openingHours`, `wifiName`, `wifiPassword`. Proč to není v konfiguračním souboru, vysvětluje kapitola [Konfigurace vs. databáze](#️-konfigurace-vs-databáze).

### Vztahy
- **uživatel 1 : N objednávky** (`orders.userId` → `users.uid`)
- **uživatel 1 : N požadavky** (`requests.userId` → `users.uid`)
- **kategorie 1 : N produkty** (`products.categoryId` → `categories.id`)
- **stůl 1 : N objednávky a požadavky** (`tableNumber` → `tables`)
- **objednávka 1 : N položky** (položky jsou vnořené přímo v objednávce)

### Rozdíly oproti relační databázi a proč
| Situace | Řešení v Brewly | Proč |
|---|---|---|
| **Položky objednávky** | vnořený seznam `items` v objednávce, s **kopií** názvu a ceny produktu | Záměrná **denormalizace**. Objednávka si pamatuje cenu v době nákupu, takže zdražení nebo smazání produktu nezmění historii ani tržby. Celá objednávka se navíc načte jedním čtením. |
| **Kategorie** | samostatná kolekce `categories`, produkt na ni odkazuje přes `categoryId` | **Normalizace**: název kategorie je uložený jen jednou. Přejmenování změní jediný dokument a nehrozí překlepy v názvech. |
| **Cizí klíče** | Firestore je sám nehlídá | Hlídají je **bezpečnostní pravidla**, např. produkt nejde uložit s neexistující kategorií a objednávka musí mít platný kód stolu. |
| **Pořadové číslo objednávky** (AUTO_INCREMENT) | dokument `orderNumbers/today` zvyšovaný v **transakci** | Dva zákazníci objednávající ve stejnou chvíli nikdy nedostanou stejné číslo. |

---

## 🔒 Zabezpečení

Pravidla v souboru [`firestore.rules`](firestore.rules) běží na serveru Firebase, takže je nejde obejít ani mimo aplikaci:

- **role:** zákazník si nemůže sám přidělit roli obsluhy nebo admina,
- **objednávky:** zákazník vytvoří objednávku jen sám za sebe, se správným **kódem stolu** a jen když má podnik otevřeno. Objednávka smí mít jen povolená pole, **číslo musí pocházet z počítadla** ve stejné transakci a **čas je čas serveru**,
- **stav objednávky** mění jen obsluha, a to jen o jeden krok dopředu (Přijata → Připravuje se → Připravena → Dokončena),
- **QR kódy:** tajné kódy stolů vidí jen obsluha. Kdo u stolu nesedí, nemůže k němu objednat ani přivolat obsluhu,
- **požadavky:** ochrana proti spamu, další požadavek jde poslat až po vyřízení předchozího,
- **menu a nastavení** mění jen admin. Obsluha smí přepnout jen Otevřeno / Zavřeno,
- **čísla objednávek** se nulují jen v opravdu novém dni podle hodin serveru,
- všechna data se kontrolují i **tvarem** (typy, délky textů, povolené hodnoty).

### Kontrola ceny objednávky
Cenu počítá aplikace v mobilu zákazníka. Bezpečnostní pravidla Firestore neumí projít seznam položek a sečíst je, takže úplnou kontrolu by musela dělat serverová funkce (**Cloud Functions**). Ta ale vyžaduje placený tarif Firebase. Proto:
- pravidla pohlídají, že cena je kladná, v rozumné výši a položek je rozumný počet,
- **obsluha u každé objednávky vidí výrazné upozornění**, když součet položek nesedí s celkovou cenou nebo když se cena položky liší od aktuálního menu,
- obsluha objednávku vždy předává osobně a platba probíhá u ní, takže podvod s cenou neprojde bez povšimnutí.

---

## 📁 Struktura projektu

```
lib/
├── main.dart            spuštění aplikace, napojení na Firebase, téma podle nastavení
├── config/              KONFIGURACE: počet stolů, palety, výchozí vzhled, limity
├── models/              datové třídy (Product, Order, Cart, VenueSettings…)
├── services/            práce s databází a přihlášením (ProductService, OrderService…)
├── screens/             obrazovky (menu, košík, obsluha, správa menu…)
├── widgets/             znovupoužitelné části obrazovek (karta produktu, okna…)
├── theme/               vzhled aplikace sestavený z vybrané palety
└── utils/               pomocné funkce (formátování cen, čtení CSV…)
test/                    automatické testy
docs/                    diagram databáze, ukázkové CSV menu
firestore.rules          bezpečnostní pravidla databáze
```

---

## 🚀 Spuštění projektu

Potřebuješ nainstalovaný [Flutter](https://docs.flutter.dev/get-started/install) a prohlížeč Chrome.

```bash
git clone https://github.com/klariiisek/Brewly.git
cd Brewly
flutter pub get
flutter run -d chrome
```

Aplikace se připojí k mému Firebase projektu. Pro vlastní projekt je potřeba nastavit Firebase přes `flutterfire configure` a nahrát pravidla příkazem `firebase deploy --only firestore:rules`.

**Zveřejnění na webu:**
```bash
flutter build web --release
firebase deploy --only hosting
```

---

## 🧪 Testy

```bash
flutter test
```

Projekt má **56 automatických testů** rozdělených do souborů podle témat (`menu_test`, `cart_order_test`, `auth_profile_test`, `staff_test`, `admin_test`, `settings_test`, `utils_test`). Používají falešnou databázi a falešné přihlášení v paměti (`fake_cloud_firestore`, `firebase_auth_mocks`), takže se při nich nic neukládá do skutečné databáze. Testují například:
- objednávku od menu přes košík až po stav u obsluhy,
- role (zákazník nevidí obsluhu, obsluha nevidí správu menu),
- čtení CSV souboru a hlášení chybných řádků,
- denní nulování čísel objednávek,
- zavřený podnik (nejde objednat),
- převod starých dat kategorií.

---

## 🗺️ Plánované funkce

- 🎟️ **razítková karta**: každá 10. káva zdarma,
- 💳 **volba platby** (kartou / hotově) a **sleva 3 % za platbu kartou**,
- 📊 **statistiky pro admina**: tržby, počet objednávek, nejprodávanější produkty,
- 🎨 **vlastní ikony nápojů** podle tvaru šálku a sklenice.

---

👩‍💻 **Autorka:** Klára Čechová, maturitní projekt
