import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/user_role.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'staff_screen.dart';

class HomeScreen extends StatefulWidget {
  final Cart cart;
  final AppServices services;

  const HomeScreen({super.key, required this.cart, required this.services});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Proud přihlášeného uživatele (null = nikdo není přihlášený).
  late final Stream<User?> userStream;

  @override
  void initState() {
    super.initState();
    userStream = widget.services.auth.userChanges();
  }

  // Proud role přihlášeného uživatele. Vytvoří se znovu jen tehdy,
  // když se přihlásí někdo jiný.
  String? roleUserId;
  Stream<UserRole>? roleStream;

  Stream<UserRole> roleFor(User user) {
    if (user.uid != roleUserId || roleStream == null) {
      roleUserId = user.uid;
      roleStream = widget.services.users.watchRole(user);
    }
    return roleStream!;
  }

  Future<void> signOut() async {
    await widget.services.auth.signOut();
    if (!mounted) return;
    showAppMessage(context, 'Byli jste odhlášeni');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          // Obrazovka se překreslí, když se někdo přihlásí nebo odhlásí.
          child: StreamBuilder<User?>(
            stream: userStream,
            // Než proud pošle první hodnotu, použije se aktuálně přihlášený uživatel.
            initialData: widget.services.auth.currentUser,
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Column(
                children: [
                  // Horní část: logo, název a uvítání.
                  Expanded(child: buildWelcome(user)),
                  // Spodní část: tlačítka.
                  buildButtons(user),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildWelcome(User? user) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo: hnědý čtverec s kulatými rohy a bílým šálkem.
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.coffee,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.coffee, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Brewly',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.darkCoffee,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user == null
                ? 'Vítejte v naší kavárně'
                : 'Vítejte, ${userDisplayName(user)}',
            style: const TextStyle(fontSize: 17, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget buildButtons(User? user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MainScreen(
                    cart: widget.cart,
                    services: widget.services,
                  ),
                ),
              );
            },
            child: const Text('Prohlédnout menu'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          // Podle toho, jestli je někdo přihlášený: Přihlásit / Odhlásit.
          child: user == null
              ? OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LoginScreen(authService: widget.services.auth),
                      ),
                    );
                  },
                  child: const Text('Přihlásit se'),
                )
              : OutlinedButton(
                  onPressed: signOut,
                  child: const Text('Odhlásit se'),
                ),
        ),
        // Vstup pro obsluhu vidí jen přihlášený uživatel s rolí "obsluha".
        if (user != null) buildStaffEntry(user),
      ],
    );
  }

  Widget buildStaffEntry(User user) {
    return StreamBuilder<UserRole>(
      stream: roleFor(user),
      builder: (context, snapshot) {
        if (snapshot.data != UserRole.obsluha) {
          return const SizedBox.shrink(); // nic nezobrazí
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextButton.icon(
            icon: const Icon(Icons.badge_outlined, size: 18),
            label: const Text('Vstup pro obsluhu'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StaffScreen(orderService: widget.services.orders),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
