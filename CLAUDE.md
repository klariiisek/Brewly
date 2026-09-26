# Brewly – projektový kontext a pokyny pro Claude

> **Účel tohoto souboru:** Předat Claudeovi co nejúplnější a praktický kontext o maturitním projektu Brewly, jeho současném stavu, dlouhodobém cíli, inspiracích a způsobu spolupráce s jeho autorkou.
>
> **Nejdůležitější pravidlo:** Neber tento dokument jako pokyn přepsat celý projekt. Pomáhej začátečnici postupně, srozumitelně a po malých krocích.

---

## 1. Rychlé shrnutí projektu

**Název:** Brewly  
**Typ:** maturitní závěrečný projekt  
**Technologie:** Flutter + Dart; Firebase je plánovaná další fáze  
**GitHub:** https://github.com/klariiisek/Brewly  
**Lokální cesta na počítači:** `C:\Users\klara\Projects\brewly`  
**Git branch:** `master`  
**Poslední známý commit:** `05fe456` – `Přidány stavy objednávky`

Brewly je aplikace pro kavárnu. Má propojit zákaznickou část s částí pro obsluhu. Zákazník si má prohlížet menu, vybírat produkty, objednávat ke stolu, sledovat stav objednávky, rezervovat stůl a využívat další funkce kavárny. Obsluha má mít vlastní rozhraní pro správu objednávek, jejich stavů a požadavků zákazníků.

Projekt se vyvíjí jako maturitní práce. Autorka se Flutter a Dart teprve učí, a proto je zásadní, aby rozuměla tomu, co v aplikaci vzniká. Nejde jen o to mít co nejrychleji hotový kód.

---

## 2. Pokyny pro Claude: jak se mnou pracovat

**Jsem začátečnice v programování, Flutteru a Dartu.** Prosím, pokračuj se mnou podobným způsobem, jako jsme dosud pracovali v ChatGPT.

### Zásady spolupráce

1. **Postupuj po středně velkých krocích.** Jeden krok má dokončit jednu malou, viditelnou funkci (např. „tlačítko, které změní stav objednávky“), i když to znamená úpravu 1–3 souborů. Nerozděluj ho zbytečně na mikrokroky, které samy o sobě nejdou vyzkoušet. Nedávej mi ale najednou celý velký systém nebo několik funkcí naráz.
2. Než začneme, krátce vysvětli, **co budeme dělat a proč**.
3. Vždy napiš přesnou cestu k souboru, který mám otevřít.
4. Uveď přesně, co mám najít, změnit, vložit nebo odstranit.
5. Vysvětli nové pojmy jednoduše a bez předpokladu, že je znám.

6. **Nepokračuj dál, dokud nepotvrdím, že krok funguje**, nebo dokud nevyřešíme případnou chybu.
7. Když je třeba upravit větší část souboru, nejprve si vyžádej jeho aktuální obsah, pokud ho nemáš ověřený.
8. Nehádej, jak aktuální soubor vypadá. Repository si nejprve prohlédni.
9.  Nepřepisuj fungující části aplikace bez jasného důvodu.
10. Nezaváděj zbytečně složitou architekturu ani další balíčky, pokud to současná fáze nepotřebuje.
11. Pokud existuje více řešení, vysvětli je jednoduše a začni přiměřeně jednoduchým řešením.
12. Když něco nefunguje, nejprve zjisti přesnou chybu a její příčinu. Neřeš ji náhodným přepisováním dalších souborů.
13. Rozlišuj mezi tím, co je skutečně hotové a ověřené, co je pouze plán a co je potřeba zkontrolovat.
14. Neříkej, že je něco otestované nebo funkční, pokud to nebylo skutečně ověřeno.
15. Mluv se mnou česky, přátelsky a srozumitelně.
16. Pomáhej mi chápat kód tak, abych ho dokázala vysvětlit u maturitní obhajoby.
17. Když je vhodné něco uložit na GitHub, nejprve mi vysvětli postup a nech mě potvrdit výsledek.

