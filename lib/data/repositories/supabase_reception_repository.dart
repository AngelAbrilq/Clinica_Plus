import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/reception_appointment.dart';
import '../../models/site.dart';
import '../services/catalog_queries.dart';
import '../services/supabase_error_mapper.dart';
import 'reception_repository.dart';

class SupabaseReceptionRepository implements ReceptionRepository {
  SupabaseReceptionRepository(this._client);

  final SupabaseClient _client;
  static final DateFormat _sqlDate = DateFormat('yyyy-MM-dd');

  @override
  Future<List<Site>> fetchSites() => CatalogQueries.fetchSites(_client);

  @override
  Future<List<ReceptionAppointment>> fetchAgenda({
    required int siteId,
    required DateTime date,
  }) => SupabaseErrorMapper.guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'get_reception_agenda',
      params: {'p_site_id': siteId, 'p_date': _sqlDate.format(date)},
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map(ReceptionAppointment.fromJson)
        .toList();
  });

  @override
  Future<CheckInResult> checkInByToken(String token) =>
      _checkIn('check_in_by_token', {'p_token': token});

  @override
  Future<CheckInResult> checkInById(int appointmentId) =>
      _checkIn('check_in_by_id', {'p_appointment_id': appointmentId});

  Future<CheckInResult> _checkIn(
    String function,
    Map<String, dynamic> params,
  ) => SupabaseErrorMapper.guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      function,
      params: params,
    );
    return CheckInResult.fromJson(json);
  });

  @override
  Future<void> markNoShow(int appointmentId) => SupabaseErrorMapper.guard(
    () => _client.rpc<void>(
      'mark_no_show',
      params: {'p_appointment_id': appointmentId},
    ),
  );
}
