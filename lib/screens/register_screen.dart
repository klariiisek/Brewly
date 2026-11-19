import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/app_message.dart';
import '../widgets/google_sign_in_button.dart';
import 'login_screen.dart';
import '../l10n/language.dart';

// Registrace nového účtu. Po úspěchu se obrazovka zavře a vrátí true
// (uživatel je po registraci rovnou přihlášený).
class RegisterScreen extends StatefulWidget {
  final AuthService authService;

  const RegisterScreen({super.key, required this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      await widget.authService.register(
        nameController.text,
        emailController.text,
        passwordController.text,
      );
      if (!mounted) return;
      showAppMessage(context, context.t.accountCreated);
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, authErrorMessage(error, context.t));
    } finally {
      if (mounted) setState(() => isLoading = false);
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
              title: context.t.registerTitle,
              subtitle: context.t.registerSubtitle,
            ),
            const SizedBox(height: 32),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: context.t.name,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? context.t.fillName
                            : null,
                  ),
                  const SizedBox(height: 16),
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
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.t.passwordMin,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: (value) => (value == null || value.length < 6)
                        ? context.t.passwordTooShort
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.t.passwordAgain,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: (value) => value != passwordController.text
                        ? context.t.passwordsDontMatch
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : register,
                child: Text(
                  isLoading ? context.t.creatingAccount : context.t.signUp,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Přes Google se registrace nevyplňuje – účet se založí sám.
            GoogleSignInButton(
              authService: widget.authService,
              onSignedIn: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
  }
}