### Doporučený formát každého kroku

- **Cíl:** Co chceme získat.
- **Proč:** Jednoduché vysvětlení.
- **Soubor:** Přesná cesta (případně více souborů, pokud k funkci patří).
- **Úprava:** Konkrétní změny pro jednu funkci. Pokud se mění velká část souboru, klidně dej celý nový obsah souboru.
- **Ověření:** Co mám spustit nebo zkontrolovat.
- Poté počkej na mou odpověď.

Prosím, nezahlcuj mě dlouhými návody, když stačí jeden konkrétní krok. Krok má být tak velký, aby byl na konci vidět výsledek v aplikaci. Podrobnější vysvětlení mi dej, když si o něj řeknu nebo když je opravdu důležité pro pochopení.

---

## 3. Hlavní vize Brewly

Cílem je vytvořit přehlednou a funkční aplikaci pro kavárnu, která bude mít zákaznickou a obslužnou část.

### Zákaznická část – plánované funkce

- Prohlížení nabídky kavárny.
- Kategorie produktů.
- Detail produktu.
- Přidávání produktů do košíku.
- Změna množství a odebírání položek.
- Výpočet ceny.
- Vytvoření objednávky.
- Objednání ke konkrétnímu stolu.
- QR kód pro identifikaci stolu.
- Sledování stavu objednávky.
- Historie objednávek a detail objednávky.
- Přivolání obsluhy.
- Požadavek „Chci zaplatit“.
- Rezervace stolu.
- Oblíbené produkty.
- Věrnostní systém / body.
- Registrace a přihlášení.
- Přihlášení přes e-mail a heslo i Google.
- Ověření e-mailu, zapomenuté heslo a odhlášení.
- Případně notifikace a tmavý režim.

### Obslužná část – plánované funkce

- Přehled příchozích objednávek.
- Detail objednávky a informace o stole.
- Změna stavu objednávky.
- Přehled požadavků na přivolání obsluhy.
- Přehled požadavků „Chci zaplatit“.
- Správa rezervací.
- Podle potřeby další funkce pro obsluhu nebo administraci.

### Plánované role

- Návštěvník.
- Zákazník.
- Obsluha.

Každá role bude mít jiné možnosti. Konkrétní oprávnění je potřeba navrhnout postupně a později bezpečně vynutit také na backendu.

### Platby

**Neplánujeme skutečné online platby.** Funkce „Chci zaplatit“ má pouze upozornit obsluhu, že zákazník chce zaplatit u stolu.

---

## 4. Technologie a plánované služby

### Používané technologie

- Flutter
- Dart

### Plánované technologie a služby

- Firebase Authentication – registrace a přihlašování.
- Cloud Firestore – databáze uživatelů, produktů, objednávek, rezervací a dalších dat.
- Firebase Storage – případné obrázky produktů a soubory.
- Google Sign-In – přihlášení přes Google.
- QR kódy – identifikace stolů.
- Firebase Cloud Messaging – případné notifikace, pokud budou potřeba.

Firebase zatím není zapojený do aktuálního prototypu. Plán je nejprve pochopit základní logiku lokálně a potom ji postupně přenést do Firebase. Nezačínej s Firebase automaticky, pokud právě řešíme lokální funkci.

---

## 5. Vývojové prostředí

Projekt je na počítači ve složce:

```text
C:\Users\klara\Projects\brewly
```

Aplikace se nyní spouští v Chrome.

Příkaz:

```bash
flutter run -d chrome
```

Běžící aplikaci není nutné při každé změně vypínat. V terminálu, kde běží Flutter:

- `r` – Hot Reload.
- `R` – Hot Restart.
- `q` – ukončení běhu aplikace.

