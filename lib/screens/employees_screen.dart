import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../utils/text.dart';
import '../widgets/app_message.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_avatar.dart';

// Správa zaměstnanců pro admina: nahoře obsluha, pod ní zákazníci.
// Nový zaměstnanec se zaregistruje jako zákazník a admin mu tady
// jedním klepnutím dá roli „obsluha“ (dřív se to dělalo ve Firebase konzoli).
class EmployeesScreen extends StatefulWidget {
  final AppServices services;

  const EmployeesScreen({super.key, required this.services});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late final Stream<List<UserProfile>> usersStream;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    usersStream = widget.services.users.watchAllUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String get myUid => widget.services.auth.currentUser?.uid ?? '';

  Future<void> setRole(UserProfile user, UserRole role) async {
    try {
      await widget.services.users.setRole(user.uid, role);
      if (!mounted) return;
      showAppMessage(
        context,
        role == UserRole.obsluha
            ? '${user.name} je teď v obsluze'
            : '${user.name} je teď zákazník',
      );
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Roli se nepodařilo změnit');
    }
  }

  // Potvrzení před změnou role (aby se to nestalo omylem).
  Future<void> confirmRole(UserProfile user, UserRole role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(role == UserRole.obsluha
            ? 'Přidat ${user.name} do obsluhy?'
            : 'Odebrat ${user.name} z obsluhy?'),
        content: Text(role == UserRole.obsluha
            ? 'Uvidí objednávky a požadavky zákazníků, bude si zapisovat '
                'docházku a uvidí QR kódy stolů.'
            : 'Stane se z něj zákazník – objednávky a docházku už neuvidí. '
                'Jeho odpracované směny zůstanou uložené.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(role == UserRole.obsluha ? 'Přidat' : 'Odebrat'),
          ),
        ],
      ),
    );
    if (confirmed == true) await setRole(user, role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zaměstnanci')),
      body: StreamBuilder<List<UserProfile>>(
        stream: usersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.cloud_off,
              title: 'Účty se nepodařilo načíst',
              message: 'Zkontrolujte připojení k internetu.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          final staff = users.where((user) => user.role.canServe).toList();
          // Zákazníků může být hodně – vyhledávání podle jména nebo e-mailu.
          final query = normalizeText(searchController.text.trim());
          final customers = users
              .where((user) => !user.role.canServe)
              .where((user) =>
                  query.isEmpty ||
                  normalizeText('${user.name} ${user.email}').contains(query))
              .toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  buildTitle('Obsluha a admin (${staff.length})'),
                  for (final user in staff) buildUserTile(user),
                  const SizedBox(height: 20),
                  buildTitle('Přidat do obsluhy'),
                  Text(
                    'Nový zaměstnanec se nejdřív zaregistruje v aplikaci. '
                    'Pak ho tady najdete a přidáte do obsluhy.',
                    style: TextStyle(color: context.colors.muted),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Hledat jméno nebo e-mail',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (customers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Nikdo takový nenalezen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.muted),
                      ),
                    ),
                  for (final user in customers) buildUserTile(user),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: context.colors.dark,
        ),
      ),
    );
  }

  // Řádek účtu: avatar, jméno, e-mail a tlačítko pro změnu role.
  // Sebe ani jiného admina měnit nejde (adminy nastavuje vývojář v konzoli).
  Widget buildUserTile(UserProfile user) {
    final isMe = user.uid == myUid;
    final Widget trailing;
    if (user.role.isAdmin) {
      trailing = Chip(label: Text(isMe ? 'Admin (vy)' : 'Admin'));
    } else if (user.role == UserRole.obsluha) {
      trailing = TextButton(
        onPressed: () => confirmRole(user, UserRole.zakaznik),
        child: const Text('Odebrat'),
      );
    } else {
      trailing = OutlinedButton.icon(
        icon: const Icon(Icons.person_add_alt, size: 18),
        label: const Text('Do obsluhy'),
        onPressed: () => confirmRole(user, UserRole.obsluha),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: UserAvatar(
          name: user.name,
          icon: user.avatarIcon == 'google' ? 'pismeno' : user.avatarIcon,
          color: user.avatarColor,
          size: 40,
        ),
        title: Text(user.name.isEmpty ? user.email : user.name),
        subtitle: Text(user.email),
        trailing: trailing,
      ),
    );
  }
}
