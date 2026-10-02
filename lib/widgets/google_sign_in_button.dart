import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'app_message.dart';

// Tlačítko "Pokračovat přes Google" s oddělovačem "nebo" nad sebou.
// Používá se na přihlašovací i registrační obrazovce.
class GoogleSignInButton extends StatefulWidget {
  final AuthService authService;

  // Zavolá se, když se uživatel úspěšně přihlásí.
  final VoidCallback onSignedIn;

  const GoogleSignInButton({
    super.key,
    required this.authService,
    required this.onSignedIn,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool isLoading = false;

  Future<void> signIn() async {
    setState(() => isLoading = true);
    try {
      final signedIn = await widget.authService.signInWithGoogle();
      if (!mounted) return;
      if (signedIn) {
        showAppMessage(context, 'Přihlášení přes Google proběhlo úspěšně');
        widget.onSignedIn();
      }
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, authErrorMessage(error));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Oddělovač: ——— nebo ———
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('nebo', style: TextStyle(color: AppColors.muted)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : signIn,
            // Písmeno G v barvě Googlu místo loga (logo by byl další obrázek).
            icon: const Text(
              'G',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4285F4),
              ),
            ),
            label: Text(isLoading ? 'Přihlašuji…' : 'Pokračovat přes Google'),
          ),
        ),
      ],
    );
  }
}