Uložení souboru přes `Ctrl + S` obvykle změnu načte automaticky. Některé strukturální změny mohou vyžadovat restart nebo nové spuštění.

Pokud se aplikace po změně znovu načítá, vysvětli stručně, že některé změny mohou vyžadovat restart. Nevyžaduj zbytečně nové `flutter run`, pokud běžící proces stále funguje.

---

## 6. GitHub a zálohování

Repository:

https://github.com/klariiisek/Brewly

Remote:

```text
git@github.com:klariiisek/Brewly.git
```

Branch:

```text
master
```

GitHub je nastavený přes SSH a projekt se na něj úspěšně pushuje.

Poslední známý commit:

```text
05fe456 Přidány stavy objednávky
```

Tento commit byl úspěšně odeslán na GitHub.

### Obvyklý postup po dokončení funkční části

Nejprve:

```bash
git status
```

Potom:

```bash
git add .
git commit -m "Stručný popis změny"
git push
```

Vysvětli mi, co jednotlivé příkazy dělají. Před většími změnami je vhodné mít funkční commit jako bod návratu.

Nikdy nepožaduj ani nevkládej do dokumentace nebo repozitáře privátní SSH klíče, hesla, tokeny či jiné tajné údaje.

---

## 7. Dosavadní práce – co už aplikace umí

Následující funkce byly během dosavadního vývoje vytvořeny a ručně ověřeny v aplikaci. Před dalšími zásahy je ale vždy možné stav ověřit proti aktuálnímu GitHubu.

### Úvodní obrazovka

- Úvodní obrazovka s názvem Brewly.
- Uvítací text.
- Tlačítko pro otevření menu.
- Tlačítko pro přihlášení je zatím pouze součástí základního rozhraní; kompletní autentizace ještě není hotová.

### Menu

- Seznam produktů.
- Produkty mají název, cenu a kategorii.
- Příklady produktů: Espresso, Cappuccino, Latte, Cheesecake, Tiramisu a domácí limonáda.
- Kliknutím na produkt se otevře detail produktu.

### Detail produktu

- Zobrazuje název, kategorii a cenu.
- Obsahuje tlačítko „Přidat do košíku“.
- Po přidání se zobrazí potvrzovací SnackBar.

### Košík

- Produkty se přidávají do košíku.
- Opakované přidání stejného produktu zvyšuje jeho množství místo vytvoření další samostatné položky.
- Množství lze zvýšit nebo snížit.
- Při snížení množství z 1 se položka odstraní.
- Zobrazuje se cena položky a celková cena.
- Prázdný košík nesmí vytvořit objednávku.
- Po vytvoření objednávky se košík vyprázdní.

### Objednávky a historie

- Objednávka obsahuje položky, celkovou cenu a stav.
- Objednávky se ukládají do lokální historie v paměti aplikace.
- Historie zobrazuje více objednávek.
- Z historie lze otevřít detail objednávky.
- Detail zobrazuje jednotlivé položky, množství a ceny.
- Stav objednávky se zobrazuje česky.

### Důležitá oprava historie

Původně se `OrderHistory` vytvářela přímo ve `CartScreen`. Při návratu na obrazovku tak vznikla nová historie a starší objednávky se ztrácely z pohledu obrazovky.

Oprava: `OrderHistory` je nyní součástí stejného objektu `Cart` a používá se přes `widget.cart.orderHistory`.

Tím se během běhu aplikace zachovává více objednávek.

---

## 8. Aktuální datové modely a důležité soubory

Aktuální známá struktura:

```text
lib/
├── models/
│   ├── product.dart
│   ├── cart_item.dart
│   ├── cart.dart
│   ├── order.dart
│   └── order_history.dart
│
└── screens/
    ├── home_screen.dart
    ├── menu_screen.dart
    ├── product_detail_screen.dart
    ├── cart_screen.dart
    ├── order_history_screen.dart
    └── order_detail_screen.dart
```

