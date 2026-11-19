import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/loyalty.dart';
import '../models/menu_category.dart';
import '../models/order.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../models/venue_settings.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/loyalty_card.dart';
import '../widgets/user_avatar.dart';
import 'login_screen.dart';
import '../l10n/language.dart';

// Záložka Profil: avatar, jméno, e-mail, razítková karta, změna hesla
// a odhlášení.
class ProfileScreen extends StatefulWidget {
  final AppServices services;

  // Objednávky zákazníka – z nich se počítají razítka na kartě.
  final List<Order> myOrders;

  const ProfileScreen({
    super.key,
    required this.services,
    this.myOrders = const [],
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Stream<User?> userStream;

  // Kategorie menu – kvůli názvu kategorie razítkové karty.
  late final Stream<List<MenuCategory>> categoriesStream;

  // Proud profilu – vytvoří se znovu, jen když se přihlásí někdo jiný.
  String? profileUserId;
  Stream<UserProfile>? profileStream;

  AuthService get auth => widget.services.auth;

  @override
  void initState() {
    super.initState();
    userStream = auth.userChanges();
    categoriesStream = widget.services.products.categories.watchCategories();
  }

  Stream<UserProfile> profileFor(User user) {
    if (user.uid != profileUserId || profileStream == null) {
      profileUserId = user.uid;
      profileStream = widget.services.users.watchProfile(user);
    }
    return profileStream!;
  }

  void openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(authService: auth)),
    );
  }

  Future<void> signOut() async {
    await auth.signOut();
    if (!mounted) return;
    showAppMessage(context, context.t.signedOut);
  }

  // Změna jména: v profilu (databáze) i v účtu (nové objednávky).
  Future<void> changeName(UserProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t.changeName),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: AppConfig.maxUserNameLength,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: context.t.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.t.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == profile.name) return;

    try {
      await widget.services.users.updateName(profile.uid, name);
      await auth.updateName(name);
      if (!mounted) return;
      showAppMessage(context, context.t.nameChanged);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, context.t.nameChangeFailed);
    }
  }

  Future<void> changeThemeMode(UserProfile profile, ThemeMode mode) async {
    try {
      await widget.services.users.updateThemeMode(profile.uid, mode);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, context.t.themeSaveFailed);
    }
  }

  Future<void> changePassword() async {
    final changed = await showChangePasswordDialog(context, auth);
    if (changed == true && mounted) {
      showAppMessage(context, context.t.passwordChanged);
    }
  }

  // Okno zespodu s výběrem ikonky a barvy avataru.
  Future<void> changeAvatar(UserProfile profile, User user) async {
    var icon = profile.avatarIcon;
    var color = profile.avatarColor;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      // StatefulBuilder = okno si samo pamatuje, co je zrovna vybrané.
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Možnosti: písmeno, fotka z Googlu (když ji má) a ikonky.
          final iconKeys = [
            'pismeno',
            if (user.photoURL != null) 'google',
            ...avatarIcons.keys,
          ];

          Widget option({
            required bool selected,
            required VoidCallback onTap,
            required Widget child,
            String? tooltip,
          }) {
            return Tooltip(
              message: tooltip ?? '',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? context.colors.dark : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: child,
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(
                    name: profile.name,
                    icon: icon,
                    color: color,
                    photoUrl: user.photoURL,
                    size: 88,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final key in iconKeys)
                        option(
                          selected: key == icon,
                          tooltip: key == 'google'
                              ? context.t.googlePhoto
                              : key == 'pismeno'
                                  ? context.t.letter
                                  : null,
                          onTap: () => setSheetState(() => icon = key),
                          child: UserAvatar(
                            name: profile.name,
                            icon: key,
                            color: color,
                            photoUrl: user.photoURL,
                            size: 44,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final key in avatarColors.keys)
                        option(
                          selected: key == color,
                          onTap: () => setSheetState(() => color = key),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: avatarColors[key],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.t.saveAvatar),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (saved != true) return;

    try {
      await widget.services.users.updateAvatar(profile.uid, icon, color);
      if (!mounted) return;
      showAppMessage(context, context.t.avatarSaved);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, context.t.avatarSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.navProfile)),
      body: StreamBuilder<User?>(
        stream: userStream,
        initialData: auth.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) {
            return EmptyState(
              icon: Icons.person_outline,
              title: context.t.signInTitle,
              message: context.t.signInForProfile,
              buttonText: context.t.signIn,
              onPressed: openLogin,
            );
          }
          return StreamBuilder<UserProfile>(
            stream: profileFor(user),
            builder: (context, profileSnapshot) {
              final profile = profileSnapshot.data;
              if (profile == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return buildProfile(profile, user);
            },
          );
        },
      ),
    );
  }

  Widget buildProfile(UserProfile profile, User user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar, jméno, e-mail a role.
        Center(
          child: Column(
            children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => changeAvatar(profile, user),
                child: UserAvatar(
                  name: profile.name,
                  icon: profile.avatarIcon,
                  color: profile.avatarColor,
                  photoUrl: user.photoURL,
                  size: 96,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.colors.dark,
                ),
              ),
              Text(
                profile.email,
                style: TextStyle(color: context.colors.muted),
              ),
              const SizedBox(height: 8),
              Chip(
                avatar: Icon(
                  hasGoogleLogin(user) ? Icons.g_mobiledata : Icons.mail_outline,
                  size: 18,
                ),
                label: Text(
                  '${roleText(context.t, profile.role)} • '
                  '${hasGoogleLogin(user) ? context.t.signedInWithGoogle : context.t.signedInWithEmail}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        buildLoyaltyCard(),
        buildThemePicker(profile),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.face, color: context.colors.primary),
                title: Text(context.t.changeAvatar),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => changeAvatar(profile, user),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.badge_outlined, color: context.colors.primary),
                title: Text(context.t.changeName),
                subtitle: Text(context.t.nameShownToStaff),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => changeName(profile),
              ),
              // Heslo si může změnit jen ten, kdo se přihlašuje e-mailem.
              if (hasPasswordLogin(user)) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.lock_outline, color: context.colors.primary),
                  title: Text(context.t.changePassword),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: changePassword,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: Text(context.t.signOut),
          onPressed: signOut,
        ),
      ],
    );
  }

  // Razítková karta – jen když ji admin zapnul.
  Widget buildLoyaltyCard() {
    final venue = VenueScope.of(context);
    if (!venue.hasLoyalty) return const SizedBox.shrink();

    final status = loyaltyStatus(
      widget.myOrders,
      categoryId: venue.loyaltyCategoryId,
      goal: venue.loyaltyGoal,
    );
    return StreamBuilder<List<MenuCategory>>(
      stream: categoriesStream,
      builder: (context, snapshot) {
        var categoryName = '';
        for (final category in snapshot.data ?? <MenuCategory>[]) {
          if (category.id == venue.loyaltyCategoryId) {
            categoryName = category.name;
          }
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: LoyaltyCard(status: status, categoryName: categoryName),
        );
      },
    );
  }

  // Vzhled aplikace: světlý / podle zařízení / tmavý. Ukládá se k účtu.
  Widget buildThemePicker(UserProfile profile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.appearance,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.colors.dark,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(context.t.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_outlined),
                    label: Text(context.t.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(context.t.themeDark),
                  ),
                ],
                selected: {profile.themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (selected) =>
                    changeThemeMode(profile, selected.first),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.t.language,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.colors.dark,
              ),
            ),
            const SizedBox(height: 12),
            // Jazyk aplikace (platí jen v tomto zařízení, dokud se aplikace
            // nezavře – pak zase podle telefonu).
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cs', label: Text('Čeština')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {context.t.localeName},
                showSelectedIcon: false,
                onSelectionChanged: (selected) =>
                    appLanguage.value = Locale(selected.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Název role v jazyce aplikace (v profilu zákazníka).
String roleText(AppLocalizations t, UserRole role) {
  if (role.isAdmin) return t.roleAdmin;
  if (role.canServe) return t.roleStaff;
  return t.roleCustomer;
}
