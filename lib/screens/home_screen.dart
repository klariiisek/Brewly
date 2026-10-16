import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/user_role.dart';
import '../models/venue_settings.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/venue_info_sheet.dart';
import 'admin_menu_screen.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'staff_screen.dart';
import 'venue_settings_screen.dart';

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
    // Název, slogan a ikona podle nastavení podniku (mění je admin).
    final venue = VenueScope.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo: barevný čtverec s kulatými rohy a ikonou podle typu podniku.
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(venue.type.icon, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            venue.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: context.colors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user == null
                ? venue.slogan
                : 'Vítejte, ${userDisplayName(user)}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: context.colors.muted),
          ),
          // Když má podnik vlastní název, připomeneme, na čem aplikace běží.
          if (venue.name != 'Brewly') ...[
            const SizedBox(height: 16),
            Text(
              'powered by Brewly',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                color: context.colors.muted.withValues(alpha: 0.7),
              ),
            ),
          ],
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
        // Adresa, otevírací doba, Wi-Fi – jen když je admin vyplnil.
        if (VenueScope.of(context).hasInfo)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('Informace o podniku'),
              onPressed: () => showVenueInfo(context),
            ),
          ),
        // Vstupy pro zaměstnance vidí jen přihlášený s rolí obsluha nebo admin.
        if (user != null) buildStaffEntry(user),
      ],
    );
  }

  Widget buildStaffEntry(User user) {
    return StreamBuilder<UserRole>(
      stream: roleFor(user),
      builder: (context, snapshot) {
        final role = snapshot.data ?? UserRole.zakaznik;
        if (!role.canServe) {
          return const SizedBox.shrink(); // zákazník nic nevidí
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          // Wrap = tlačítka vedle sebe, a když se nevejdou, pod sebe.
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Vstup pro obsluhu'),
                onPressed: () => openScreen(
                  StaffScreen(services: widget.services),
                ),
              ),
              // Správa menu a nastavení podniku jen pro admina.
              if (role.isAdmin) ...[
                TextButton.icon(
                  icon: const Icon(Icons.edit_note, size: 20),
                  label: const Text('Správa menu'),
                  onPressed: () => openScreen(
                    AdminMenuScreen(services: widget.services),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('Nastavení podniku'),
                  onPressed: () => openScreen(
                    VenueSettingsScreen(services: widget.services),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
