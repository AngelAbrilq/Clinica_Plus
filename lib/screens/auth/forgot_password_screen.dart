import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final sent = await context.read<AuthProvider>().sendPasswordReset(_emailController.text);
    if (mounted && sent) setState(() => _emailSent = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AuthScaffold(
      showBackButton: true,
      title: 'Recuperar contraseña',
      subtitle: 'Te enviaremos un enlace para crear una nueva',
      child: _emailSent
          ? Card(
              child: ListTile(
                leading: const Icon(Icons.mark_email_read_outlined),
                title: const Text('Revisa tu correo'),
                subtitle: Text(
                  'Si ${_emailController.text.trim()} está registrado, '
                  'recibirás el enlace en unos minutos.',
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (auth.errorMessage != null)
                    ErrorBanner(message: auth.errorMessage!, onDismiss: auth.clearError),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LoadingButton(
                    label: 'Enviar enlace',
                    isLoading: auth.isBusy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
