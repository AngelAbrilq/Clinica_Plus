import '../../models/doctor_appointment.dart';
import '../../models/medical_record.dart';

/// Operaciones del portal médico.
abstract interface class DoctorRepository {
  Future<List<DoctorAppointment>> fetchAgenda(DateTime date);

  Future<ConsultationDetail> fetchConsultation(int appointmentId);

  Future<void> startConsultation(int appointmentId);

  /// Guarda el registro clínico y cierra la cita (atómico en el servidor).
  Future<int> completeConsultation(int appointmentId, ConsultationNote note);

  /// Historia previa del paciente. El servidor deja registro de auditoría.
  Future<List<MedicalRecord>> fetchPatientHistory(int appointmentId);
}

/// Historia clínica del paciente autenticado.
abstract interface class MedicalRecordsRepository {
  Future<List<MedicalRecord>> fetchMyRecords();
}
