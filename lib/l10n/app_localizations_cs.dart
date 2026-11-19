// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get languageName => 'Čeština';

  @override
  String get otherLanguageName => 'English';

  @override
  String get changeLanguage => 'Změnit jazyk';

  @override
  String get language => 'Jazyk';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Zrušit';

  @override
  String get save => 'Uložit';

  @override
  String get saving => 'Ukládám…';

  @override
  String get show => 'Zobrazit';

  @override
  String get remove => 'Odebrat';

  @override
  String get total => 'Celkem';

  @override
  String get checkConnection => 'Zkontrolujte připojení k internetu.';

  @override
  String get today => 'dnes';

  @override
  String get tomorrow => 'zítra';

  @override
  String dayAtTime(String day, String time) {
    return '$day v $time';
  }

  @override
  String tableTitle(int table) {
    return 'Stůl $table';
  }

  @override
  String tableLower(int table) {
    return 'stůl $table';
  }

  @override
  String get table => 'Stůl';

  @override
  String get enterTableCode => 'Zadat kód stolu';

  @override
  String get goToMenu => 'Přejít do menu';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count položek',
      few: '$count položky',
      one: '1 položka',
    );
    return '$_temp0';
  }

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count osob',
      few: '$count osoby',
      one: '1 osoba',
    );
    return '$_temp0';
  }

  @override
  String stampCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count razítek',
      few: '$count razítka',
      one: '1 razítko',
    );
    return '$_temp0';
  }

  @override
  String get signInToReserve => 'Pro rezervaci se prosím přihlaste';

  @override
  String get signedOut => 'Byli jste odhlášeni';

  @override
  String welcomeUser(String name) {
    return 'Vítejte, $name';
  }

  @override
  String get open => 'Otevřeno';

  @override
  String get closed => 'Zavřeno';

  @override
  String get browseMenu => 'Prohlédnout menu';

  @override
  String get reserveTable => 'Rezervovat stůl';

  @override
  String get signIn => 'Přihlásit se';

  @override
  String get signOut => 'Odhlásit se';

  @override
  String get venueInfo => 'Informace o podniku';

  @override
  String orderReady(int number) {
    return 'Vaše objednávka č. $number je připravená!';
  }

  @override
  String get signInForFavorites => 'Pro oblíbené produkty se prosím přihlaste';

  @override
  String get favoritesSaveFailed => 'Oblíbené se nepodařilo uložit';

  @override
  String get navMenu => 'Menu';

  @override
  String get navCart => 'Košík';

  @override
  String get navOrders => 'Objednávky';

  @override
  String get navProfile => 'Profil';

  @override
  String get categoryAll => 'Vše';

  @override
  String get categoryFavorites => 'Oblíbené';

  @override
  String get goodMorning => 'Dobré ráno';

  @override
  String get goodDay => 'Dobrý den';

  @override
  String get goodEvening => 'Dobrý večer';

  @override
  String get menuLoadFailed => 'Menu se nepodařilo načíst';

  @override
  String get menuEmpty => 'Menu je zatím prázdné';

  @override
  String get menuEmptyHint => 'Obsluha ho brzy doplní.';

  @override
  String get toCart => 'Do košíku';

  @override
  String get closedBanner =>
      'Teď máme zavřeno. Menu si můžete prohlédnout, objednat ale zatím nejde.';

  @override
  String get whatWillYouHave => 'Co si dnes dáte?';

  @override
  String tableWhatWillYouHave(int table) {
    return 'Stůl $table · Co si dnes dáte?';
  }

  @override
  String get addToFavorites => 'Přidat do oblíbených';

  @override
  String get removeFromFavorites => 'Odebrat z oblíbených';

  @override
  String get addToCart => 'Přidat do košíku';

  @override
  String get soldOut => 'Vyprodáno';

  @override
  String get decreaseQuantity => 'Snížit množství';

  @override
  String get increaseQuantity => 'Zvýšit množství';

  @override
  String addToCartPrice(String price) {
    return 'Přidat do košíku · $price';
  }

  @override
  String get currentlySoldOut => 'Momentálně vyprodáno';

  @override
  String get statusReceived => 'Přijata';

  @override
  String get statusPreparing => 'Připravuje se';

  @override
  String get statusReady => 'Připravena';

  @override
  String get statusDone => 'Dokončena';

  @override
  String get progressReceived => 'Objednávku jsme přijali';

  @override
  String get progressPreparing => 'Připravujeme vaši objednávku…';

  @override
  String get progressReady => 'Hotovo! Za chvíli ji máte na stole 🎉';

  @override
  String get progressDone => 'Dobrou chuť! 🙌';

  @override
  String get whichTable => 'U kterého stolu sedíte?';

  @override
  String get tableCodeHint =>
      'Naskenujte QR kód na stole fotoaparátem, nebo opište kód, který je pod ním.';

  @override
  String get tableCodeLabel => 'Kód stolu (např. 4-K7P2X9)';

  @override
  String get tableCodeFormat => 'Kód má tvar číslo stolu, pomlčka a 6 znaků';

  @override
  String get confirmTable => 'Potvrdit stůl';

  @override
  String get nowOpen => '● Teď máme otevřeno';

  @override
  String get nowClosed => '● Teď máme zavřeno';

  @override
  String get noVenueInfo => 'Podnik zatím nevyplnil žádné informace.';

  @override
  String get address => 'Adresa';

  @override
  String get openingHours => 'Otevírací doba';

  @override
  String get closedDay => 'zavřeno';

  @override
  String todayHours(String hours) {
    return 'Dnes $hours';
  }

  @override
  String get closedToday => 'Dnes zavřeno';

  @override
  String wifiPassword(String password) {
    return 'Heslo: $password';
  }

  @override
  String get copyPassword => 'Zkopírovat heslo';

  @override
  String get passwordCopied => 'Heslo zkopírováno';

  @override
  String get googleSignedIn => 'Přihlášení přes Google proběhlo úspěšně';

  @override
  String get or => 'nebo';

  @override
  String get signingIn => 'Přihlašuji…';

  @override
  String get continueWithGoogle => 'Pokračovat přes Google';

  @override
  String get resPending => 'Čeká na potvrzení';

  @override
  String get resConfirmed => 'Potvrzena';

  @override
  String get resDeclined => 'Odmítnuta';

  @override
  String get resCancelled => 'Zrušena';

  @override
  String get loyaltyCard => 'Razítková karta';

  @override
  String loyaltyRule(String category, String goal) {
    return 'Za každý kus z kategorie $category jedno razítko. Každý $goal. kus máte zdarma.';
  }

  @override
  String loyaltyReady(String goal) {
    return '🎉 $goal. kus máte zdarma! Uplatníte ho v košíku.';
  }

  @override
  String loyaltyMissing(String stamps, String goal) {
    return 'Ještě $stamps a $goal. kus máte zdarma.';
  }

  @override
  String get closedCannotOrder => 'Teď máme zavřeno, objednat zatím nejde';

  @override
  String get removeSoldOutFirst =>
      'Nejdřív odeberte z košíku vyprodané produkty';

  @override
  String get signInToOrder => 'Pro objednání se prosím přihlaste';

  @override
  String get orderSent => 'Objednávka byla odeslána';

  @override
  String get rewardFailed =>
      'Odměnu se nepodařilo uplatnit, razítková karta se mezitím změnila. Zkuste to prosím znovu.';

  @override
  String get orderDenied =>
      'Objednávku se nepodařilo odeslat. Naskenujte prosím QR kód na stole znovu a zkontrolujte, že máte v telefonu správné datum a čas.';

  @override
  String get orderFailed => 'Objednávku se nepodařilo odeslat';

  @override
  String get cartEmpty => 'Košík je prázdný';

  @override
  String get cartEmptyHint => 'Vyberte si něco dobrého z menu.';

  @override
  String get noLongerOffered => 'Už není v nabídce – odeberte ji';

  @override
  String get soldOutRemove => 'Vyprodáno – odeberte z košíku';

  @override
  String get previewOnly =>
      'Náhled pro obsluhu a admina – objednávat mohou jen zákazníci.';

  @override
  String get closedCannotOrderDot => 'Teď máme zavřeno, objednat zatím nejde.';

  @override
  String get soldOutInCart =>
      'V košíku je vyprodaný produkt. Odeberte ho, prosím.';

  @override
  String get sending => 'Odesílám…';

  @override
  String get placeOrder => 'Objednat';

  @override
  String rewardFree(String name, String discount) {
    return '$name zdarma  −$discount';
  }

  @override
  String loyaltyProgress(String filled, String needed, String missing) {
    return 'Razítková karta: $filled/$needed – do odměny zbývá $missing';
  }

  @override
  String get loyaltyFullHint =>
      'Máte plnou razítkovou kartu! Přidejte si něco z menu a bude to zdarma.';

  @override
  String useReward(String name) {
    return 'Uplatnit odměnu: $name zdarma';
  }

  @override
  String get myOrders => 'Moje objednávky';

  @override
  String get signInTitle => 'Přihlaste se';

  @override
  String get signInForOrders => 'Po přihlášení tu uvidíte své objednávky.';

  @override
  String get ordersLoadFailed => 'Objednávky se nepodařilo načíst';

  @override
  String get noOrdersYet => 'Zatím nemáte žádné objednávky';

  @override
  String get ordersAppearHere => 'Vaše objednávky se zobrazí tady.';

  @override
  String orderNumber(int number) {
    return 'Objednávka #$number';
  }

  @override
  String orderSummary(String date, int table, String items) {
    return '$date • Stůl $table • $items';
  }

  @override
  String get order => 'Objednávka';

  @override
  String get orderLoadFailed => 'Objednávku se nepodařilo načíst';

  @override
  String get orderNotFound => 'Objednávka nenalezena';

  @override
  String get orderNotFoundHint => 'Tato objednávka už v databázi není.';

  @override
  String tableAndDate(int table, String date) {
    return 'Stůl $table • $date';
  }

  @override
  String get loyaltyReward => 'Odměna z razítkové karty';

  @override
  String get billComing => 'Obsluha za vámi přijde s účtem';

  @override
  String get staffComing => 'Obsluha za vámi brzy přijde';

  @override
  String get requestDenied =>
      'Obsluha o vás už ví, nebo kód stolu neplatí. Případně naskenujte QR kód na stole znovu.';

  @override
  String get requestFailed => 'Požadavek se nepodařilo odeslat';

  @override
  String get needAnything => 'Potřebujete něco?';

  @override
  String get callStaff => 'Přivolat obsluhu';

  @override
  String get wantToPay => 'Chci zaplatit';

  @override
  String get closedNoCall =>
      'Teď máme zavřeno, obsluhu nejde přivolat. Zaplatit můžete.';

  @override
  String get staffKnows => 'Obsluha o vás ví…';

  @override
  String get welcomeBack => 'Vítejte zpět!';

  @override
  String get fillEmailFirst => 'Nejdřív vyplňte e-mail';

  @override
  String get resetSent =>
      'Pokud k e-mailu existuje účet, poslali jsme odkaz pro nové heslo';

  @override
  String get loginTitle => 'Přihlášení';

  @override
  String get loginSubtitle => 'Přihlaste se a objednávejte přímo ke stolu.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Heslo';

  @override
  String get fillPassword => 'Vyplňte heslo';

  @override
  String get forgotPassword => 'Zapomenuté heslo?';

  @override
  String get noAccount => 'Nemáte účet?';

  @override
  String get goToRegister => 'Zaregistrujte se';

  @override
  String get fillEmail => 'Vyplňte e-mail';

  @override
  String get emailInvalid => 'E-mail nemá správný tvar';

  @override
  String get accountCreated => 'Účet byl vytvořen. Vítejte!';

  @override
  String get registerTitle => 'Registrace';

  @override
  String get registerSubtitle => 'Vytvořte si účet a sledujte své objednávky.';

  @override
  String get name => 'Jméno';

  @override
  String get fillName => 'Vyplňte jméno';

  @override
  String get passwordMin => 'Heslo (alespoň 6 znaků)';

  @override
  String get passwordTooShort => 'Heslo musí mít alespoň 6 znaků';

  @override
  String get passwordAgain => 'Heslo znovu';

  @override
  String get passwordsDontMatch => 'Hesla se neshodují';

  @override
  String get creatingAccount => 'Vytvářím účet…';

  @override
  String get signUp => 'Zaregistrovat se';

  @override
  String get changePassword => 'Změnit heslo';

  @override
  String get currentPassword => 'Současné heslo';

  @override
  String get enterCurrentPassword => 'Zadejte současné heslo';

  @override
  String get newPassword => 'Nové heslo';

  @override
  String get atLeast6 => 'Alespoň 6 znaků';

  @override
  String get samePassword => 'Nové heslo je stejné jako současné';

  @override
  String get newPasswordAgain => 'Nové heslo znovu';

  @override
  String get showPasswords => 'Zobrazit hesla';

  @override
  String get authInvalidEmail => 'E-mail nemá správný tvar.';

  @override
  String get authWrongCredentials => 'Špatný e-mail nebo heslo.';

  @override
  String get authRecentLogin =>
      'Z bezpečnostních důvodů se prosím odhlaste a znovu přihlaste.';

  @override
  String get authEmailInUse => 'Účet s tímto e-mailem už existuje.';

  @override
  String get authWeakPassword => 'Heslo je příliš slabé (alespoň 6 znaků).';

  @override
  String get authNoInternet => 'Chybí připojení k internetu.';

  @override
  String get authTooManyRequests =>
      'Příliš mnoho pokusů. Zkuste to prosím později.';

  @override
  String get authPopupBlocked =>
      'Prohlížeč zablokoval okno pro přihlášení. Povolte vyskakovací okna a zkuste to znovu.';

  @override
  String get authOtherProvider =>
      'Účet s tímto e-mailem už používá jiný způsob přihlášení.';

  @override
  String get authNotEnabled =>
      'Tento způsob přihlášení není ve Firebase zapnutý.';

  @override
  String get authUnauthorizedDomain =>
      'Tato adresa není ve Firebase povolená pro přihlášení.';

  @override
  String get authUnknown => 'Něco se pokazilo. Zkuste to prosím znovu.';

  @override
  String get changeName => 'Změnit jméno';

  @override
  String get nameChanged => 'Jméno změněno';

  @override
  String get nameChangeFailed => 'Jméno se nepodařilo změnit';

  @override
  String get themeSaveFailed => 'Vzhled se nepodařilo uložit';

  @override
  String get passwordChanged => 'Heslo změněno';

  @override
  String get googlePhoto => 'Fotka z Google';

  @override
  String get letter => 'Písmeno';

  @override
  String get saveAvatar => 'Uložit avatar';

  @override
  String get avatarSaved => 'Avatar uložen';

  @override
  String get avatarSaveFailed => 'Avatar se nepodařilo uložit';

  @override
  String get signInForProfile =>
      'Po přihlášení si tu můžete upravit svůj profil.';

  @override
  String get roleCustomer => 'Zákazník';

  @override
  String get roleStaff => 'Obsluha';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get signedInWithGoogle => 'přihlášení přes Google';

  @override
  String get signedInWithEmail => 'přihlášení e-mailem';

  @override
  String get changeAvatar => 'Změnit avatar';

  @override
  String get nameShownToStaff => 'Toto jméno uvidí obsluha u objednávky';

  @override
  String get appearance => 'Vzhled aplikace';

  @override
  String get themeLight => 'Světlý';

  @override
  String get themeSystem => 'Systém';

  @override
  String get themeDark => 'Tmavý';

  @override
  String maxReservations(int count) {
    return 'Máte už $count rezervace – nejdřív některou zrušte';
  }

  @override
  String get cancelReservationQuestion => 'Zrušit rezervaci?';

  @override
  String get keep => 'Ponechat';

  @override
  String get cancelReservation => 'Zrušit rezervaci';

  @override
  String get reservationCancelled => 'Rezervace zrušena';

  @override
  String get reservationCancelFailed => 'Rezervaci se nepodařilo zrušit';

  @override
  String get reservations => 'Rezervace';

  @override
  String get reservationsLoadFailed => 'Rezervace se nepodařilo načíst';

  @override
  String get newReservation => 'Nová rezervace';

  @override
  String get noReservations => 'Zatím žádná rezervace';

  @override
  String get noReservationsHint =>
      'Zarezervujte si stůl a obsluha vám ho potvrdí.';

  @override
  String get older => 'Starší';

  @override
  String get reservationSent => 'Rezervace odeslána – počkejte na potvrzení';

  @override
  String get reservationFailed => 'Rezervaci se nepodařilo odeslat';

  @override
  String get reservationsUnavailable => 'Rezervace teď nejdou';

  @override
  String get reservationsUnavailableHint =>
      'Podnik v nejbližších dnech rezervace nepřijímá.';

  @override
  String get day => 'Den';

  @override
  String get time => 'Čas';

  @override
  String get numberOfPeople => 'Počet osob';

  @override
  String get fewerPeople => 'Méně osob';

  @override
  String get morePeople => 'Více osob';

  @override
  String get noteOptional => 'Poznámka (nepovinné)';

  @override
  String get noteHint => 'Např. dětská židlička, oslava narozenin…';

  @override
  String get chooseTime => 'Vyberte čas';

  @override
  String reserveAt(String day, String time) {
    return 'Rezervovat $day v $time';
  }
}
