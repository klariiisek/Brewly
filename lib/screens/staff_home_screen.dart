import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../models/reservation.dart';
import '../models/service_request.dart';
import '../models/shift.dart';
import '../models/user_role.dart';
import '../models/venue_settings.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_message.dart';
import '../widgets/upcoming_reservations_banner.dart';
import 'admin_menu_screen.dart';
import 'attendance_overview_screen.dart';
import 'attendance_screen.dart';
import 'employees_screen.dart';
import 'main_screen.dart';
import 'staff_reservations_screen.dart';
import 'staff_screen.dart';
import 'staff_tables_screen.dart';
import 'statistics_screen.dart';
import 'venue_settings_screen.dart';

// Pevné barvy dlaždic. Záměrně se NEMĚNÍ podle palety podniku: každý nástroj
// má pořád stejnou barvu, takže si ji obsluha zapamatuje a najde ho
// i bez čtení („statistiky jsou ty zelené“).
class ToolColors {
  static const orders = Color(0xFF6F4E37); // hnědá
  static const menu = Color(0xFFD08B45); // oranžová
  static const statistics = Color(0xFF7DB25B); // zelená
  static const attendance = Color(0xFF4FAE8F); // tyrkysová
  static const venue = Color(0xFF5C6BC0); // modrá
  static const tables = Color(0xFFAB5CB8); // fialová
  static const employees = Color(0xFFD9667A); // růžová
  static const reservations = Color(0xFFE0A030); // žlutá
}

// Úvodní obrazovka pro obsluhu a admina: místo menu pro zákazníky
// rychlý přehled (otevřeno, čísla dne) a barevné dlaždice s nástroji.
class StaffHomeScreen extends StatefulWidget {
  final User user;
  final UserRole role;
  final Cart cart;
  final AppServices services;

  const StaffHomeScreen({
    super.key,
    required this.user,
    required this.role,
    required this.cart,
    required this.services,
  });

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  // Aktivní a dnešní objednávky (stejné jako vidí obsluha).
  late final Stream<List<Order>> ordersStream;

  // Je zaměstnanec v práci? (jen obsluha – admin docházku nemá)
  late final Stream<ActiveShift?> shiftStream;

  // Pro červená čísla na dlaždicích (co čeká na vyřízení):
  // nevyřízené požadavky, rezervace a kdo je v práci (admin – zapomenuté
  // odchody).
  late final Stream<List<ServiceRequest>> requestsStream;
  late final Stream<List<Reservation>> reservationsStream;
  late final Stream<List<ActiveShift>> activeShiftsStream;

  bool get isAdmin => widget.role.isAdmin;

  @override
  void initState() {
    super.initState();
    ordersStream = widget.services.orders.watchStaffOrders();
    shiftStream = widget.services.attendance.watchActiveShift(widget.user.uid);
    requestsStream = widget.services.requests.watchPendingRequests();
    reservationsStream =
        widget.services.reservations.watchUpcomingReservations();
    // Docházku všech vidí jen admin; obsluze stačí prázdný seznam.
    activeShiftsStream = isAdmin
        ? widget.services.attendance.watchActiveShifts()
        : Stream.value(const []);
  }

  void open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Future<void> signOut() async {
    await widget.services.auth.signOut();
    if (!mounted) return;
    showAppMessage(context, 'Byli jste odhlášeni');
  }

