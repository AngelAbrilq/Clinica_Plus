import '../../models/reception_appointment.dart';
import '../../models/site.dart';

/// Operaciones de recepción: agenda, check-in e inasistencias.
abstract interface class ReceptionRepository {
  Future<List<Site>> fetchSites();

  Future<List<ReceptionAppointment>> fetchAgenda({
    required int siteId,
    required DateTime date,
  });

  Future<CheckInResult> checkInByToken(String token);

  Future<CheckInResult> checkInById(int appointmentId);

  Future<void> markNoShow(int appointmentId);
}
