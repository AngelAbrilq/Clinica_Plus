import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/available_slot.dart';
import '../../models/patient_appointment.dart';
import '../../models/site.dart';
import '../../models/specialty.dart';
import '../services/catalog_queries.dart';
import '../services/supabase_error_mapper.dart';
import 'appointment_repository.dart';

/// Toda la lógica de negocio (disponibilidad, asignación, reglas de
/// cancelación) vive en funciones SQL: la app solo las invoca.
class SupabaseAppointmentRepository implements AppointmentRepository {
  SupabaseAppointmentRepository(this._client);

  final SupabaseClient _client;
  static final DateFormat _sqlDate = DateFormat('yyyy-MM-dd');

  @override
  Future<List<Specialty>> fetchSpecialties() =>
      CatalogQueries.fetchSpecialties(_client);

  @override
  Future<List<Site>> fetchSites() => CatalogQueries.fetchSites(_client);

  @override
  Future<List<AvailableSlot>> fetchAvailableSlots({
    required int specialtyId,
    required int siteId,
    required DateTime date,
  }) => SupabaseErrorMapper.guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'get_available_slots',
      params: {
        'p_specialty_id': specialtyId,
        'p_site_id': siteId,
        'p_date': _sqlDate.format(date),
      },
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map(AvailableSlot.fromJson)
        .toList();
  });

  @override
  Future<int> bookAppointment({
    required int specialtyId,
    required int siteId,
    required DateTime startsAt,
    String? symptoms,
  }) => SupabaseErrorMapper.guard(() async {
    final appointmentId = await _client.rpc<num>(
      'book_appointment',
      params: {
        'p_specialty_id': specialtyId,
        'p_site_id': siteId,
        // En UTC: el servidor compara el instante exacto con el slot.
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_symptoms': symptoms,
      },
    );
    return appointmentId.toInt();
  });

  @override
  Future<List<PatientAppointment>> fetchMyAppointments() =>
      SupabaseErrorMapper.guard(() async {
        final rows = await _client.rpc<List<dynamic>>('get_my_appointments');
        return rows
            .cast<Map<String, dynamic>>()
            .map(PatientAppointment.fromJson)
            .toList();
      });

  @override
  Future<void> cancelAppointment({
    required int appointmentId,
    String? reason,
  }) => SupabaseErrorMapper.guard(
    () => _client.rpc<void>(
      'cancel_appointment',
      params: {'p_appointment_id': appointmentId, 'p_reason': reason},
    ),
  );
}