Kromě toho existují standardní Flutter soubory, například `lib/main.dart`, `pubspec.yaml`, složky `test/`, `web/`, `android/` a další.

### `product.dart`

Datový model produktu. Produkt má název, cenu a kategorii.

### `cart_item.dart`

Položka košíku. Obsahuje produkt a množství.

### `cart.dart`

Košík:

- seznam položek
- přidávání položek
- slučování stejného produktu
- výpočet celkové ceny
- objekt `OrderHistory`

### `order.dart`

Objednávka a její stav. Podrobnosti jsou níže.

### `order_history.dart`

Seznam objednávek a metoda pro přidání objednávky.

### `home_screen.dart`

Úvodní obrazovka aplikace.

### `menu_screen.dart`

Zobrazení menu a navigace do detailu produktu a košíku. V současném jednoduchém řešení vytváří objekt `Cart` a předává ho dalším obrazovkám.

### `product_detail_screen.dart`

Detail produktu a tlačítko pro přidání do košíku.

### `cart_screen.dart`

Košík, změna množství, výpočet ceny a vytvoření objednávky.

### `order_history_screen.dart`

Historie objednávek.

### `order_detail_screen.dart`

Detail objednávky.

---

## 9. Aktuální stav `OrderStatus`

V `lib/models/order.dart` je definovaný enum:

```dart
enum OrderStatus {
  prijata,
  pripravujeSe,
  pripravena,
  dokoncena,
}
```

Pro zobrazení českého názvu je vytvořená funkce:

```dart
String orderStatusText(OrderStatus status) {
  switch (status) {
    case OrderStatus.prijata:
      return 'Přijata';
    case OrderStatus.pripravujeSe:
      return 'Připravuje se';
    case OrderStatus.pripravena:
      return 'Připravena';
    case OrderStatus.dokoncena:
      return 'Dokončena';
  }
}
```

Model `Order` má podle posledního známého stavu:

```dart
class Order {
  final List<CartItem> items;
  final double totalPrice;
  OrderStatus status;

  Order({
    required this.items,
    required this.totalPrice,
    required this.status,
  });
}
```

Všimni si, že `status` **není `final`**. To bylo záměrné, protože chceme později stav měnit.

Při vytváření objednávky se aktuálně nastavuje:

```dart
status: OrderStatus.prijata,
```

V historii se stav vypisuje přes:

```dart
orderStatusText(order.status)
```

a na detailu objednávky se zobrazuje například:

```text
Stav: Přijata
```

---

## 10. Kde jsme přesně skončili

**Poslední ověřený stav:** V historii a detailu objednávky se zobrazuje český stav `Přijata`. Enum se správně používá místo obyčejného textového řetězce.

Poslední známý commit na GitHubu:

```text
05fe456 Přidány stavy objednávky
```

### Nejbližší plánovaný krok

Chceme umožnit změnu stavu objednávky:

```text
Přijata → Připravuje se → Připravena → Dokončena
```

Zatím lokálně a jednoduše, abychom pochopily logiku. Později bude stav měnit obsluha a zákazník uvidí změnu.

**Nezačínej hned vytvářet celou staff část.** Nejprve malým krokem ověřme, že stav lze změnit a správně zobrazit. Pak můžeme pokračovat k obsluze.

Poznámka: Před pokračováním si ověř aktuální soubory na GitHubu. Tento dokument popisuje poslední známý stav, ale repository může být mezitím změněné.

---

## 11. Důležitá omezení současného prototypu

- Data jsou zatím v paměti aplikace.
- Po úplném restartu aplikace se košík i historie mohou ztratit.
- Objednávky zatím nejsou synchronizované s jiným zařízením ani s obsluhou.
- Firebase není zapojený.
- Přihlášení, role, rezervace, QR stoly, obsluha a věrnostní systém ještě nejsou kompletně implementované.
- Vzhled je zatím jednoduchý a bude se později zlepšovat.

