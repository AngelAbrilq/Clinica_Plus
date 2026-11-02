import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../models/site.dart';
import '../../../models/specialty.dart';
import '../../../providers/catalog_admin_provider.dart';
import '../../../utils/validators.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_button.dart';

/// Abre el formulario de sede. [site] null = crear.
Future<void> showSiteFormSheet(BuildContext context, {Site? site}) =>
    _showSheet(context, _SiteForm(site: site));

/// Abre el formulario de especialidad. [specialty] null = crear.
Future<void> showSpecialtyFormSheet(BuildContext context, {Specialty? specialty}) =>
    _showSheet(context, _SpecialtyForm(specialty: specialty));

Future<void> _showSheet(BuildContext context, Widget form) {
  final provider = context.read<CatalogAdminProvider>()..clearError();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => ChangeNotifierProvider.value(
      value: provider,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(child: form),
      ),
    ),
  );
}

/// Cierra la hoja y confirma con un mensaje (o deja el error visible).
void _closeIfSaved(BuildContext context, {required bool saved, required String message}) {
  if (!saved || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).pop();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

class _SiteForm extends StatefulWidget {
  const _SiteForm({this.site});

  final Site? site;

  @override
  State<_SiteForm> createState() => _SiteFormState();
}

class _SiteFormState extends State<_SiteForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.site?.name);
  late final TextEditingController _address = TextEditingController(text: widget.site?.address);
  late final TextEditingController _phone = TextEditingController(text: widget.site?.phone);

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final isNew = widget.site == null;
    final saved = await context.read<CatalogAdminProvider>().saveSite(
          SiteDraft(name: _name.text, address: _address.text, phone: _phone.text),
          id: widget.site?.id,
        );
    if (mounted) {
      _closeIfSaved(context, saved: saved, message: isNew ? 'Sede creada' : 'Sede actualizada');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogAdminProvider>();
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.site == null ? 'Nueva sede' : 'Editar sede',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (provider.errorMessage != null)
            ErrorBanner(message: provider.errorMessage!, onDismiss: provider.clearError),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            validator: (value) => Validators.required(value, 'El nombre'),
            decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Ej: Sede Norte'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _address,
            validator: (value) => Validators.required(value, 'La dirección'),
            decoration: const InputDecoration(labelText: 'Dirección'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? null : Validators.phone(value),
            decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
          ),
          const SizedBox(height: 20),
          LoadingButton(label: 'Guardar sede', isLoading: provider.isSaving, onPressed: _submit),
        ],
      ),
    );
  }
}

class _SpecialtyForm extends StatefulWidget {
  const _SpecialtyForm({this.specialty});

  final Specialty? specialty;

  @override
  State<_SpecialtyForm> createState() => _SpecialtyFormState();
}

class _SpecialtyFormState extends State<_SpecialtyForm> {
  static const List<int> _durations = [10, 15, 20, 25, 30, 40, 45, 60, 90, 120];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.specialty?.name);
  late final TextEditingController _description =
      TextEditingController(text: widget.specialty?.description);
  late int _slotMinutes = widget.specialty?.slotMinutes ?? 20;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Incluye la duración actual aunque no esté en la lista sugerida.
  List<int> get _options =>
      ({..._durations, _slotMinutes}.toList()..sort());

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final isNew = widget.specialty == null;
    final saved = await context.read<CatalogAdminProvider>().saveSpecialty(
          SpecialtyDraft(
            name: _name.text,
            slotMinutes: _slotMinutes,
            description: _description.text,
          ),
          id: widget.specialty?.id,
        );
    if (mounted) {
      _closeIfSaved(
        context,
        saved: saved,
        message: isNew ? 'Especialidad creada' : 'Especialidad actualizada',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogAdminProvider>();
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.specialty == null ? 'Nueva especialidad' : 'Editar especialidad',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (provider.errorMessage != null)
            ErrorBanner(message: provider.errorMessage!, onDismiss: provider.clearError),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) => Validators.required(value, 'El nombre'),
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            maxLines: 2,
            maxLength: 160,
            decoration: const InputDecoration(
              labelText: 'Descripción para el paciente (opcional)',
            ),
          ),
          const SizedBox(height: 6),
          Text('Duración de cada consulta', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in _options)
                ChoiceChip(
                  label: Text('$minutes min'),
                  selected: _slotMinutes == minutes,
                  onSelected: (_) => setState(() => _slotMinutes = minutes),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Entre consultas se suman 5 minutos de holgura. El cambio aplica '
            'a las horas que se ofrezcan desde ahora; las citas ya agendadas no cambian.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          LoadingButton(
            label: 'Guardar especialidad',
            isLoading: provider.isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