  // Otevřeno / zavřeno. Když je zavřeno, zákazníci nemůžou objednávat.
  // Světlý / systémový / tmavý vzhled (obsluha a admin nemají Profil,
  // proto volba přímo tady). Ukládá se k účtu stejně jako v Profilu.
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      await widget.services.users.updateThemeMode(widget.user.uid, mode);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Vzhled se nepodařilo uložit');
    }
  }

  Future<void> setOpen(bool isOpen) async {
    try {
      await widget.services.settings.setOpen(isOpen);
      if (!mounted) return;
      showAppMessage(
        context,
        isOpen
            ? 'Otevřeno – zákazníci můžou objednávat'
            : 'Zavřeno – nové objednávky nejdou odeslat',
      );
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, 'Změnu se nepodařilo uložit');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              buildHeader(),
              const SizedBox(height: 16),
              buildOpenSwitch(),
              UpcomingReservationsBanner(
                reservationService: widget.services.reservations,
                margin: const EdgeInsets.only(top: 12),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Order>>(
                stream: ordersStream,
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? [];
                  return Column(
                    children: [
                      buildNumbers(orders),
                      const SizedBox(height: 32),
                      buildToolsWithBadges(orders),
                    ],
                  );
                },
              ),
              if (isAdmin) ...[
                const SizedBox(height: 32),
                // Admin si může menu vyzkoušet očima zákazníka.
                TextButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Zobrazit jako zákazník'),
                  onPressed: () => open(
                    MainScreen(cart: widget.cart, services: widget.services),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Pozdrav, jméno, podnik a odhlášení.
  Widget buildHeader() {
    final colors = context.colors;
    final venue = VenueScope.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dobrý den',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colors.dark,
                ),
              ),
              Text(
                '${userDisplayName(widget.user)} · ${venue.name} · '
                '${widget.role.label.toLowerCase()}',
                style: TextStyle(color: colors.muted),
              ),
            ],
          ),
        ),
        buildThemeButton(),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          icon: const Icon(Icons.logout),
          tooltip: 'Odhlásit se',
          onPressed: signOut,
        ),
      ],
    );
  }

  // Tlačítko se sluníčkem / měsícem – nabídne Světlý / Systém / Tmavý.
  Widget buildThemeButton() {
    final isDark = context.colors.isDark;
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Vzhled aplikace',
      onSelected: setThemeMode,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ThemeMode.light,
          child: ListTile(
            leading: Icon(Icons.light_mode_outlined),
            title: Text('Světlý'),
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.system,
          child: ListTile(
            leading: Icon(Icons.brightness_auto_outlined),
            title: Text('Systém'),
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: ListTile(
            leading: Icon(Icons.dark_mode_outlined),
            title: Text('Tmavý'),
          ),
        ),
      ],
      child: IgnorePointer(
        child: IconButton.filledTonal(
          icon: Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          ),
          onPressed: () {},
        ),
      ),
    );
  }

  // Otevřeno / zavřeno (smí přepnout obsluha i admin).
  Widget buildOpenSwitch() {
    final colors = context.colors;
    final isOpen = VenueScope.of(context).isOpen;
    final color =
        isOpen ? AppColors.success : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOpen ? 'Otevřeno' : 'Zavřeno – nejde objednávat',
              style: TextStyle(fontWeight: FontWeight.w600, color: colors.dark),
            ),
          ),
          Switch(value: isOpen, onChanged: setOpen),
        ],
      ),
    );
  }

  // Dvě živá čísla. Admin: tržba dnes + aktivní objednávky.
  // Obsluha: aktivní objednávky + od kdy je v práci.
  Widget buildNumbers(List<Order> orders) {
    final active =
        orders.where((order) => order.status != OrderStatus.dokoncena).length;
    final activeCard = NumberCard(
      icon: Icons.receipt_long,
      value: '$active',
      label: 'aktivní objednávky',
      onTap: () => open(StaffScreen(services: widget.services)),
    );

    if (isAdmin) {
      var revenue = 0.0;
      for (final order in orders) {
        if (order.status == OrderStatus.dokoncena && isToday(order.time)) {
          revenue += order.totalPrice;
        }
      }
      return Row(
        children: [
          Expanded(
            child: NumberCard(
              icon: Icons.payments_outlined,
              value: formatPrice(revenue),
              label: 'tržba dnes',
              onTap: () => open(StatisticsScreen(services: widget.services)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: activeCard),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: activeCard),
        const SizedBox(width: 10),
        Expanded(
          child: StreamBuilder<ActiveShift?>(
            stream: shiftStream,
            builder: (context, snapshot) {
              final shift = snapshot.data;
              return NumberCard(
                icon: Icons.schedule,
                value: shift == null ? '–' : 'od ${formatTime(shift.start)}',
                label: shift == null ? 'nejste v práci' : 'jste v práci',
                onTap: openAttendance,
              );
            },
          ),
        ),
      ],
    );
  }

  void openAttendance() {
    open(
      isAdmin
          ? AttendanceOverviewScreen(services: widget.services)
          : AttendanceScreen(services: widget.services, user: widget.user),
    );
  }

  // Spočítá, co na kterém nástroji čeká, a nakreslí dlaždice s čísly:
  // Objednávky = nové objednávky (Přijata) + nevyřízené požadavky,
  // Rezervace = čekající na potvrzení, Docházka (admin) = možná
  // zapomenuté odchody.
  Widget buildToolsWithBadges(List<Order> orders) {
    final newOrders =
        orders.where((order) => order.status == OrderStatus.prijata).length;
    return StreamBuilder<List<ServiceRequest>>(
      stream: requestsStream,
      builder: (context, requestsSnapshot) {
        final requests = requestsSnapshot.data?.length ?? 0;
        return StreamBuilder<List<Reservation>>(
          stream: reservationsStream,
          builder: (context, reservationsSnapshot) {
            final pendingReservations = (reservationsSnapshot.data ?? [])
                .where((r) => r.status == ReservationStatus.ceka)
                .length;
            return StreamBuilder<List<ActiveShift>>(
              stream: activeShiftsStream,
              builder: (context, shiftsSnapshot) {
                final forgottenShifts = (shiftsSnapshot.data ?? [])
                    .where((shift) =>
                        shift.elapsed.inHours >= AppConfig.forgottenShiftHours)
                    .length;
                return buildTools(
                  ordersBadge: newOrders + requests,
                  reservationsBadge: pendingReservations,
                  attendanceBadge: forgottenShifts,
                );
              },
            );
          },
        );
      },
    );
  }

  // Dlaždice s nástroji. Obsluha má jen objednávky, rezervace, docházku
  // a stoly.
  Widget buildTools({
    required int ordersBadge,
    required int reservationsBadge,
    required int attendanceBadge,
  }) {
    final services = widget.services;
    final tools = [
      ToolTile(
        icon: Icons.receipt_long,
        label: 'Objednávky',
        color: ToolColors.orders,
        badge: ordersBadge,
        onTap: () => open(StaffScreen(services: services)),
      ),
      ToolTile(
        icon: Icons.event_seat_outlined,
        label: 'Rezervace',
        color: ToolColors.reservations,
        badge: reservationsBadge,
        onTap: () => open(StaffReservationsScreen(services: services)),
      ),
      if (isAdmin)
        ToolTile(
          icon: Icons.edit_note,
          label: 'Menu',
          color: ToolColors.menu,
          onTap: () => open(AdminMenuScreen(services: services)),
        ),
      if (isAdmin)
        ToolTile(
          icon: Icons.bar_chart,
          label: 'Statistiky',
          color: ToolColors.statistics,
          onTap: () => open(StatisticsScreen(services: services)),
        ),
      ToolTile(
        icon: Icons.schedule,
        label: 'Docházka',
        color: ToolColors.attendance,
        badge: attendanceBadge,
        onTap: openAttendance,
      ),
      if (isAdmin)
        ToolTile(
          icon: Icons.groups_outlined,
          label: 'Zaměstnanci',
          color: ToolColors.employees,
          onTap: () => open(EmployeesScreen(services: services)),
        ),
      if (isAdmin)
        ToolTile(
          icon: Icons.storefront_outlined,
          label: 'Podnik',
          color: ToolColors.venue,
          onTap: () => open(VenueSettingsScreen(services: services)),
        ),
      ToolTile(
        icon: Icons.qr_code_2,
        label: 'Stoly',
        color: ToolColors.tables,
        // Obnovit kódy smí jen admin – obsluha je jen vidí.
        onTap: () => open(StaffTablesScreen(
          tableService: services.tables,
          canEdit: isAdmin,
        )),
      ),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 20,
      children: tools,
    );
  }
}

// Karta s jedním číslem (tržba, aktivní objednávky…). Klepnutím otevře detail.
class NumberCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  const NumberCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.primary, size: 20),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.dark,
                  ),
                ),
              ),
              Text(label, style: TextStyle(color: colors.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// Barevná dlaždice s ikonou a jedním slovem pod ní.
class ToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  // Číslo v rohu (např. čekající rezervace); 0 = bez čísla.
  final int badge;

  const ToolTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              offset: const Offset(-2, 2),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
