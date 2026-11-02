import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_theme.dart';
import '../../models/document_type.dart';
import '../../models/profile_update.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../utils/date_formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/password_field.dart';

/// Perfil del usuario autenticado (cualquier rol): datos personales
/// editables y cambio de contraseña.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _AccountHeader(profile: profile),
                const SizedBox(height: 24),
                if (auth.errorMessage != null)
                  ErrorBanner(message: auth.errorMessage!, onDismiss: auth.clearError),
                // key: si el perfil cambia desde fuera, el formulario se reinicia.
                _PersonalDataForm(key: ValueKey(profile.id), profile: profile),
                const SizedBox(height: 24),
                const _ChangePasswordForm(),
              ],
            ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final initial = profile.fullName.trim().isEmpty
        ? profile.email.characters.first
        : profile.fullName.trim().characters.first;
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: colors.primaryContainer,
          child: Text(
            initial.toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(color: colors.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName.trim().isEmpty ? 'Sin nombre' : profile.fullName,
                style: theme.textTheme.titleLarge,
              ),
              Text(profile.email, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                profile.role?.label ?? 'Pendiente de aprobación',
                style: theme.textTheme.labelLarge?.copyWith(color: colors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonalDataForm extends StatefulWidget {
  const _PersonalDataForm({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<_PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends State<_PersonalDataForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
      TextEditingController(text: widget.profile.fullName);
  late final TextEditingController _documentController =
      TextEditingController(text: widget.profile.documentNumber ?? '');
  late final TextEditingController _phoneController =
      TextEditingController(text: widget.profile.phone ?? '');
  late DocumentType _documentType = widget.profile.documentType ?? DocumentType.cc;
  late DateTime? _birthDate = widget.profile.birthDate;
  String? _birthDateError;

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateError = null;
      });
    }
  }

  Future<void> _save() async {
    final birthError = Validators.birthDate(_birthDate);
    setState(() => _birthDateError = birthError);
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || birthError != null) return;
    FocusScope.of(context).unfocus();

    final saved = await context.read<AuthProvider>().updateProfile(
          ProfileUpdate(
            fullName: _nameController.text,
            documentType: _documentType,
            documentNumber: _documentController.text,
            phone: _phoneController.text,
            birthDate: _birthDate,
          ),
        );
    if (saved && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Datos guardados')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    const gap = SizedBox(height: 14);

    return _Section(
      title: 'Datos personales',
      description: 'Los usa la clínica para identificarte en recepción.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              validator: Validators.fullName,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            gap,
            DropdownButtonFormField<DocumentType>(
              initialValue: _documentType,
              decoration: const InputDecoration(labelText: 'Tipo de documento'),
              items: [
                for (final type in DocumentType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _documentType = value);
              },
            ),
            gap,
            TextFormField(
              controller: _documentController,
              validator: Validators.documentNumber,
              decoration: const InputDecoration(labelText: 'Número de documento'),
            ),
            gap,
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
              decoration: const InputDecoration(labelText: 'Celular'),
            ),
            gap,
            InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  errorText: _birthDateError,
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  _birthDate == null
                      ? 'Sin registrar'
                      : DateFormatters.longDate(_birthDate!),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 20),
            LoadingButton(label: 'Guardar datos', isLoading: auth.isBusy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm();

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    final changed = await context.read<AuthProvider>().changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (changed) {
      _formKey.currentState?.reset();
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
    }
  }

  @override
  Widget build(BuildContext context) => _Section(
        title: 'Contraseña',
        description: 'Para cambiarla te pedimos la actual.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(
                controller: _currentController,
                label: 'Contraseña actual',
                textInputAction: TextInputAction.next,
                validator: (value) => Validators.required(value, 'La contraseña actual'),
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _newController,
                label: 'Nueva contraseña',
                isNewPassword: true,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final error = Validators.password(value);
                  if (error != null) return error;
                  return value == _currentController.text
                      ? 'Debe ser distinta de la actual'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirmController,
                label: 'Confirmar nueva contraseña',
                isNewPassword: true,
                validator: (value) => value == _newController.text
                    ? null
                    : 'Las contraseñas no coinciden',
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              LoadingButton(
                label: 'Cambiar contraseña',
                isLoading: _isSaving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.description, required this.child});

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              description,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
