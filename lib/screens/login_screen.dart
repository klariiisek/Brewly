import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/google_sign_in_button.dart';
import 'register_screen.dart';

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
      showAppMessage(context, 'Vítejte zpět!');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, authErrorMessage(error));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showAppMessage(context, 'Nejdřív vyplňte e-mail');
      return;
    }
    try {
      await widget.authService.sendPasswordReset(email);
      if (!mounted) return;
      // Firebase z bezpečnostních důvodů neprozradí, jestli účet s e-mailem
      // existuje, proto hláška říká "pokud".
      showAppMessage(
        context,
        'Pokud k e-mailu existuje účet, poslali jsme odkaz pro nové heslo',
      );
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, authErrorMessage(error));
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
            const AuthHeader(
              title: 'Přihlášení',
              subtitle: 'Přihlaste se a objednávejte přímo ke stolu.',
            ),
            const SizedBox(height: 32),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Heslo',
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
                        ? 'Vyplňte heslo'
                        : null,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: resetPassword,
                child: const Text('Zapomenuté heslo?'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : signIn,
                child: Text(isLoading ? 'Přihlašuji…' : 'Přihlásit se'),
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
                const Text(
                  'Nemáte účet?',
                  style: TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: openRegister,
                  child: const Text('Zaregistrujte se'),
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
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Vyplňte e-mail';
  if (!email.contains('@') || !email.contains('.')) {
    return 'E-mail nemá správný tvar';
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
            color: AppColors.coffee,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.coffee, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.darkCoffee,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    );
  }
}