Nevydávej tyto plánované funkce za hotové.

---

## 12. Inspirace z jiných maturitních projektů

Autorka chce, aby se Brewly inspirovalo rozsahem, organizací a nápady z následujících veřejných projektů. **Inspirace neznamená kopírování jejich kódu, grafiky ani textů.** Brewly zůstává vlastním projektem pro kavárnu.

Při práci s odkazy nejprve ověř aktuální README a strukturu repository. Následující poznámky jsou orientační a vycházejí z dosud známých informací o projektech.

### 12.1 Ales Vcelka – MaturitniProjekt

https://github.com/alesvcelka1/MaturitniProjekt

Známá inspirace: Flutter + Firebase fitness aplikace, autentizace, Firestore, Storage, role trenér/klient a případné statistiky.

Co může být užitečné pro Brewly:

- přihlášení a role
- oddělené funkce pro různé typy uživatelů
- ukládání dat přes Firebase
- přehledná struktura funkcí
- případné statistiky v budoucnu

### 12.2 TrenApp

https://github.com/matejko4/TrenApp

Známá inspirace: Flutter + Firebase, přihlášení e-mailem/heslem a Google, role trenér/hráč, plány a komunikace.

Co může být užitečné:

- e-mailová autentizace
- Google Sign-In
- role a rozdílná oprávnění
- rozdělení zákaznické a obslužné části
- případná komunikace mezi rolemi

### 12.3 Flyte fitness app – frontend-mat

https://github.com/vmazurova/frontend-mat

Repository může být přesměrované na jiné jméno. Ověř aktuální obsah odkazu.

Známá inspirace: webový maturitní projekt s funkcemi jako rezervace, uživatelský účet, trenéři, administrace a další plánovací funkce.

Co může být užitečné:

- rezervace
- účet uživatele
- administrativní/staff část
- rozdělení aplikace do přehledných částí
- inspirace rozsahem funkcí

Brewly ale zůstává Flutter aplikací. Nekopíruj technologický stack tohoto projektu.

### 12.4 RepTrack

https://github.com/RicnyF/Maturitni-projekt-RepTrack

Známá inspirace: Flutter + Firebase aplikace pro tréninky, rutiny, statistiky, profily, administraci a nastavení.

Co může být užitečné:

- organizace dat
- profily a nastavení
- administrátorská část
- případné statistiky
- dokumentace maturitního projektu

### 12.5 Hockey App

https://github.com/Ejdmoss/HOCKEY_APP

Známá inspirace: Flutter + Firebase + REST API aplikace pro hokejové fanoušky, s přehledy lig, týmů, hráčů, historií a oblíbenými položkami.

Co může být užitečné:

- oblíbené položky
- přehledné seznamy a detailní obrazovky
- personalizace
- případná inspirace pro budoucí práci s externím API

### Jak s inspiracemi zacházet

- Používej je pro inspiraci funkčností, rozsahem, strukturou a dokumentací.
- Při konkrétním návrhu se podívej na aktuální README a kód, pokud je dostupný.
- Rozlišuj mezi ověřeným faktem a pouhým nápadem.
- Nekopíruj cizí zdrojový kód, grafiku ani texty.
- Nepřidávej do Brewly funkce jen proto, že je má jiný projekt. Vždy vysvětli, jakou hodnotu by měly pro kavárnu a zda jsou realistické pro maturitní práci.

---

## 13. Doporučený dlouhodobý plán

Toto je orientační plán, nikoli seznam úkolů k okamžité implementaci. Pořadí se může upravit podle toho, co se při vývoji ukáže jako vhodné.

### Fáze A – lokální základ
- menu a produkty
- detail produktu
- košík
- objednávky
- historie
- stav objednávky

### Fáze B – objednávky a obsluha
- změna stavu objednávky
- jednoduchá staff obrazovka
- přehled objednávek pro obsluhu
- detail objednávky
- informace o stole

