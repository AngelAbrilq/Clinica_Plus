import 'package:flutter/foundation.dart';

import '../data/repositories/insights_repository.dart';
import '../models/clinic_metrics.dart';
import '../models/site.dart';
import '../utils/app_exception.dart';

/// Periodos predefinidos (siempre terminan hoy).
enum MetricsPeriod {
  week(7, '7 días'),
  month(30, '30 días'),
  quarter(90, '90 días');

  const MetricsPeriod(this.days, this.label);
  final int days;
  final String label;
}

/// Estado del módulo "Indicadores".
class MetricsProvider extends ChangeNotifier {
  MetricsProvider(this._repository, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final InsightsRepository _repository;
  final DateTime Function() _clock;

  List<Site> _sites = const [];
  MetricsPeriod _period = MetricsPeriod.month;
  int? _siteId;
  ClinicMetrics? _metrics;
  bool _isLoading = false;
  String? _errorMessage;
  int _requestId = 0;

  List<Site> get sites => _sites;
  MetricsPeriod get period => _period;
  int? get siteId => _siteId;
  ClinicMetrics? get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DateTime get to {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  /// Aritmética de calendario (no Duration): no se corre una hora en
  /// zonas con horario de verano.
  DateTime get from => DateTime(to.year, to.month, to.day - (_period.days - 1));

  Future<void> selectPeriod(MetricsPeriod period) async {
    if (_period == period) return;
    _period = period;
    await load();
  }

  /// null = todas las sedes.
  Future<void> selectSite(int? siteId) async {
    if (_siteId == siteId) return;
    _siteId = siteId;
    await load();
  }

  /// Carga las sedes (una vez) y los indicadores.
  Future<void> initialize() async {
    if (_sites.isEmpty) {
      try {
        _sites = await _repository.fetchSites();
      } on AppException {
        // Sin sedes el filtro queda en "Todas"; los indicadores igual cargan.
      }
    }
    await load();
  }

  Future<void> load() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.fetchMetrics(from: from, to: to, siteId: _siteId);
      if (requestId != _requestId) return;
      _metrics = result;
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
