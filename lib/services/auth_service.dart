import 'package:firebase_auth/firebase_auth.dart';

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

// Převede chybu z Firebase na srozumitelnou českou hlášku.
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'E-mail nemá správný tvar.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Špatný e-mail nebo heslo.';
      case 'email-already-in-use':
        return 'Účet s tímto e-mailem už existuje.';
      case 'weak-password':
        return 'Heslo je příliš slabé (alespoň 6 znaků).';
      case 'network-request-failed':
        return 'Chybí připojení k internetu.';
      case 'too-many-requests':
        return 'Příliš mnoho pokusů. Zkuste to prosím později.';
      case 'popup-blocked':
        return 'Prohlížeč zablokoval okno pro přihlášení. '
            'Povolte vyskakovací okna a zkuste to znovu.';
      case 'account-exists-with-different-credential':
        return 'Účet s tímto e-mailem už používá jiný způsob přihlášení.';
      case 'operation-not-allowed':
        return 'Tento způsob přihlášení není ve Firebase zapnutý.';
      case 'unauthorized-domain':
        return 'Tato adresa není ve Firebase povolená pro přihlášení.';
    }
  }
  return 'Něco se pokazilo. Zkuste to prosím znovu.';
}
