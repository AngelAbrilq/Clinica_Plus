import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/audit_entry.dart';
import '../../providers/audit_provider.dart';
import '../../utils/date_formatters.dart';
import '../../widgets/error_banner.dart';

/// Bitácora: quién consultó o modificó historias clínicas y cuándo.
class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  static const Map<AuditAction?, String> _filters = {
    null: 'Todo',
    AuditAction.readHistory: 'Consultas de historia',
    AuditAction.insert: 'Registros nuevos',
    AuditAction.update: 'Modificaciones',
  };

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuditProvider>().refresh(),
    );
    // Scroll infinito: pide la siguiente página cerca del final.
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) context.read<AuditProvider>().loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditProvider>();
    final theme = Theme.of(context);
    final entries = provider.entries;

    return Scaffold(
      appBar: AppBar(title: const Text('Auditoría')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                for (final entry in _filters.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: provider.filter == entry.key,
                      onSelected: (_) => provider.selectFilter(entry.key),
                    ),
                  ),
              ],
            ),
          ),
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ErrorBanner(message: provider.errorMessage!),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.refresh,
              child: entries.isEmpty && !provider.isLoading
                  ? ListView(
                      padding: const EdgeInsets.all(40),
                      children: [
                        Icon(Icons.policy_outlined, size: 56, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        const Text(
                          'Aún no hay eventos. Cada vez que un médico consulte o registre '
                          'una historia clínica aparecerá aquí.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: entries.length + 1,
                      itemBuilder: (_, index) {
                        if (index == entries.length) {
                          return _ListFooter(isLoading: provider.isLoading, hasMore: provider.hasMore);
                        }
                        final entry = entries[index];
                        final showDate = index == 0 ||
                            !DateUtils.isSameDay(entries[index - 1].createdAt, entry.createdAt);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showDate)
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 8),
                                child: Text(
                                  DateFormatters.longDate(entry.createdAt),
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                            _AuditTile(entry: entry),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry});

  final AuditEntry entry;

  IconData get _icon => switch (entry.action) {
        AuditAction.readHistory => Icons.visibility_outlined,
        AuditAction.insert => Icons.note_add_outlined,
        AuditAction.update => Icons.edit_note_rounded,
        AuditAction.delete => Icons.delete_outline_rounded,
        AuditAction.unknown => Icons.history_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final role = entry.actorRole?.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(_icon, color: colors.primary),
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: entry.actorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' ${entry.action.sentence.toLowerCase()} '),
                TextSpan(
                  text: entry.patientName ?? 'un paciente',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          subtitle: Text(
            role == null
                ? DateFormatters.time(entry.createdAt)
                : '$role, ${DateFormatters.time(entry.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.isLoading, required this.hasMore});

  final bool isLoading;
  final bool hasMore;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Text(
                  hasMore ? '' : 'No hay eventos más antiguos',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
        ),
      );
}
