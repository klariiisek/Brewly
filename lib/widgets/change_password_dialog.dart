import 'package:flutter/material.dart';

import '../services/auth_service.dart';

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
        errorMessage = authErrorMessage(error);
      });
    }
  }

  InputDecoration decoration(String label) {
    return InputDecoration(labelText: label);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Změnit heslo'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                obscureText: !showPasswords,
                decoration: decoration('Současné heslo'),
                validator: (value) => (value ?? '').isEmpty
                    ? 'Zadejte současné heslo'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newController,
                obscureText: !showPasswords,
                decoration: decoration('Nové heslo'),
                validator: (value) {
                  final password = value ?? '';
                  if (password.length < 6) return 'Alespoň 6 znaků';
                  if (password == currentController.text) {
                    return 'Nové heslo je stejné jako současné';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: !showPasswords,
                decoration: decoration('Nové heslo znovu'),
                validator: (value) => value != newController.text
                    ? 'Hesla se neshodují'
                    : null,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: showPasswords,
                title: const Text('Zobrazit hesla'),
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
          child: const Text('Zrušit'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : save,
          child: Text(isSaving ? 'Ukládám…' : 'Změnit heslo'),
        ),
      ],
    );
  }
}
