import '../../models/available_slot.dart';
import '../../models/patient_appointment.dart';
import '../../models/site.dart';
import '../../models/specialty.dart';

/// Agendamiento de citas desde el lado del paciente.
abstract interface class AppointmentRepository {
  Future<List<Specialty>> fetchSpecialties();

  Future<List<Site>> fetchSites();

  /// Horas libres para [date] (solo se usa año-mes-día).
  Future<List<AvailableSlot>> fetchAvailableSlots({
    required int specialtyId,
    required int siteId,
    required DateTime date,
  });

  /// Agenda la cita y devuelve su id. El servidor asigna el médico.
  Future<int> bookAppointment({
    required int specialtyId,
    required int siteId,
    required DateTime startsAt,
    String? symptoms,
  });

  Future<List<PatientAppointment>> fetchMyAppointments();

  Future<void> cancelAppointment({required int appointmentId, String? reason});
}
