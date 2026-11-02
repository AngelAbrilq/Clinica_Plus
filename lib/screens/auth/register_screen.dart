import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/env.dart';
import '../../config/routes/app_routes.dart';
import '../../models/document_type.dart';
import '../../models/patient_sign_up_data.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/password_field.dart';

/// Registro de pacientes. El personal NO se registra aquí:
/// sus cuentas las crea el administrador.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  DocumentType _documentType = DocumentType.cc;
  bool _acceptedDataPolicy = false;
  bool _showConsentError = false;

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _documentController,
      _phoneController,
      _emailController,
      _passwordController,
      _confirmController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final error = Validators.email(value);
    if (error != null) return error;
    if (Validators.isStaffEmail(value!, Env.staffEmailDomain)) {
      return 'Las cuentas del personal las crea el administrador';
    }
    return null;
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showConsentError = !_acceptedDataPolicy);
    if (!isFormValid || !_acceptedDataPolicy) return;
    FocusScope.of(context).unfocus();

    final result = await context.read<AuthProvider>().signUpPatient(
      PatientSignUpData(
        fullName: _nameController.text,
        documentType: _documentType,
        documentNumber: _documentController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );

    if (!mounted || result != SignUpResult.emailConfirmationRequired) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_outlined),
        title: const Text('Confirma tu correo'),
        content: Text(
          'Enviamos un enlace a ${_emailController.text.trim()}. '
          'Ábrelo para activar tu cuenta y luego inicia sesión.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = Theme.of(context).colorScheme;
    const gap = SizedBox(height: 16);

    return AuthScaffold(
      showBackButton: true,
      title: 'Crear cuenta de paciente',
      subtitle: 'Regístrate para agendar tus citas',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.errorMessage != null)
                ErrorBanner(
                  message: auth.errorMessage!,
                  onDismiss: auth.clearError,
                ),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: Validators.fullName,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              gap,
              DropdownButtonFormField<DocumentType>(
                initialValue: _documentType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de documento',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
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
                textInputAction: TextInputAction.next,
                validator: Validators.documentNumber,
                decoration: const InputDecoration(
                  labelText: 'Número de documento',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
              ),
              gap,
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: Validators.phone,
                decoration: const InputDecoration(
                  labelText: 'Celular',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              gap,
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              gap,
              PasswordField(
                controller: _passwordController,
                isNewPassword: true,
                textInputAction: TextInputAction.next,
                validator: Validators.password,
              ),
              gap,
              PasswordField(
                controller: _confirmController,
                label: 'Confirmar contraseña',
                isNewPassword: true,
                validator: (value) => value == _passwordController.text
                    ? null
                    : 'Las contraseñas no coinciden',
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _acceptedDataPolicy,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) => setState(() {
                  _acceptedDataPolicy = value ?? false;
                  if (_acceptedDataPolicy) _showConsentError = false;
                }),
                title: const Text(
                  'Autorizo el tratamiento de mis datos personales y de salud '
                  'conforme a la Ley 1581 de 2012.',
                ),
                subtitle: _showConsentError
                    ? Text(
                        'Debes aceptar para crear tu cuenta',
                        style: TextStyle(color: colors.error),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              LoadingButton(
                label: 'Crear cuenta',
                isLoading: auth.isBusy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