### Fáze C – UX a vzhled
- lepší navigace
- vizuální sjednocení
- přehlednější produktové karty
- kategorie
- prázdné a chybové stavy
- potvrzovací dialogy

### Fáze D – účty a role
- registrace
- přihlášení e-mailem a heslem
- Google Sign-In
- odhlášení
- zapomenuté heslo
- ověření e-mailu
- role návštěvník/zákazník/obsluha

### Fáze E – Firebase
- Firebase Authentication
- Cloud Firestore
- případně Storage
- bezpečnostní pravidla
- postupná migrace lokálních dat na databázi

### Fáze F – kavárenské funkce
- QR kódy stolů
- rezervace
- přivolání obsluhy
- „Chci zaplatit“
- oblíbené produkty
- věrnostní body
- případně notifikace

### Fáze G – stabilizace a zabezpečení
- validace
- zpracování chyb
- testování
- ošetření okrajových situací
- bezpečnostní pravidla
- přístupová práva
- kontrola uživatelského prostředí

### Fáze H – dokumentace a obhajoba
- README
- technická dokumentace
- popis architektury
- databázový návrh
- popis Firebase
- bezpečnost
- testování
- screenshoty
- prezentace
- příprava na maturitní obhajobu

---

## 14. Bezpečnost, kvalita a testování

Bezpečnost a stabilita se mají řešit průběžně, ne až na konci.

Postupně mysli na:

- validaci uživatelských vstupů
- správné ošetření chyb
- prázdné stavy a neplatné hodnoty
- ochranu dat
- Firebase Authentication
- Firestore Security Rules
- oddělení práv zákazníka a obsluhy
- testování hlavních scénářů
- kontrolu neobvyklých situací
- stabilizaci před odevzdáním

Nikdy neslibuj, že aplikace bude stoprocentně bez chyb. Cílem je chyby minimalizovat, správně ošetřit očekávané problémy a ověřit funkčnost.

---

## 15. Design a uživatelský dojem

Současný vzhled je jednoduchý. To je v této fázi v pořádku: nejdříve jsme budovaly logiku a funkčnost.

Později chceme vytvořit ucelený kavárenský vzhled:

- vhodnou barevnou paletu
- čitelnou typografii
- hezké produktové karty
- produktové fotografie
- kvalitní tlačítka a ikony
- přehlednou navigaci
- příjemné prázdné stavy
- případně tmavý režim a drobné animace

Při návrhu vzhledu mysli na to, že jde o aplikaci kavárny, ale grafiku nepřekopávej při každé funkční změně. Vhodné bude později sjednotit vzhled centrálně pomocí Flutter Theme.

---

## 16. Co je důležité pro maturitní obhajobu

Projekt má být nejen funkční, ale také srozumitelný své autorce.

Pomáhej mi postupně pochopit:

- co je widget a widget tree
- jak funguje navigace
- jak fungují datové modely
- jak se předávají objekty mezi obrazovkami
- jak se spravuje stav
- jak funguje košík a objednávka
- jak bude fungovat databáze
- co řeší Firebase Authentication
- co řeší Firestore
- jak se nastavují role a oprávnění
- proč jsou důležitá bezpečnostní pravidla
- jak se aplikace testuje
- jak vysvětlit architekturu projektu

Když vytvoříš důležitou funkci, můžeš mi na konci stručně říct, jak bych ji mohla vlastními slovy vysvětlit u obhajoby. Nedělej z každého kroku dlouhou přednášku.

---

## 17. Jak pracovat s repository

Při prvním otevření projektu:

1. Projdi GitHub repository: https://github.com/klariiisek/Brewly
2. Přečti tento dokument.
3. Porovnej dokument s aktuálním kódem.
4. Pokud se něco liší, upozorni na to a uveď, co je aktuálně v kódu.
5. **Zatím nic neměň.**
6. Stručně shrň, co je hotové a kde jsme skončili.

