import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/doctor_appointment.dart';
import '../../models/medical_record.dart';
import '../../utils/app_exception.dart';
import '../services/supabase_error_mapper.dart';
import 'doctor_repository.dart';

class SupabaseDoctorRepository
    implements DoctorRepository, MedicalRecordsRepository {
  SupabaseDoctorRepository(this._client);

  final SupabaseClient _client;
  static final DateFormat _sqlDate = DateFormat('yyyy-MM-dd');

  Future<List<Map<String, dynamic>>> _rows(
    String function, [
    Map<String, dynamic>? params,
  ]) async {
    final rows = await _client.rpc<List<dynamic>>(function, params: params);
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<DoctorAppointment>> fetchAgenda(DateTime date) =>
      SupabaseErrorMapper.guard(() async {
        final rows = await _rows('get_doctor_agenda', {
          'p_date': _sqlDate.format(date),
        });
        return rows.map(DoctorAppointment.fromJson).toList();
      });

  @override
  Future<ConsultationDetail> fetchConsultation(int appointmentId) =>
      SupabaseErrorMapper.guard(() async {
        final rows = await _rows('get_consultation', {
          'p_appointment_id': appointmentId,
        });
        if (rows.isEmpty) throw const AppException('No encontramos esta cita.');
        return ConsultationDetail.fromJson(rows.first);
      });

  @override
  Future<void> startConsultation(int appointmentId) =>
      SupabaseErrorMapper.guard(
        () => _client.rpc<void>(
          'start_consultation',
          params: {'p_appointment_id': appointmentId},
        ),
      );

  @override
  Future<int> completeConsultation(int appointmentId, ConsultationNote note) =>
      SupabaseErrorMapper.guard(() async {
        final recordId = await _client.rpc<num>(
          'complete_consultation',
          params: {
            'p_appointment_id': appointmentId,
            'p_reason': note.reason,
            'p_clinical_notes': note.clinicalNotes,
            'p_diagnosis_code': note.diagnosisCode,
            'p_diagnosis_description': note.diagnosisDescription,
          },
        );
        return recordId.toInt();
      });

  @override
  Future<List<MedicalRecord>> fetchPatientHistory(int appointmentId) =>
      SupabaseErrorMapper.guard(() async {
        final rows = await _rows('get_patient_history', {
          'p_appointment_id': appointmentId,
        });
        return rows.map(MedicalRecord.fromJson).toList();
      });

  @override
  Future<List<MedicalRecord>> fetchMyRecords() =>
      SupabaseErrorMapper.guard(() async {
        final rows = await _rows('get_my_medical_records');
        return rows.map(MedicalRecord.fromJson).toList();
      });
}
