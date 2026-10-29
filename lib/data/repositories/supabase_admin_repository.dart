import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/doctor_schedule.dart';
import '../../models/site.dart';
import '../../models/specialty.dart';
import '../../models/staff_member.dart';
import '../../models/user_role.dart';
import '../services/supabase_error_mapper.dart';
import 'admin_repository.dart';

/// Implementación con Supabase. La seguridad real la imponen RLS y las
/// funciones SQL: aunque alguien llame estos métodos sin ser admin, falla.
class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._client);

  final SupabaseClient _client;

  /// Un solo request trae perfil + ficha médica + especialidad (sin N+1).
  static const String _staffSelect =
      '*, doctors(id, specialty_id, license_number, is_active, specialties(name))';

  @override
  Future<List<StaffMember>> fetchStaff() => SupabaseErrorMapper.guard(() async {
    final rows = await _client
        .from('profiles')
        .select(_staffSelect)
        .or('role.is.null,role.neq.patient')
        .order('created_at', ascending: false);
    return rows.map(StaffMember.fromJson).toList();
  });

  @override
  Future<List<Site>> fetchSites() => SupabaseErrorMapper.guard(() async {
    final rows = await _client
        .from('sites')
        .select()
        .eq('is_active', true)
        .order('name');
    return rows.map(Site.fromJson).toList();
  });

  @override
  Future<List<Specialty>> fetchSpecialties() =>
      SupabaseErrorMapper.guard(() async {
        final rows = await _client
            .from('specialties')
            .select()
            .eq('is_active', true)
            .order('name');
        return rows.map(Specialty.fromJson).toList();
      });

  @override
  Future<void> assignRole({required String userId, required UserRole role}) =>
      SupabaseErrorMapper.guard(
        () => _client.rpc<void>(
          'admin_set_user_role',
          params: {'p_user_id': userId, 'p_role': role.name},
        ),
      );

  @override
  Future<int> registerDoctor({
    required String userId,
    required int specialtyId,
    required String licenseNumber,
  }) => SupabaseErrorMapper.guard(
    () async {
      final doctorId = await _client.rpc<num>(
        'admin_register_doctor',
        params: {
          'p_user_id': userId,
          'p_specialty_id': specialtyId,
          'p_license_number': licenseNumber,
        },
      );
      return doctorId.toInt();
    },
    messagesByCode: {
      '23505': 'Ese registro médico ya está asignado a otro médico.',
    },
  );

  @override
  Future<List<DoctorSchedule>> fetchSchedules(int doctorId) =>
      SupabaseErrorMapper.guard(() async {
        final rows = await _client
            .from('doctor_schedules')
            .select('*, sites(name)')
            .eq('doctor_id', doctorId)
            .order('weekday')
            .order('start_time');
        return rows.map(DoctorSchedule.fromJson).toList();
      });

  @override
  Future<void> addSchedule(NewDoctorSchedule schedule) =>
      SupabaseErrorMapper.guard(
        () => _client.from('doctor_schedules').insert(schedule.toJson()),
        messagesByCode: {
          '23P01': 'Este horario se cruza con otro del mismo médico ese día.',
          '23514': 'La hora de fin debe ser posterior a la de inicio.',
        },
      );

  @override
  Future<void> deleteSchedule(int scheduleId) => SupabaseErrorMapper.guard(
    () => _client.from('doctor_schedules').delete().eq('id', scheduleId),
  );
}