Při další práci:

- měň pouze to, co souvisí s aktuálním úkolem
- zachovávej funkční části
- nevymýšlej soubory nebo metody, které jsi neověřil
- pokud je potřeba, vyžádej si aktuální soubor
- před rozsáhlou změnou vysvětli plán
- neprováděj destruktivní příkazy bez výslovného souhlasu
- nepřepisuj historii Git ani nemaž soubory bez vysvětlení a souhlasu
- po dokončení nech uživatelku aplikaci otestovat
- doporuč commit až ve chvíli, kdy je krok funkční

Pokud máš možnost přímo měnit repository, neprováděj velký automatický commit nebo rozsáhlý refaktor bez toho, abych rozuměla tomu, co se mění.

---

## 18. Jak řešit chyby

Když nahlásím chybu:

1. Nejdříve zjisti přesné znění chyby a soubor/řádek, kde vzniká.
2. Pokud chybí kontext, požádej mě o chybovou hlášku nebo aktuální obsah souboru.
3. Vysvětli příčinu jednoduchými slovy.
4. Navrhni nejmenší opravu.
5. Nech mě změnu uložit a aplikaci znovu spustit.
6. Ověř, zda chyba zmizela, než začneš s další funkcí.

Neskrývej chybu tím, že bez vysvětlení přepíšeš další nesouvisející části.

---

## 19. Co nedělat

- Neimplementuj celý projekt najednou.
- Nepřidávej Firebase do každého kroku jen proto, že je v plánu.
- Nezačínej složitou architekturou.
- Nepřidávej zbytečné knihovny bez vysvětlení.
- Neprováděj rozsáhlý refaktor bez důvodu.
- Nepředpokládej, že uživatelka zná odborné termíny.
- Nezaměňuj plánované funkce za hotové.
- Nevydávej inspiraci za vlastní práci Brewly.
- Nezkopíruj cizí projekt.
- Neslibuj nulovou chybovost.
- Nezahltit uživatelku příliš mnoha úkoly najednou.

---

## 20. První zpráva v novém Claude Projectu

Po připojení GitHubu a vložení tohoto dokumentu může uživatelka poslat tuto zprávu:

> Ahoj, tohle je můj maturitní projekt Brewly. Prosím, nejdříve si projdi repository na GitHubu a celý soubor `CLAUDE_CONTEXT.md`. Zatím nic neměň a negeneruj žádný nový kód.
>
> Jsem začátečnice ve Flutteru a Dartu. Chci, abys se mnou pracoval po jednom malém kroku, vysvětloval mi, co děláme a proč, vždy uváděl přesný soubor a nechal mě každou změnu otestovat.
>
> Nejdříve porovnej dokument se skutečným stavem repository. Pak mi česky a stručně potvrď:
> 1. co Brewly je,
> 2. co už podle kódu skutečně funguje,
> 3. kde jsme skončili,
> 4. jaký je nejbližší malý krok.
>
> Pokud se dokument a repository liší, upozorni mě na rozdíl a vycházej z aktuálního kódu. Zatím nic neupravuj.

---

## 21. Shrnutí

Brewly je vlastní maturitní aplikace pro kavárnu ve Flutteru a Dartu. Aktuálně má lokální menu, produkty, detail produktu, košík, vytváření objednávek, historii, detail objednávky a základní stavy objednávky. Dalším plánovaným krokem je umožnit změnu stavu objednávky a postupně vybudovat obslužnou část. Později se přidají účty, role, Firebase, QR stoly, rezervace a další funkce.

**Claude má být trpělivý průvodce, ne automatický generátor celého projektu.** Pomáhej mi po malých krocích, vysvětluj mi důvody, ověřuj každou změnu a pomáhej mi vytvořit aplikaci, které opravdu rozumím a kterou dokážu obhájit u maturity.
