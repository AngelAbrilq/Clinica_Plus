import 'package:flutter/foundation.dart';

import '../data/repositories/insights_repository.dart';
import '../models/audit_entry.dart';
import '../utils/app_exception.dart';

/// Estado del módulo "Auditoría": paginación por cursor y filtro.
class AuditProvider extends ChangeNotifier {
  AuditProvider(this._repository);

  static const int pageSize = 30;

  final InsightsRepository _repository;

  List<AuditEntry> _entries = const [];
  AuditAction? _filter;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _requestId = 0;

  List<AuditEntry> get entries => _entries;
  AuditAction? get filter => _filter;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> selectFilter(AuditAction? action) async {
    if (_filter == action) return;
    _filter = action;
    await refresh();
  }

  /// Primera página.
  Future<void> refresh() async {
    _entries = const [];
    _hasMore = true;
    await _fetchPage();
  }

  /// Siguiente página (si hay y no se está cargando).
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _fetchPage();
  }

  Future<void> _fetchPage() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await _repository.fetchAuditLog(
        limit: pageSize,
        beforeId: _entries.isEmpty ? null : _entries.last.id,
        action: _filter,
      );
      if (requestId != _requestId) return;
      _entries = [..._entries, ...page];
      _hasMore = page.length == pageSize;
    } on AppException catch (error) {
      if (requestId != _requestId) return;
      _errorMessage = error.message;
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
