import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/routes/app_routes.dart';
import '../../models/staff_member.dart';
import '../../models/user_role.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/error_banner.dart';
import 'widgets/assign_role_sheet.dart';

enum _StaffFilter {
  pending('Pendientes'),
  doctors('Médicos'),
  reception('Recepción'),
  admins('Admins');

  const _StaffFilter(this.label);
  final String label;
}

/// Lista del personal con filtros. Desde aquí se aprueban cuentas,
/// se asignan roles y se entra a los horarios de cada médico.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  _StaffFilter _filter = _StaffFilter.pending;

  @override
  void initState() {
    super.initState();
    // Se carga después del primer frame para no notificar durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminProvider>().loadStaff());
  }

  List<StaffMember> _filtered(AdminProvider admin) => switch (_filter) {
        _StaffFilter.pending => admin.pending,
        _StaffFilter.doctors => admin.withRole(UserRole.doctor),
        _StaffFilter.reception => admin.withRole(UserRole.receptionist),
        _StaffFilter.admins => admin.withRole(UserRole.admin),
      };

  Future<void> _onMemberTap(StaffMember member) async {
    final doctor = member.doctor;
    if (member.isActiveDoctor && doctor != null) {
      await context.push(AppRoutes.doctorSchedulesPath(doctor.id));
      return;
    }
    if (member.role == UserRole.admin) return;
    await showAssignRoleSheet(context, member);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final members = _filtered(admin);

    return Scaffold(
      appBar: AppBar(title: const Text('Personal')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                for (final filter in _StaffFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter == _StaffFilter.pending && admin.pending.isNotEmpty
                            ? '${filter.label} (${admin.pending.length})'
                            : filter.label,
                      ),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          if (admin.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ErrorBanner(message: admin.errorMessage!, onDismiss: admin.clearError),
            ),
          Expanded(
            child: admin.isLoading && admin.staff.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: admin.loadStaff,
                    child: members.isEmpty
                        ? _EmptyState(filter: _filter)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: members.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (_, index) => _StaffTile(
                              member: members[index],
                              onTap: () => _onMemberTap(members[index]),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.member, required this.onTap});

  final StaffMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final doctor = member.doctor;
    final subtitle = member.isActiveDoctor && doctor != null
        ? '${doctor.specialtyName} · RM ${doctor.licenseNumber}'
        : member.profile.email;
    final trailing = switch (member) {
      _ when member.isPending => const Chip(label: Text('Aprobar')),
      _ when member.isActiveDoctor => const Icon(Icons.schedule_rounded),
      _ when member.role == UserRole.admin => null,
      _ => const Icon(Icons.edit_outlined),
    };

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(child: Text(member.displayName.characters.first.toUpperCase())),
        title: Text(member.displayName),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: member.role == UserRole.admin ? null : onTap,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final _StaffFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _StaffFilter.pending =>
        'No hay cuentas pendientes.\nCrea la cuenta del personal en Supabase '
            '(Authentication → Add user) con un correo de la clínica y aparecerá aquí.',
      _StaffFilter.doctors => 'Aún no hay médicos registrados.',
      _StaffFilter.reception => 'Aún no hay personal de recepción.',
      _StaffFilter.admins => 'No hay administradores.',
    };
    // ListView para que RefreshIndicator funcione también sin elementos.
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Icon(Icons.inbox_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}
