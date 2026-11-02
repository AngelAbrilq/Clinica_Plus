import '../../models/doctor_patient.dart';
import '../../models/medical_record.dart';

/// "Mis pacientes" del médico. Separado de DoctorRepository (ISP): quien
/// solo necesita la agenda no depende de estos métodos.
abstract interface class PatientDirectoryRepository {
  /// Pacientes atendidos o agendados con el médico. [search]: nombre o documento.
  Future<List<DoctorPatient>> fetchMyPatients({String? search});

  /// Historia completa del paciente. El servidor la deja auditada.
  Future<List<MedicalRecord>> fetchPatientChart(String patientId);
}
