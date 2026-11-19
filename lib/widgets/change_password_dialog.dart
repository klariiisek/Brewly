import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../l10n/language.dart';

// Okno pro změnu hesla: současné heslo, nové heslo a jeho zopakování.
// Vrátí true, když se heslo změnilo.
Future<bool?> showChangePasswordDialog(
  BuildContext context,
  AuthService authService,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ChangePasswordDialog(authService: authService),
  );
}

class ChangePasswordDialog extends StatefulWidget {
  final AuthService authService;

  const ChangePasswordDialog({super.key, required this.authService});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final formKey = GlobalKey<FormState>();
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
  bool isSaving = false;
  bool showPasswords = false;

  // Chyba z Firebase (např. špatné současné heslo) – ukáže se v okně.
  String? errorMessage;

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      isSaving = true;
      errorMessage = null;
    });
    try {
      await widget.authService.changePassword(
        currentController.text,
        newController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
        errorMessage = authErrorMessage(error, context.t);
      });
    }
  }

  InputDecoration decoration(String label) {
    return InputDecoration(labelText: label);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.t.changePassword),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                obscureText: !showPasswords,
                decoration: decoration(context.t.currentPassword),
                validator: (value) => (value ?? '').isEmpty
                    ? context.t.enterCurrentPassword
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newController,
                obscureText: !showPasswords,
                decoration: decoration(context.t.newPassword),
                validator: (value) {
                  final password = value ?? '';
                  if (password.length < 6) return context.t.atLeast6;
                  if (password == currentController.text) {
                    return context.t.samePassword;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: !showPasswords,
                decoration: decoration(context.t.newPasswordAgain),
                validator: (value) => value != newController.text
                    ? context.t.passwordsDontMatch
                    : null,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: showPasswords,
                title: Text(context.t.showPasswords),
                onChanged: (value) =>
                    setState(() => showPasswords = value ?? false),
              ),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context, false),
          child: Text(context.t.cancel),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : save,
          child: Text(isSaving ? context.t.saving : context.t.changePassword),
        ),
      ],
    );
  }
}
