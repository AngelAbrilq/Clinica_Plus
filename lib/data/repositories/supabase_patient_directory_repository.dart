import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/doctor_patient.dart';
import '../../models/medical_record.dart';
import '../services/supabase_error_mapper.dart';
import 'patient_directory_repository.dart';

class SupabasePatientDirectoryRepository implements PatientDirectoryRepository {
  SupabasePatientDirectoryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<DoctorPatient>> fetchMyPatients({String? search}) =>
      SupabaseErrorMapper.guard(() async {
        final trimmed = search?.trim();
        final rows = await _client.rpc<List<dynamic>>(
          'get_my_patients',
          params: {'p_search': (trimmed == null || trimmed.isEmpty) ? null : trimmed},
        );
        return rows.cast<Map<String, dynamic>>().map(DoctorPatient.fromJson).toList();
      });

  @override
  Future<List<MedicalRecord>> fetchPatientChart(String patientId) =>
      SupabaseErrorMapper.guard(() async {
        final rows = await _client.rpc<List<dynamic>>(
          'get_patient_chart',
          params: {'p_patient_id': patientId},
        );
        return rows.cast<Map<String, dynamic>>().map(MedicalRecord.fromJson).toList();
      });
}
