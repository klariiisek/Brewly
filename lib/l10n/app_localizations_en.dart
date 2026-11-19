// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get otherLanguageName => 'Čeština';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get language => 'Language';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving…';

  @override
  String get show => 'Show';

  @override
  String get remove => 'Remove';

  @override
  String get total => 'Total';

  @override
  String get checkConnection => 'Please check your internet connection.';

  @override
  String get today => 'today';

  @override
  String get tomorrow => 'tomorrow';

  @override
  String dayAtTime(String day, String time) {
    return '$day at $time';
  }

  @override
  String tableTitle(int table) {
    return 'Table $table';
  }

  @override
  String tableLower(int table) {
    return 'table $table';
  }

  @override
  String get table => 'Table';

  @override
  String get enterTableCode => 'Enter table code';

  @override
  String get goToMenu => 'Go to the menu';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String stampCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stamps',
      one: '1 stamp',
    );
    return '$_temp0';
  }

  @override
  String get signInToReserve => 'Please sign in to make a reservation';

  @override
  String get signedOut => 'You have been signed out';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String get open => 'Open';

  @override
  String get closed => 'Closed';

  @override
  String get browseMenu => 'Browse the menu';

  @override
  String get reserveTable => 'Reserve a table';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get venueInfo => 'About the venue';

  @override
  String orderReady(int number) {
    return 'Your order no. $number is ready!';
  }

  @override
  String get signInForFavorites => 'Please sign in to save favourites';

  @override
  String get favoritesSaveFailed => 'Could not save your favourites';

  @override
  String get navMenu => 'Menu';

  @override
  String get navCart => 'Cart';

  @override
  String get navOrders => 'Orders';

  @override
  String get navProfile => 'Profile';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryFavorites => 'Favourites';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodDay => 'Hello';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get menuLoadFailed => 'Could not load the menu';

  @override
  String get menuEmpty => 'The menu is empty for now';

  @override
  String get menuEmptyHint => 'The staff will add items soon.';

  @override
  String get toCart => 'View cart';

  @override
  String get closedBanner =>
      'We\'re closed right now. You can browse the menu, but you can\'t order yet.';

  @override
  String get whatWillYouHave => 'What would you like today?';

  @override
  String tableWhatWillYouHave(int table) {
    return 'Table $table · What would you like today?';
  }

  @override
  String get addToFavorites => 'Add to favourites';

  @override
  String get removeFromFavorites => 'Remove from favourites';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get soldOut => 'Sold out';

  @override
  String get decreaseQuantity => 'Decrease quantity';

  @override
  String get increaseQuantity => 'Increase quantity';

  @override
  String addToCartPrice(String price) {
    return 'Add to cart · $price';
  }

  @override
  String get currentlySoldOut => 'Currently sold out';

  @override
  String get statusReceived => 'Received';

  @override
  String get statusPreparing => 'Preparing';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusDone => 'Completed';

  @override
  String get progressReceived => 'We\'ve received your order';

  @override
  String get progressPreparing => 'We\'re preparing your order…';

  @override
  String get progressReady => 'Done! It\'ll be at your table in a moment 🎉';

  @override
  String get progressDone => 'Enjoy! 🙌';

  @override
  String get whichTable => 'Which table are you sitting at?';

  @override
  String get tableCodeHint =>
      'Scan the QR code on your table with your camera, or type in the code printed below it.';

  @override
  String get tableCodeLabel => 'Table code (e.g. 4-K7P2X9)';

  @override
  String get tableCodeFormat =>
      'The code is the table number, a dash and 6 characters';

  @override
  String get confirmTable => 'Confirm table';

  @override
  String get nowOpen => '● We\'re open now';

  @override
  String get nowClosed => '● We\'re closed now';

  @override
  String get noVenueInfo => 'The venue hasn\'t added any information yet.';

  @override
  String get address => 'Address';

  @override
  String get openingHours => 'Opening hours';

  @override
  String get closedDay => 'closed';

  @override
  String todayHours(String hours) {
    return 'Today $hours';
  }

  @override
  String get closedToday => 'Closed today';

  @override
  String wifiPassword(String password) {
    return 'Password: $password';
  }

  @override
  String get copyPassword => 'Copy password';

  @override
  String get passwordCopied => 'Password copied';

  @override
  String get googleSignedIn => 'Signed in with Google';

  @override
  String get or => 'or';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get resPending => 'Waiting for confirmation';

  @override
  String get resConfirmed => 'Confirmed';

  @override
  String get resDeclined => 'Declined';

  @override
  String get resCancelled => 'Cancelled';

  @override
  String get loyaltyCard => 'Stamp card';

  @override
  String loyaltyRule(String category, String goal) {
    return 'One stamp for every item from $category. Every item no. $goal is on us.';
  }

  @override
  String loyaltyReady(String goal) {
    return '🎉 Item no. $goal is on us! Redeem it in your cart.';
  }

  @override
  String loyaltyMissing(String stamps, String goal) {
    return '$stamps more and item no. $goal is on us.';
  }

  @override
  String get closedCannotOrder =>
      'We\'re closed right now, you can\'t order yet';

  @override
  String get removeSoldOutFirst =>
      'Please remove sold-out items from your cart first';

  @override
  String get signInToOrder => 'Please sign in to place an order';

  @override
  String get orderSent => 'Your order has been sent';

  @override
  String get rewardFailed =>
      'Couldn\'t redeem your reward, the stamp card has changed in the meantime. Please try again.';

  @override
  String get orderDenied =>
      'Your order could not be sent. Please scan the QR code on your table again and check that the date and time on your phone are correct.';

  @override
  String get orderFailed => 'Your order could not be sent';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptyHint => 'Pick something tasty from the menu.';

  @override
  String get noLongerOffered => 'No longer available – please remove it';

  @override
  String get soldOutRemove => 'Sold out – please remove it';

  @override
  String get previewOnly =>
      'Preview for staff and admin – only customers can place orders.';

  @override
  String get closedCannotOrderDot =>
      'We\'re closed right now, you can\'t order yet.';

  @override
  String get soldOutInCart =>
      'There is a sold-out item in your cart. Please remove it.';

  @override
  String get sending => 'Sending…';

  @override
  String get placeOrder => 'Place order';

  @override
  String rewardFree(String name, String discount) {
    return '$name free  −$discount';
  }

  @override
  String loyaltyProgress(String filled, String needed, String missing) {
    return 'Stamp card: $filled/$needed – $missing to go';
  }

  @override
  String get loyaltyFullHint =>
      'Your stamp card is full! Add something from the menu and it will be free.';

  @override
  String useReward(String name) {
    return 'Redeem reward: $name for free';
  }

  @override
  String get myOrders => 'My orders';

  @override
  String get signInTitle => 'Please sign in';

  @override
  String get signInForOrders => 'Sign in to see your orders here.';

  @override
  String get ordersLoadFailed => 'Could not load your orders';

  @override
  String get noOrdersYet => 'You don\'t have any orders yet';

  @override
  String get ordersAppearHere => 'Your orders will appear here.';

  @override
  String orderNumber(int number) {
    return 'Order #$number';
  }

  @override
  String orderSummary(String date, int table, String items) {
    return '$date • Table $table • $items';
  }

  @override
  String get order => 'Order';

  @override
  String get orderLoadFailed => 'Could not load the order';

  @override
  String get orderNotFound => 'Order not found';

  @override
  String get orderNotFoundHint => 'This order no longer exists.';

  @override
  String tableAndDate(int table, String date) {
    return 'Table $table • $date';
  }

  @override
  String get loyaltyReward => 'Stamp card reward';

  @override
  String get billComing => 'A staff member is coming with your bill';

  @override
  String get staffComing => 'A staff member will be with you shortly';

  @override
  String get requestDenied =>
      'The staff already know, or the table code is not valid. You can scan the QR code on your table again.';

  @override
  String get requestFailed => 'Your request could not be sent';

  @override
  String get needAnything => 'Need anything?';

  @override
  String get callStaff => 'Call staff';

  @override
  String get wantToPay => 'Request the bill';

  @override
  String get closedNoCall =>
      'We\'re closed right now, so you can\'t call staff. You can still pay.';

  @override
  String get staffKnows => 'The staff know you\'re waiting…';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get fillEmailFirst => 'Please enter your e-mail first';

  @override
  String get resetSent =>
      'If an account exists for this e-mail, we\'ve sent you a link to reset your password';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Sign in and order straight to your table.';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Password';

  @override
  String get fillPassword => 'Please enter your password';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get goToRegister => 'Sign up';

  @override
  String get fillEmail => 'Please enter your e-mail';

  @override
  String get emailInvalid => 'This e-mail address is not valid';

  @override
  String get accountCreated => 'Your account has been created. Welcome!';

  @override
  String get registerTitle => 'Sign up';

  @override
  String get registerSubtitle =>
      'Create an account and keep track of your orders.';

  @override
  String get name => 'Name';

  @override
  String get fillName => 'Please enter your name';

  @override
  String get passwordMin => 'Password (at least 6 characters)';

  @override
  String get passwordTooShort => 'The password must have at least 6 characters';

  @override
  String get passwordAgain => 'Repeat password';

  @override
  String get passwordsDontMatch => 'The passwords don\'t match';

  @override
  String get creatingAccount => 'Creating account…';

  @override
  String get signUp => 'Sign up';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get enterCurrentPassword => 'Please enter your current password';

  @override
  String get newPassword => 'New password';

  @override
  String get atLeast6 => 'At least 6 characters';

  @override
  String get samePassword => 'The new password is the same as the current one';

  @override
  String get newPasswordAgain => 'Repeat new password';

  @override
  String get showPasswords => 'Show passwords';

  @override
  String get authInvalidEmail => 'This e-mail address is not valid.';

  @override
  String get authWrongCredentials => 'Wrong e-mail or password.';

  @override
  String get authRecentLogin =>
      'For security reasons, please sign out and sign in again.';

  @override
  String get authEmailInUse => 'An account with this e-mail already exists.';

  @override
  String get authWeakPassword =>
      'The password is too weak (at least 6 characters).';

  @override
  String get authNoInternet => 'No internet connection.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get authPopupBlocked =>
      'Your browser blocked the sign-in window. Please allow pop-ups and try again.';

  @override
  String get authOtherProvider =>
      'An account with this e-mail already uses a different sign-in method.';

  @override
  String get authNotEnabled =>
      'This sign-in method is not enabled in Firebase.';

  @override
  String get authUnauthorizedDomain =>
      'This address is not allowed for sign-in in Firebase.';

  @override
  String get authUnknown => 'Something went wrong. Please try again.';

  @override
  String get changeName => 'Change name';

  @override
  String get nameChanged => 'Name changed';

  @override
  String get nameChangeFailed => 'Could not change your name';

  @override
  String get themeSaveFailed => 'Could not save the appearance';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get googlePhoto => 'Google photo';

  @override
  String get letter => 'Letter';

  @override
  String get saveAvatar => 'Save avatar';

  @override
  String get avatarSaved => 'Avatar saved';

  @override
  String get avatarSaveFailed => 'Could not save the avatar';

  @override
  String get signInForProfile => 'Sign in to edit your profile here.';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get roleStaff => 'Staff';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get signedInWithGoogle => 'signed in with Google';

  @override
  String get signedInWithEmail => 'signed in with e-mail';

  @override
  String get changeAvatar => 'Change avatar';

  @override
  String get nameShownToStaff => 'The staff will see this name on your order';

  @override
  String get appearance => 'App appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get themeDark => 'Dark';

  @override
  String maxReservations(int count) {
    return 'You already have $count reservations – please cancel one first';
  }

  @override
  String get cancelReservationQuestion => 'Cancel reservation?';

  @override
  String get keep => 'Keep';

  @override
  String get cancelReservation => 'Cancel reservation';

  @override
  String get reservationCancelled => 'Reservation cancelled';

  @override
  String get reservationCancelFailed => 'Could not cancel the reservation';

  @override
  String get reservations => 'Reservations';

  @override
  String get reservationsLoadFailed => 'Could not load your reservations';

  @override
  String get newReservation => 'New reservation';

  @override
  String get noReservations => 'No reservations yet';

  @override
  String get noReservationsHint =>
      'Reserve a table and the staff will confirm it.';

  @override
  String get older => 'Past';

  @override
  String get reservationSent =>
      'Reservation sent – please wait for confirmation';

  @override
  String get reservationFailed => 'Could not send the reservation';

  @override
  String get reservationsUnavailable => 'Reservations are not available';

  @override
  String get reservationsUnavailableHint =>
      'The venue is not taking reservations in the coming days.';

  @override
  String get day => 'Day';

  @override
  String get time => 'Time';

  @override
  String get numberOfPeople => 'Number of people';

  @override
  String get fewerPeople => 'Fewer people';

  @override
  String get morePeople => 'More people';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get noteHint => 'E.g. high chair, birthday party…';

  @override
  String get chooseTime => 'Choose a time';

  @override
  String reserveAt(String day, String time) {
    return 'Reserve $day at $time';
  }
}
