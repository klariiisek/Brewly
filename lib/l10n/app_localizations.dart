import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('en'),
  ];

  /// No description provided for @languageName.
  ///
  /// In cs, this message translates to:
  /// **'Čeština'**
  String get languageName;

  /// No description provided for @otherLanguageName.
  ///
  /// In cs, this message translates to:
  /// **'English'**
  String get otherLanguageName;

  /// No description provided for @changeLanguage.
  ///
  /// In cs, this message translates to:
  /// **'Změnit jazyk'**
  String get changeLanguage;

  /// No description provided for @language.
  ///
  /// In cs, this message translates to:
  /// **'Jazyk'**
  String get language;

  /// No description provided for @ok.
  ///
  /// In cs, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In cs, this message translates to:
  /// **'Zrušit'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In cs, this message translates to:
  /// **'Uložit'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In cs, this message translates to:
  /// **'Ukládám…'**
  String get saving;

  /// No description provided for @show.
  ///
  /// In cs, this message translates to:
  /// **'Zobrazit'**
  String get show;

  /// No description provided for @remove.
  ///
  /// In cs, this message translates to:
  /// **'Odebrat'**
  String get remove;

  /// No description provided for @total.
  ///
  /// In cs, this message translates to:
  /// **'Celkem'**
  String get total;

  /// No description provided for @checkConnection.
  ///
  /// In cs, this message translates to:
  /// **'Zkontrolujte připojení k internetu.'**
  String get checkConnection;

  /// No description provided for @today.
  ///
  /// In cs, this message translates to:
  /// **'dnes'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In cs, this message translates to:
  /// **'zítra'**
  String get tomorrow;

  /// No description provided for @dayAtTime.
  ///
  /// In cs, this message translates to:
  /// **'{day} v {time}'**
  String dayAtTime(String day, String time);

  /// No description provided for @tableTitle.
  ///
  /// In cs, this message translates to:
  /// **'Stůl {table}'**
  String tableTitle(int table);

  /// No description provided for @tableLower.
  ///
  /// In cs, this message translates to:
  /// **'stůl {table}'**
  String tableLower(int table);

  /// No description provided for @table.
  ///
  /// In cs, this message translates to:
  /// **'Stůl'**
  String get table;

  /// No description provided for @enterTableCode.
  ///
  /// In cs, this message translates to:
  /// **'Zadat kód stolu'**
  String get enterTableCode;

  /// No description provided for @goToMenu.
  ///
  /// In cs, this message translates to:
  /// **'Přejít do menu'**
  String get goToMenu;

  /// No description provided for @itemCount.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, =1{1 položka} few{{count} položky} other{{count} položek}}'**
  String itemCount(int count);

  /// No description provided for @peopleCount.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, =1{1 osoba} few{{count} osoby} other{{count} osob}}'**
  String peopleCount(int count);

  /// No description provided for @stampCount.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, =1{1 razítko} few{{count} razítka} other{{count} razítek}}'**
  String stampCount(int count);

  /// No description provided for @signInToReserve.
  ///
  /// In cs, this message translates to:
  /// **'Pro rezervaci se prosím přihlaste'**
  String get signInToReserve;

  /// No description provided for @signedOut.
  ///
  /// In cs, this message translates to:
  /// **'Byli jste odhlášeni'**
  String get signedOut;

  /// No description provided for @welcomeUser.
  ///
  /// In cs, this message translates to:
  /// **'Vítejte, {name}'**
  String welcomeUser(String name);

  /// No description provided for @open.
  ///
  /// In cs, this message translates to:
  /// **'Otevřeno'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In cs, this message translates to:
  /// **'Zavřeno'**
  String get closed;

  /// No description provided for @browseMenu.
  ///
  /// In cs, this message translates to:
  /// **'Prohlédnout menu'**
  String get browseMenu;

  /// No description provided for @reserveTable.
  ///
  /// In cs, this message translates to:
  /// **'Rezervovat stůl'**
  String get reserveTable;

  /// No description provided for @signIn.
  ///
  /// In cs, this message translates to:
  /// **'Přihlásit se'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In cs, this message translates to:
  /// **'Odhlásit se'**
  String get signOut;

  /// No description provided for @venueInfo.
  ///
  /// In cs, this message translates to:
  /// **'Informace o podniku'**
  String get venueInfo;

  /// No description provided for @orderReady.
  ///
  /// In cs, this message translates to:
  /// **'Vaše objednávka č. {number} je připravená!'**
  String orderReady(int number);

  /// No description provided for @signInForFavorites.
  ///
  /// In cs, this message translates to:
  /// **'Pro oblíbené produkty se prosím přihlaste'**
  String get signInForFavorites;

  /// No description provided for @favoritesSaveFailed.
  ///
  /// In cs, this message translates to:
  /// **'Oblíbené se nepodařilo uložit'**
  String get favoritesSaveFailed;

  /// No description provided for @navMenu.
  ///
  /// In cs, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @navCart.
  ///
  /// In cs, this message translates to:
  /// **'Košík'**
  String get navCart;

  /// No description provided for @navOrders.
  ///
  /// In cs, this message translates to:
  /// **'Objednávky'**
  String get navOrders;

  /// No description provided for @navProfile.
  ///
  /// In cs, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @categoryAll.
  ///
  /// In cs, this message translates to:
  /// **'Vše'**
  String get categoryAll;

  /// No description provided for @categoryFavorites.
  ///
  /// In cs, this message translates to:
  /// **'Oblíbené'**
  String get categoryFavorites;

  /// No description provided for @goodMorning.
  ///
  /// In cs, this message translates to:
  /// **'Dobré ráno'**
  String get goodMorning;

  /// No description provided for @goodDay.
  ///
  /// In cs, this message translates to:
  /// **'Dobrý den'**
  String get goodDay;

  /// No description provided for @goodEvening.
  ///
  /// In cs, this message translates to:
  /// **'Dobrý večer'**
  String get goodEvening;

  /// No description provided for @menuLoadFailed.
  ///
  /// In cs, this message translates to:
  /// **'Menu se nepodařilo načíst'**
  String get menuLoadFailed;

  /// No description provided for @menuEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Menu je zatím prázdné'**
  String get menuEmpty;

  /// No description provided for @menuEmptyHint.
  ///
  /// In cs, this message translates to:
  /// **'Obsluha ho brzy doplní.'**
  String get menuEmptyHint;

  /// No description provided for @toCart.
  ///
  /// In cs, this message translates to:
  /// **'Do košíku'**
  String get toCart;

  /// No description provided for @closedBanner.
  ///
  /// In cs, this message translates to:
  /// **'Teď máme zavřeno. Menu si můžete prohlédnout, objednat ale zatím nejde.'**
  String get closedBanner;

  /// No description provided for @whatWillYouHave.
  ///
  /// In cs, this message translates to:
  /// **'Co si dnes dáte?'**
  String get whatWillYouHave;

  /// No description provided for @tableWhatWillYouHave.
  ///
  /// In cs, this message translates to:
  /// **'Stůl {table} · Co si dnes dáte?'**
  String tableWhatWillYouHave(int table);

  /// No description provided for @addToFavorites.
  ///
  /// In cs, this message translates to:
  /// **'Přidat do oblíbených'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In cs, this message translates to:
  /// **'Odebrat z oblíbených'**
  String get removeFromFavorites;

  /// No description provided for @addToCart.
  ///
  /// In cs, this message translates to:
  /// **'Přidat do košíku'**
  String get addToCart;

  /// No description provided for @soldOut.
  ///
  /// In cs, this message translates to:
  /// **'Vyprodáno'**
  String get soldOut;

  /// No description provided for @decreaseQuantity.
  ///
  /// In cs, this message translates to:
  /// **'Snížit množství'**
  String get decreaseQuantity;

  /// No description provided for @increaseQuantity.
  ///
  /// In cs, this message translates to:
  /// **'Zvýšit množství'**
  String get increaseQuantity;

  /// No description provided for @addToCartPrice.
  ///
  /// In cs, this message translates to:
  /// **'Přidat do košíku · {price}'**
  String addToCartPrice(String price);

  /// No description provided for @currentlySoldOut.
  ///
  /// In cs, this message translates to:
  /// **'Momentálně vyprodáno'**
  String get currentlySoldOut;

  /// No description provided for @statusReceived.
  ///
  /// In cs, this message translates to:
  /// **'Přijata'**
  String get statusReceived;

  /// No description provided for @statusPreparing.
  ///
  /// In cs, this message translates to:
  /// **'Připravuje se'**
  String get statusPreparing;

  /// No description provided for @statusReady.
  ///
  /// In cs, this message translates to:
  /// **'Připravena'**
  String get statusReady;

  /// No description provided for @statusDone.
  ///
  /// In cs, this message translates to:
  /// **'Dokončena'**
  String get statusDone;

  /// No description provided for @progressReceived.
  ///
  /// In cs, this message translates to:
  /// **'Objednávku jsme přijali'**
  String get progressReceived;

  /// No description provided for @progressPreparing.
  ///
  /// In cs, this message translates to:
  /// **'Připravujeme vaši objednávku…'**
  String get progressPreparing;

  /// No description provided for @progressReady.
  ///
  /// In cs, this message translates to:
  /// **'Hotovo! Za chvíli ji máte na stole 🎉'**
  String get progressReady;

  /// No description provided for @progressDone.
  ///
  /// In cs, this message translates to:
  /// **'Dobrou chuť! 🙌'**
  String get progressDone;

  /// No description provided for @whichTable.
  ///
  /// In cs, this message translates to:
  /// **'U kterého stolu sedíte?'**
  String get whichTable;

  /// No description provided for @tableCodeHint.
  ///
  /// In cs, this message translates to:
  /// **'Naskenujte QR kód na stole fotoaparátem, nebo opište kód, který je pod ním.'**
  String get tableCodeHint;

  /// No description provided for @tableCodeLabel.
  ///
  /// In cs, this message translates to:
  /// **'Kód stolu (např. 4-K7P2X9)'**
  String get tableCodeLabel;

  /// No description provided for @tableCodeFormat.
  ///
  /// In cs, this message translates to:
  /// **'Kód má tvar číslo stolu, pomlčka a 6 znaků'**
  String get tableCodeFormat;

  /// No description provided for @confirmTable.
  ///
  /// In cs, this message translates to:
  /// **'Potvrdit stůl'**
  String get confirmTable;

  /// No description provided for @nowOpen.
  ///
  /// In cs, this message translates to:
  /// **'● Teď máme otevřeno'**
  String get nowOpen;

  /// No description provided for @nowClosed.
  ///
  /// In cs, this message translates to:
  /// **'● Teď máme zavřeno'**
  String get nowClosed;

  /// No description provided for @noVenueInfo.
  ///
  /// In cs, this message translates to:
  /// **'Podnik zatím nevyplnil žádné informace.'**
  String get noVenueInfo;

  /// No description provided for @address.
  ///
  /// In cs, this message translates to:
  /// **'Adresa'**
  String get address;

  /// No description provided for @openingHours.
  ///
  /// In cs, this message translates to:
  /// **'Otevírací doba'**
  String get openingHours;

  /// No description provided for @closedDay.
  ///
  /// In cs, this message translates to:
  /// **'zavřeno'**
  String get closedDay;

  /// No description provided for @todayHours.
  ///
  /// In cs, this message translates to:
  /// **'Dnes {hours}'**
  String todayHours(String hours);

  /// No description provided for @closedToday.
  ///
  /// In cs, this message translates to:
  /// **'Dnes zavřeno'**
  String get closedToday;

  /// No description provided for @wifiPassword.
  ///
  /// In cs, this message translates to:
  /// **'Heslo: {password}'**
  String wifiPassword(String password);

  /// No description provided for @copyPassword.
  ///
  /// In cs, this message translates to:
  /// **'Zkopírovat heslo'**
  String get copyPassword;

  /// No description provided for @passwordCopied.
  ///
  /// In cs, this message translates to:
  /// **'Heslo zkopírováno'**
  String get passwordCopied;

  /// No description provided for @googleSignedIn.
  ///
  /// In cs, this message translates to:
  /// **'Přihlášení přes Google proběhlo úspěšně'**
  String get googleSignedIn;

  /// No description provided for @or.
  ///
  /// In cs, this message translates to:
  /// **'nebo'**
  String get or;

  /// No description provided for @signingIn.
  ///
  /// In cs, this message translates to:
  /// **'Přihlašuji…'**
  String get signingIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In cs, this message translates to:
  /// **'Pokračovat přes Google'**
  String get continueWithGoogle;

  /// No description provided for @resPending.
  ///
  /// In cs, this message translates to:
  /// **'Čeká na potvrzení'**
  String get resPending;

  /// No description provided for @resConfirmed.
  ///
  /// In cs, this message translates to:
  /// **'Potvrzena'**
  String get resConfirmed;

  /// No description provided for @resDeclined.
  ///
  /// In cs, this message translates to:
  /// **'Odmítnuta'**
  String get resDeclined;

  /// No description provided for @resCancelled.
  ///
  /// In cs, this message translates to:
  /// **'Zrušena'**
  String get resCancelled;

  /// No description provided for @loyaltyCard.
  ///
  /// In cs, this message translates to:
  /// **'Razítková karta'**
  String get loyaltyCard;

  /// No description provided for @loyaltyRule.
  ///
  /// In cs, this message translates to:
  /// **'Za každý kus z kategorie {category} jedno razítko. Každý {goal}. kus máte zdarma.'**
  String loyaltyRule(String category, String goal);

  /// No description provided for @loyaltyReady.
  ///
  /// In cs, this message translates to:
  /// **'🎉 {goal}. kus máte zdarma! Uplatníte ho v košíku.'**
  String loyaltyReady(String goal);

  /// No description provided for @loyaltyMissing.
  ///
  /// In cs, this message translates to:
  /// **'Ještě {stamps} a {goal}. kus máte zdarma.'**
  String loyaltyMissing(String stamps, String goal);

  /// No description provided for @closedCannotOrder.
  ///
  /// In cs, this message translates to:
  /// **'Teď máme zavřeno, objednat zatím nejde'**
  String get closedCannotOrder;

  /// No description provided for @removeSoldOutFirst.
  ///
  /// In cs, this message translates to:
  /// **'Nejdřív odeberte z košíku vyprodané produkty'**
  String get removeSoldOutFirst;

  /// No description provided for @signInToOrder.
  ///
  /// In cs, this message translates to:
  /// **'Pro objednání se prosím přihlaste'**
  String get signInToOrder;

  /// No description provided for @orderSent.
  ///
  /// In cs, this message translates to:
  /// **'Objednávka byla odeslána'**
  String get orderSent;

  /// No description provided for @rewardFailed.
  ///
  /// In cs, this message translates to:
  /// **'Odměnu se nepodařilo uplatnit, razítková karta se mezitím změnila. Zkuste to prosím znovu.'**
  String get rewardFailed;

  /// No description provided for @orderDenied.
  ///
  /// In cs, this message translates to:
  /// **'Objednávku se nepodařilo odeslat. Naskenujte prosím QR kód na stole znovu a zkontrolujte, že máte v telefonu správné datum a čas.'**
  String get orderDenied;

  /// No description provided for @orderFailed.
  ///
  /// In cs, this message translates to:
  /// **'Objednávku se nepodařilo odeslat'**
  String get orderFailed;

  /// No description provided for @cartEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Košík je prázdný'**
  String get cartEmpty;

  /// No description provided for @cartEmptyHint.
  ///
  /// In cs, this message translates to:
  /// **'Vyberte si něco dobrého z menu.'**
  String get cartEmptyHint;

  /// No description provided for @noLongerOffered.
  ///
  /// In cs, this message translates to:
  /// **'Už není v nabídce – odeberte ji'**
  String get noLongerOffered;

  /// No description provided for @soldOutRemove.
  ///
  /// In cs, this message translates to:
  /// **'Vyprodáno – odeberte z košíku'**
  String get soldOutRemove;

  /// No description provided for @previewOnly.
  ///
  /// In cs, this message translates to:
  /// **'Náhled pro obsluhu a admina – objednávat mohou jen zákazníci.'**
  String get previewOnly;

  /// No description provided for @closedCannotOrderDot.
  ///
  /// In cs, this message translates to:
  /// **'Teď máme zavřeno, objednat zatím nejde.'**
  String get closedCannotOrderDot;

  /// No description provided for @soldOutInCart.
  ///
  /// In cs, this message translates to:
  /// **'V košíku je vyprodaný produkt. Odeberte ho, prosím.'**
  String get soldOutInCart;

  /// No description provided for @sending.
  ///
  /// In cs, this message translates to:
  /// **'Odesílám…'**
  String get sending;

  /// No description provided for @placeOrder.
  ///
  /// In cs, this message translates to:
  /// **'Objednat'**
  String get placeOrder;

  /// No description provided for @rewardFree.
  ///
  /// In cs, this message translates to:
  /// **'{name} zdarma  −{discount}'**
  String rewardFree(String name, String discount);

  /// No description provided for @loyaltyProgress.
  ///
  /// In cs, this message translates to:
  /// **'Razítková karta: {filled}/{needed} – do odměny zbývá {missing}'**
  String loyaltyProgress(String filled, String needed, String missing);

  /// No description provided for @loyaltyFullHint.
  ///
  /// In cs, this message translates to:
  /// **'Máte plnou razítkovou kartu! Přidejte si něco z menu a bude to zdarma.'**
  String get loyaltyFullHint;

  /// No description provided for @useReward.
  ///
  /// In cs, this message translates to:
  /// **'Uplatnit odměnu: {name} zdarma'**
  String useReward(String name);

  /// No description provided for @myOrders.
  ///
  /// In cs, this message translates to:
  /// **'Moje objednávky'**
  String get myOrders;

  /// No description provided for @signInTitle.
  ///
  /// In cs, this message translates to:
  /// **'Přihlaste se'**
  String get signInTitle;

  /// No description provided for @signInForOrders.
  ///
  /// In cs, this message translates to:
  /// **'Po přihlášení tu uvidíte své objednávky.'**
  String get signInForOrders;

  /// No description provided for @ordersLoadFailed.
  ///
  /// In cs, this message translates to:
  /// **'Objednávky se nepodařilo načíst'**
  String get ordersLoadFailed;

  /// No description provided for @noOrdersYet.
  ///
  /// In cs, this message translates to:
  /// **'Zatím nemáte žádné objednávky'**
  String get noOrdersYet;

  /// No description provided for @ordersAppearHere.
  ///
  /// In cs, this message translates to:
  /// **'Vaše objednávky se zobrazí tady.'**
  String get ordersAppearHere;

  /// No description provided for @orderNumber.
  ///
  /// In cs, this message translates to:
  /// **'Objednávka #{number}'**
  String orderNumber(int number);

  /// No description provided for @orderSummary.
  ///
  /// In cs, this message translates to:
  /// **'{date} • Stůl {table} • {items}'**
  String orderSummary(String date, int table, String items);

  /// No description provided for @order.
  ///
  /// In cs, this message translates to:
  /// **'Objednávka'**
  String get order;

  /// No description provided for @orderLoadFailed.
  ///
  /// In cs, this message translates to:
  /// **'Objednávku se nepodařilo načíst'**
  String get orderLoadFailed;

  /// No description provided for @orderNotFound.
  ///
  /// In cs, this message translates to:
  /// **'Objednávka nenalezena'**
  String get orderNotFound;

  /// No description provided for @orderNotFoundHint.
  ///
  /// In cs, this message translates to:
  /// **'Tato objednávka už v databázi není.'**
  String get orderNotFoundHint;

  /// No description provided for @tableAndDate.
  ///
  /// In cs, this message translates to:
  /// **'Stůl {table} • {date}'**
  String tableAndDate(int table, String date);

  /// No description provided for @loyaltyReward.
  ///
  /// In cs, this message translates to:
  /// **'Odměna z razítkové karty'**
  String get loyaltyReward;

  /// No description provided for @billComing.
  ///
  /// In cs, this message translates to:
  /// **'Obsluha za vámi přijde s účtem'**
  String get billComing;

  /// No description provided for @staffComing.
  ///
  /// In cs, this message translates to:
  /// **'Obsluha za vámi brzy přijde'**
  String get staffComing;

  /// No description provided for @requestDenied.
  ///
  /// In cs, this message translates to:
  /// **'Obsluha o vás už ví, nebo kód stolu neplatí. Případně naskenujte QR kód na stole znovu.'**
  String get requestDenied;

  /// No description provided for @requestFailed.
  ///
  /// In cs, this message translates to:
  /// **'Požadavek se nepodařilo odeslat'**
  String get requestFailed;

  /// No description provided for @needAnything.
  ///
  /// In cs, this message translates to:
  /// **'Potřebujete něco?'**
  String get needAnything;

  /// No description provided for @callStaff.
  ///
  /// In cs, this message translates to:
  /// **'Přivolat obsluhu'**
  String get callStaff;

  /// No description provided for @wantToPay.
  ///
  /// In cs, this message translates to:
  /// **'Chci zaplatit'**
  String get wantToPay;

  /// No description provided for @closedNoCall.
  ///
  /// In cs, this message translates to:
  /// **'Teď máme zavřeno, obsluhu nejde přivolat. Zaplatit můžete.'**
  String get closedNoCall;

  /// No description provided for @staffKnows.
  ///
  /// In cs, this message translates to:
  /// **'Obsluha o vás ví…'**
  String get staffKnows;

  /// No description provided for @welcomeBack.
  ///
  /// In cs, this message translates to:
  /// **'Vítejte zpět!'**
  String get welcomeBack;

  /// No description provided for @fillEmailFirst.
  ///
  /// In cs, this message translates to:
  /// **'Nejdřív vyplňte e-mail'**
  String get fillEmailFirst;

  /// No description provided for @resetSent.
  ///
  /// In cs, this message translates to:
  /// **'Pokud k e-mailu existuje účet, poslali jsme odkaz pro nové heslo'**
  String get resetSent;

  /// No description provided for @loginTitle.
  ///
  /// In cs, this message translates to:
  /// **'Přihlášení'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In cs, this message translates to:
  /// **'Přihlaste se a objednávejte přímo ke stolu.'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In cs, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In cs, this message translates to:
  /// **'Heslo'**
  String get password;

  /// No description provided for @fillPassword.
  ///
  /// In cs, this message translates to:
  /// **'Vyplňte heslo'**
  String get fillPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In cs, this message translates to:
  /// **'Zapomenuté heslo?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In cs, this message translates to:
  /// **'Nemáte účet?'**
  String get noAccount;

  /// No description provided for @goToRegister.
  ///
  /// In cs, this message translates to:
  /// **'Zaregistrujte se'**
  String get goToRegister;

  /// No description provided for @fillEmail.
  ///
  /// In cs, this message translates to:
  /// **'Vyplňte e-mail'**
  String get fillEmail;

  /// No description provided for @emailInvalid.
  ///
  /// In cs, this message translates to:
  /// **'E-mail nemá správný tvar'**
  String get emailInvalid;

  /// No description provided for @accountCreated.
  ///
  /// In cs, this message translates to:
  /// **'Účet byl vytvořen. Vítejte!'**
  String get accountCreated;

  /// No description provided for @registerTitle.
  ///
  /// In cs, this message translates to:
  /// **'Registrace'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In cs, this message translates to:
  /// **'Vytvořte si účet a sledujte své objednávky.'**
  String get registerSubtitle;

  /// No description provided for @name.
  ///
  /// In cs, this message translates to:
  /// **'Jméno'**
  String get name;

  /// No description provided for @fillName.
  ///
  /// In cs, this message translates to:
  /// **'Vyplňte jméno'**
  String get fillName;

  /// No description provided for @passwordMin.
  ///
  /// In cs, this message translates to:
  /// **'Heslo (alespoň 6 znaků)'**
  String get passwordMin;

  /// No description provided for @passwordTooShort.
  ///
  /// In cs, this message translates to:
  /// **'Heslo musí mít alespoň 6 znaků'**
  String get passwordTooShort;

  /// No description provided for @passwordAgain.
  ///
  /// In cs, this message translates to:
  /// **'Heslo znovu'**
  String get passwordAgain;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In cs, this message translates to:
  /// **'Hesla se neshodují'**
  String get passwordsDontMatch;

  /// No description provided for @creatingAccount.
  ///
  /// In cs, this message translates to:
  /// **'Vytvářím účet…'**
  String get creatingAccount;

  /// No description provided for @signUp.
  ///
  /// In cs, this message translates to:
  /// **'Zaregistrovat se'**
  String get signUp;

  /// No description provided for @changePassword.
  ///
  /// In cs, this message translates to:
  /// **'Změnit heslo'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In cs, this message translates to:
  /// **'Současné heslo'**
  String get currentPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In cs, this message translates to:
  /// **'Zadejte současné heslo'**
  String get enterCurrentPassword;

  /// No description provided for @newPassword.
  ///
  /// In cs, this message translates to:
  /// **'Nové heslo'**
  String get newPassword;

  /// No description provided for @atLeast6.
  ///
  /// In cs, this message translates to:
  /// **'Alespoň 6 znaků'**
  String get atLeast6;

  /// No description provided for @samePassword.
  ///
  /// In cs, this message translates to:
  /// **'Nové heslo je stejné jako současné'**
  String get samePassword;

  /// No description provided for @newPasswordAgain.
  ///
  /// In cs, this message translates to:
  /// **'Nové heslo znovu'**
  String get newPasswordAgain;

  /// No description provided for @showPasswords.
  ///
  /// In cs, this message translates to:
  /// **'Zobrazit hesla'**
  String get showPasswords;

  /// No description provided for @authInvalidEmail.
  ///
  /// In cs, this message translates to:
  /// **'E-mail nemá správný tvar.'**
  String get authInvalidEmail;

  /// No description provided for @authWrongCredentials.
  ///
  /// In cs, this message translates to:
  /// **'Špatný e-mail nebo heslo.'**
  String get authWrongCredentials;

  /// No description provided for @authRecentLogin.
  ///
  /// In cs, this message translates to:
  /// **'Z bezpečnostních důvodů se prosím odhlaste a znovu přihlaste.'**
  String get authRecentLogin;

  /// No description provided for @authEmailInUse.
  ///
  /// In cs, this message translates to:
  /// **'Účet s tímto e-mailem už existuje.'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In cs, this message translates to:
  /// **'Heslo je příliš slabé (alespoň 6 znaků).'**
  String get authWeakPassword;

  /// No description provided for @authNoInternet.
  ///
  /// In cs, this message translates to:
  /// **'Chybí připojení k internetu.'**
  String get authNoInternet;

  /// No description provided for @authTooManyRequests.
  ///
  /// In cs, this message translates to:
  /// **'Příliš mnoho pokusů. Zkuste to prosím později.'**
  String get authTooManyRequests;

  /// No description provided for @authPopupBlocked.
  ///
  /// In cs, this message translates to:
  /// **'Prohlížeč zablokoval okno pro přihlášení. Povolte vyskakovací okna a zkuste to znovu.'**
  String get authPopupBlocked;

  /// No description provided for @authOtherProvider.
  ///
  /// In cs, this message translates to:
  /// **'Účet s tímto e-mailem už používá jiný způsob přihlášení.'**
  String get authOtherProvider;

  /// No description provided for @authNotEnabled.
  ///
  /// In cs, this message translates to:
  /// **'Tento způsob přihlášení není ve Firebase zapnutý.'**
  String get authNotEnabled;

  /// No description provided for @authUnauthorizedDomain.
  ///
  /// In cs, this message translates to:
  /// **'Tato adresa není ve Firebase povolená pro přihlášení.'**
  String get authUnauthorizedDomain;

  /// No description provided for @authUnknown.
  ///
  /// In cs, this message translates to:
  /// **'Něco se pokazilo. Zkuste to prosím znovu.'**
  String get authUnknown;

  /// No description provided for @changeName.
  ///
  /// In cs, this message translates to:
  /// **'Změnit jméno'**
  String get changeName;

  /// No description provided for @nameChanged.
  ///
  /// In cs, this message translates to:
  /// **'Jméno změněno'**
  String get nameChanged;

  /// No description provided for @nameChangeFailed.
  ///
  /// In cs, this message translates to:
  /// **'Jméno se nepodařilo změnit'**
  String get nameChangeFailed;

  /// No description provided for @themeSaveFailed.
  ///
  /// In cs, this message translates to:
  /// **'Vzhled se nepodařilo uložit'**
  String get themeSaveFailed;

  /// No description provided for @passwordChanged.
  ///
  /// In cs, this message translates to:
  /// **'Heslo změněno'**
  String get passwordChanged;

  /// No description provided for @googlePhoto.
  ///
  /// In cs, this message translates to:
  /// **'Fotka z Google'**
  String get googlePhoto;

  /// No description provided for @letter.
  ///
  /// In cs, this message translates to:
  /// **'Písmeno'**
  String get letter;

  /// No description provided for @saveAvatar.
  ///
  /// In cs, this message translates to:
  /// **'Uložit avatar'**
  String get saveAvatar;

  /// No description provided for @avatarSaved.
  ///
  /// In cs, this message translates to:
  /// **'Avatar uložen'**
  String get avatarSaved;

  /// No description provided for @avatarSaveFailed.
  ///
  /// In cs, this message translates to:
  /// **'Avatar se nepodařilo uložit'**
  String get avatarSaveFailed;

  /// No description provided for @signInForProfile.
  ///
  /// In cs, this message translates to:
  /// **'Po přihlášení si tu můžete upravit svůj profil.'**
  String get signInForProfile;

  /// No description provided for @roleCustomer.
  ///
  /// In cs, this message translates to:
  /// **'Zákazník'**
  String get roleCustomer;

  /// No description provided for @roleStaff.
  ///
  /// In cs, this message translates to:
  /// **'Obsluha'**
  String get roleStaff;

  /// No description provided for @roleAdmin.
  ///
  /// In cs, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @signedInWithGoogle.
  ///
  /// In cs, this message translates to:
  /// **'přihlášení přes Google'**
  String get signedInWithGoogle;

  /// No description provided for @signedInWithEmail.
  ///
  /// In cs, this message translates to:
  /// **'přihlášení e-mailem'**
  String get signedInWithEmail;

  /// No description provided for @changeAvatar.
  ///
  /// In cs, this message translates to:
  /// **'Změnit avatar'**
  String get changeAvatar;

  /// No description provided for @nameShownToStaff.
  ///
  /// In cs, this message translates to:
  /// **'Toto jméno uvidí obsluha u objednávky'**
  String get nameShownToStaff;

  /// No description provided for @appearance.
  ///
  /// In cs, this message translates to:
  /// **'Vzhled aplikace'**
  String get appearance;

  /// No description provided for @themeLight.
  ///
  /// In cs, this message translates to:
  /// **'Světlý'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In cs, this message translates to:
  /// **'Systém'**
  String get themeSystem;

  /// No description provided for @themeDark.
  ///
  /// In cs, this message translates to:
  /// **'Tmavý'**
  String get themeDark;

  /// No description provided for @maxReservations.
  ///
  /// In cs, this message translates to:
  /// **'Máte už {count} rezervace – nejdřív některou zrušte'**
  String maxReservations(int count);

  /// No description provided for @cancelReservationQuestion.
  ///
  /// In cs, this message translates to:
  /// **'Zrušit rezervaci?'**
  String get cancelReservationQuestion;

  /// No description provided for @keep.
  ///
  /// In cs, this message translates to:
  /// **'Ponechat'**
  String get keep;

  /// No description provided for @cancelReservation.
  ///
  /// In cs, this message translates to:
  /// **'Zrušit rezervaci'**
  String get cancelReservation;

  /// No description provided for @reservationCancelled.
  ///
  /// In cs, this message translates to:
  /// **'Rezervace zrušena'**
  String get reservationCancelled;

  /// No description provided for @reservationCancelFailed.
  ///
  /// In cs, this message translates to:
  /// **'Rezervaci se nepodařilo zrušit'**
  String get reservationCancelFailed;

  /// No description provided for @reservations.
  ///
  /// In cs, this message translates to:
  /// **'Rezervace'**
  String get reservations;

  /// No description provided for @reservationsLoadFailed.
  ///
  /// In cs, this message translates to:
  /// **'Rezervace se nepodařilo načíst'**
  String get reservationsLoadFailed;

  /// No description provided for @newReservation.
  ///
  /// In cs, this message translates to:
  /// **'Nová rezervace'**
  String get newReservation;

  /// No description provided for @noReservations.
  ///
  /// In cs, this message translates to:
  /// **'Zatím žádná rezervace'**
  String get noReservations;

  /// No description provided for @noReservationsHint.
  ///
  /// In cs, this message translates to:
  /// **'Zarezervujte si stůl a obsluha vám ho potvrdí.'**
  String get noReservationsHint;

  /// No description provided for @older.
  ///
  /// In cs, this message translates to:
  /// **'Starší'**
  String get older;

  /// No description provided for @reservationSent.
  ///
  /// In cs, this message translates to:
  /// **'Rezervace odeslána – počkejte na potvrzení'**
  String get reservationSent;

  /// No description provided for @reservationFailed.
  ///
  /// In cs, this message translates to:
  /// **'Rezervaci se nepodařilo odeslat'**
  String get reservationFailed;

  /// No description provided for @reservationsUnavailable.
  ///
  /// In cs, this message translates to:
  /// **'Rezervace teď nejdou'**
  String get reservationsUnavailable;

  /// No description provided for @reservationsUnavailableHint.
  ///
  /// In cs, this message translates to:
  /// **'Podnik v nejbližších dnech rezervace nepřijímá.'**
  String get reservationsUnavailableHint;

  /// No description provided for @day.
  ///
  /// In cs, this message translates to:
  /// **'Den'**
  String get day;

  /// No description provided for @time.
  ///
  /// In cs, this message translates to:
  /// **'Čas'**
  String get time;

  /// No description provided for @numberOfPeople.
  ///
  /// In cs, this message translates to:
  /// **'Počet osob'**
  String get numberOfPeople;

  /// No description provided for @fewerPeople.
  ///
  /// In cs, this message translates to:
  /// **'Méně osob'**
  String get fewerPeople;

  /// No description provided for @morePeople.
  ///
  /// In cs, this message translates to:
  /// **'Více osob'**
  String get morePeople;

  /// No description provided for @noteOptional.
  ///
  /// In cs, this message translates to:
  /// **'Poznámka (nepovinné)'**
  String get noteOptional;

  /// No description provided for @noteHint.
  ///
  /// In cs, this message translates to:
  /// **'Např. dětská židlička, oslava narozenin…'**
  String get noteHint;

  /// No description provided for @chooseTime.
  ///
  /// In cs, this message translates to:
  /// **'Vyberte čas'**
  String get chooseTime;

  /// No description provided for @reserveAt.
  ///
  /// In cs, this message translates to:
  /// **'Rezervovat {day} v {time}'**
  String reserveAt(String day, String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['cs', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
