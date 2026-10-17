import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_avatar.dart';
import 'login_screen.dart';

// Záložka Profil: avatar, jméno, e-mail, změna hesla a odhlášení.
class ProfileScreen extends StatefulWidget {
  final AppServices services;

  const ProfileScreen({super.key, required this.services});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Stream<User?> userStream;

  // Proud profilu – vytvoří se znovu, jen když se přihlásí někdo jiný.
  String? profileUserId;
  Stream<UserProfile>? profileStream;

  AuthService get auth => widget.services.auth;

  @override
  void initState() {
    super.initState();
    userStream = auth.userChanges();
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
    showAppMessage(context, 'Byli jste odhlášeni');
  }

  // Změna jména: v profilu (databáze) i v účtu (nové objednávky).
  Future<void> changeName(UserProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Změnit jméno'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Jméno'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == profile.name) return;

    try {
      await widget.services.users.updateName(profile.uid, name);
      await auth.updateName(name);
      if (!mounted) return;
      showAppMessage(context, 'Jméno změněno');
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Jméno se nepodařilo změnit');
    }
  }

  Future<void> changePassword() async {
    final changed = await showChangePasswordDialog(context, auth);
    if (changed == true && mounted) {
      showAppMessage(context, 'Heslo změněno');
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
                              ? 'Fotka z Google'
                              : key == 'pismeno'
                                  ? 'Písmeno'
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
                      child: const Text('Uložit avatar'),
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
      showAppMessage(context, 'Avatar uložen');
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Avatar se nepodařilo uložit');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: StreamBuilder<User?>(
        stream: userStream,
        initialData: auth.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) {
            return EmptyState(
              icon: Icons.person_outline,
              title: 'Přihlaste se',
              message: 'Po přihlášení si tu můžete upravit svůj profil.',
              buttonText: 'Přihlásit se',
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
                  '${profile.role.label} • '
                  '${hasGoogleLogin(user) ? 'přihlášení přes Google' : 'přihlášení e-mailem'}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.face, color: context.colors.primary),
                title: const Text('Změnit avatar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => changeAvatar(profile, user),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.badge_outlined, color: context.colors.primary),
                title: const Text('Změnit jméno'),
                subtitle: const Text('Toto jméno uvidí obsluha u objednávky'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => changeName(profile),
              ),
              // Heslo si může změnit jen ten, kdo se přihlašuje e-mailem.
              if (hasPasswordLogin(user)) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.lock_outline, color: context.colors.primary),
                  title: const Text('Změnit heslo'),
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
          label: const Text('Odhlásit se'),
          onPressed: signOut,
        ),
      ],
    );
  }
}
