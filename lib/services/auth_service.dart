import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/language.dart';

// Služba pro přihlašování přes Firebase Authentication.
class AuthService {
  final FirebaseAuth auth;

  AuthService(this.auth);

  // Proud, který pošle nového uživatele pokaždé, když se někdo přihlásí,
  // odhlásí nebo změní své údaje (např. jméno). Odhlášený = null.
  Stream<User?> userChanges() => auth.userChanges();

  // Právě přihlášený uživatel (nebo null).
  User? get currentUser => auth.currentUser;

  Future<void> signIn(String email, String password) {
    return auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Vytvoří nový účet a uloží k němu jméno.
  Future<void> register(String name, String email, String password) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
  }

  // Přihlášení přes Google: otevře okno Googlu, kde si uživatel vybere účet.
  // Když se přihlašuje poprvé, Firebase mu účet sám založí.
  // Vrátí true, když se přihlásil, a false, když okno zavřel.
  Future<bool> signInWithGoogle() async {
    try {
      await auth.signInWithPopup(GoogleAuthProvider());
      return true;
    } on FirebaseAuthException catch (error) {
      // Zavřené okno není chyba – uživatel si to jen rozmyslel.
      if (error.code == 'popup-closed-by-user' ||
          error.code == 'cancelled-popup-request') {
        return false;
      }
      rethrow;
    }
  }

  Future<void> signOut() => auth.signOut();

  // Změní jméno účtu (to se pak ukládá do nových objednávek).
  Future<void> updateName(String name) async {
    await auth.currentUser?.updateDisplayName(name.trim());
  }

  // Změna hesla. Firebase u citlivých změn chce, aby uživatel nejdřív
  // znovu potvrdil současné heslo (reautentizace) – kdyby někdo našel
  // odemčený telefon, heslo bez znalosti toho starého nezmění.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = auth.currentUser!;
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  // Pošle na e-mail odkaz pro nastavení nového hesla.
  Future<void> sendPasswordReset(String email) {
    return auth.sendPasswordResetEmail(email: email.trim());
  }
}

// Jméno, které se zobrazí v aplikaci (když jméno chybí, použije se e-mail).
String userDisplayName(User user) {
  final name = user.displayName;
  if (name != null && name.isNotEmpty) return name;
  return user.email ?? 'Zákazník';
}

// Přihlašuje se uživatel e-mailem a heslem? (Jen takový si může heslo
// změnit – kdo se přihlašuje přes Google, heslo v aplikaci nemá.)
bool hasPasswordLogin(User user) {
  return user.providerData.any((info) => info.providerId == 'password');
}

// Přihlašuje se přes Google?
bool hasGoogleLogin(User user) {
  return user.providerData.any((info) => info.providerId == 'google.com');
}

// Převede chybu z Firebase na srozumitelnou hlášku v jazyce aplikace.
String authErrorMessage(Object error, AppLocalizations t) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return t.authInvalidEmail;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return t.authWrongCredentials;
      case 'requires-recent-login':
        return t.authRecentLogin;
      case 'email-already-in-use':
        return t.authEmailInUse;
      case 'weak-password':
        return t.authWeakPassword;
      case 'network-request-failed':
        return t.authNoInternet;
      case 'too-many-requests':
        return t.authTooManyRequests;
      case 'popup-blocked':
        return t.authPopupBlocked;
      case 'account-exists-with-different-credential':
        return t.authOtherProvider;
      case 'operation-not-allowed':
        return t.authNotEnabled;
      case 'unauthorized-domain':
        return t.authUnauthorizedDomain;
    }
  }
  return t.authUnknown;
}
