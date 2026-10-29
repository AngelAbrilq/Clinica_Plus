import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../models/specialty.dart';
import '../../../models/staff_member.dart';
import '../../../models/user_role.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_button.dart';

/// Abre el formulario para asignar rol (médico o recepción) a [member].
Future<void> showAssignRoleSheet(BuildContext context, StaffMember member) {
  context.read<AdminProvider>().clearError();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AdminProvider>(),
      child: _AssignRoleSheet(member: member),
    ),
  );
}

class _AssignRoleSheet extends StatefulWidget {
  const _AssignRoleSheet({required this.member});

  final StaffMember member;

  @override
  State<_AssignRoleSheet> createState() => _AssignRoleSheetState();
}

class _AssignRoleSheetState extends State<_AssignRoleSheet> {
  static final RegExp _licensePattern = RegExp(r'^[A-Za-z0-9-]{3,30}$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _licenseController =
      TextEditingController(text: widget.member.doctor?.licenseNumber ?? '');
  late UserRole _role =
      widget.member.role == UserRole.receptionist ? UserRole.receptionist : UserRole.doctor;
  late int? _specialtyId = widget.member.doctor?.specialtyId;

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final admin = context.read<AdminProvider>();
    final userId = widget.member.profile.id;

    final success = _role == UserRole.doctor
        ? await admin.registerDoctor(
            userId: userId,
            specialtyId: _specialtyId!,
            licenseNumber: _licenseController.text.trim(),
          )
        : await admin.assignRole(userId: userId, role: _role);

    if (!mounted || !success) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('${widget.member.displayName} ahora es ${_role.label}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Asignar rol', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(widget.member.profile.email, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            if (admin.errorMessage != null)
              ErrorBanner(message: admin.errorMessage!, onDismiss: admin.clearError),
            SegmentedButton<UserRole>(
              segments: const [
                ButtonSegment(
                  value: UserRole.doctor,
                  label: Text('Médico'),
                  icon: Icon(Icons.medical_services_outlined),
                ),
                ButtonSegment(
                  value: UserRole.receptionist,
                  label: Text('Recepción'),
                  icon: Icon(Icons.support_agent_outlined),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (selection) => setState(() => _role = selection.first),
            ),
            if (_role == UserRole.doctor) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _specialtyId,
                decoration: const InputDecoration(
                  labelText: 'Especialidad',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
                items: [
                  for (final Specialty specialty in admin.specialties)
                    DropdownMenuItem(value: specialty.id, child: Text(specialty.name)),
                ],
                validator: (value) => value == null ? 'Elige una especialidad' : null,
                onChanged: (value) => setState(() => _specialtyId = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Registro médico (RETHUS)',
                  hintText: 'Ej: RM-12345',
                  prefixIcon: Icon(Icons.verified_outlined),
                ),
                validator: (value) {
                  final license = value?.trim() ?? '';
                  if (license.isEmpty) return 'El registro médico es obligatorio';
                  if (!_licensePattern.hasMatch(license)) {
                    return 'Solo letras, números y guiones (3 a 30)';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            LoadingButton(label: 'Guardar', isLoading: admin.isSaving, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
