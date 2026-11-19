import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/google_sign_in_button.dart';
import 'register_screen.dart';
import '../l10n/language.dart';

// Přihlášení e-mailem a heslem.
// Po úspěšném přihlášení se obrazovka zavře a vrátí true.
class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Klíč formuláře: přes něj se spustí kontrola všech polí najednou.
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    // Controllery je potřeba uvolnit, když obrazovka zanikne.
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    // Zkontroluje pole (validator). Když je něco špatně, nepokračuje.
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      await widget.authService.signIn(
        emailController.text,
        passwordController.text,
      );
      if (!mounted) return;
      showAppMessage(context, context.t.welcomeBack);
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, authErrorMessage(error, context.t));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showAppMessage(context, context.t.fillEmailFirst);
      return;
    }
    try {
      await widget.authService.sendPasswordReset(email);
      if (!mounted) return;
      // Firebase z bezpečnostních důvodů neprozradí, jestli účet s e-mailem
      // existuje, proto hláška říká "pokud".
      showAppMessage(
        context,
        context.t.resetSent,
      );
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, authErrorMessage(error, context.t));
    }
  }

  Future<void> openRegister() async {
    final registered = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(authService: widget.authService),
      ),
    );
    // Po úspěšné registraci je uživatel rovnou přihlášený.
    if (registered == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AuthHeader(
              title: context.t.loginTitle,
              subtitle: context.t.loginSubtitle,
            ),
            const SizedBox(height: 32),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: context.t.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (value) => validateEmail(value, context.t),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: context.t.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      // Oko: zobrazí / skryje heslo.
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => hidePassword = !hidePassword);
                        },
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? context.t.fillPassword
                        : null,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: resetPassword,
                child: Text(context.t.forgotPassword),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : signIn,
                child: Text(isLoading ? context.t.signingIn : context.t.signIn),
              ),
            ),
            const SizedBox(height: 24),
            GoogleSignInButton(
              authService: widget.authService,
              onSignedIn: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.t.noAccount,
                  style: TextStyle(color: context.colors.muted),
                ),
                TextButton(
                  onPressed: openRegister,
                  child: Text(context.t.goToRegister),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Kontrola e-mailu ve formuláři. Vrátí text chyby, nebo null, když je vše v pořádku.
String? validateEmail(String? value, AppLocalizations t) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return t.fillEmail;
  if (!email.contains('@') || !email.contains('.')) {
    return t.emailInvalid;
  }
  return null;
}

// Hlavička přihlašovací a registrační obrazovky: logo a nadpis.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.coffee, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: context.colors.dark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.muted),
        ),
      ],
    );
  }
}
