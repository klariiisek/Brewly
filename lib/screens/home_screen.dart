import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/user_role.dart';
import '../models/venue_settings.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/venue_hero.dart';
import '../widgets/venue_info_sheet.dart';
import 'admin_menu_screen.dart';
import 'attendance_overview_screen.dart';
import 'attendance_screen.dart';
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
    // Pozadí se vzorem podle typu podniku dostává každá stránka z tématu
    // (viz venue_pattern.dart).
    return Scaffold(
      body: SafeArea(
        // Obrazovka se překreslí, když se někdo přihlásí nebo odhlásí.
        child: StreamBuilder<User?>(
          stream: userStream,
          // Než proud pošle první hodnotu, použije se aktuálně přihlášený uživatel.
          initialData: widget.services.auth.currentUser,
          builder: (context, snapshot) {
            final user = snapshot.data;
            // Na velké obrazovce (počítač) zůstane obsah úzký uprostřed,
            // na malé se dá posouvat.
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      buildWelcome(user),
                      const SizedBox(height: 28),
                      buildButtons(user),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Horní část: ilustrace v kruhu, název, slogan, stav a oznámení.
  // Při otevření obrazovky plynule „vyjede“ (průhlednost + posun).
  Widget buildWelcome(User? user) {
    // Název, slogan a ilustrace podle nastavení podniku (mění je admin).
    final venue = VenueScope.of(context);
    final colors = context.colors;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: child,
        ),
      ),
      child: Column(
        children: [
          // Ilustrace v měkkém kruhu – jako na talířku.
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                colors: [
                  Colors.white,
                  Color.alphaBlend(
                    colors.primary.withValues(alpha: 0.12),
                    colors.background,
                  ),
                ],
                stops: const [0.25, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: VenueHero(type: venue.type, size: 178),
          ),
          const SizedBox(height: 22),
          Text(
            venue.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: colors.dark,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            venue.slogan,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: colors.muted),
          ),
          if (user != null) ...[
            const SizedBox(height: 6),
            Text(
              'Vítejte, ${userDisplayName(user)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          buildStatusRow(venue),
          // Oznámení od podniku (např. sleva dne) – vidět hned na úvodu.
          if (venue.announcement.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Row(
                children: [
                  Icon(Icons.campaign_outlined, color: colors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      venue.announcement,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.dark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Štítek Otevřeno / Zavřeno a vedle první řádek otevírací doby.
  Widget buildStatusRow(VenueSettings venue) {
    final color = venue.isOpen
        ? AppColors.success
        : Theme.of(context).colorScheme.error;
    final hours = venue.openingHours.split('\n').first.trim();

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 6),
              Text(
                venue.isOpen ? 'Otevřeno' : 'Zavřeno',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (hours.isNotEmpty)
          Text(
            hours,
            style: TextStyle(fontSize: 13, color: context.colors.muted),
          ),
      ],
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
                  builder: (context) =>
                      MainScreen(cart: widget.cart, services: widget.services),
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
        // Když má podnik vlastní název, připomeneme, na čem aplikace běží.
        if (VenueScope.of(context).name != 'Brewly') ...[
          const SizedBox(height: 16),
          Text(
            'powered by Brewly',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.6,
              color: context.colors.muted.withValues(alpha: 0.8),
            ),
          ),
        ],
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
                onPressed: () =>
                    openScreen(StaffScreen(services: widget.services)),
              ),
              // Docházku si zapisuje obsluha, admin vidí přehled všech.
              TextButton.icon(
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(role.isAdmin ? 'Docházka zaměstnanců' : 'Docházka'),
                onPressed: () => openScreen(
                  role.isAdmin
                      ? AttendanceOverviewScreen(services: widget.services)
                      : AttendanceScreen(services: widget.services, user: user),
                ),
              ),
              // Správa menu a nastavení podniku jen pro admina.
              if (role.isAdmin) ...[
                TextButton.icon(
                  icon: const Icon(Icons.edit_note, size: 20),
                  label: const Text('Správa menu'),
                  onPressed: () =>
                      openScreen(AdminMenuScreen(services: widget.services)),
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
