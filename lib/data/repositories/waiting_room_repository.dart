import '../../models/queue_status.dart';

/// Sala de espera del paciente.
abstract interface class WaitingRoomRepository {
  Future<QueueStatus> fetchQueueStatus(int appointmentId);

  /// Emite cada vez que la cita cambia en el servidor (tiempo real).
  /// Cancelar la suscripción cierra el canal.
  Stream<void> watchAppointment(int appointmentId);
}
