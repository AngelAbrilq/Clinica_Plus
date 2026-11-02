/// Reglas de negocio centralizadas de Clinica Plus.
abstract final class AppConstants {
  static const String appName = 'Clinica Plus';

  // Agendamiento
  static const Duration slotBuffer = Duration(minutes: 5);
  static const Duration lateTolerance = Duration(minutes: 10);
  static const Duration freeCancellationWindow = Duration(hours: 2);
  static const Duration reminderBeforeAppointment = Duration(hours: 24);
  static const int maxNoShowsBeforeBlock = 3;
  static const Duration noShowBlockDuration = Duration(days: 30);

  // Seguridad
  static const Duration staffInactivityTimeout = Duration(minutes: 15);
  static const int minPasswordLength = 8;

  // Línea de emergencias Colombia
  static const String emergencyPhone = '123';

  /// Días de la semana en formato ISO (1 = lunes).
  static const Map<int, String> weekdayLabels = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };
}
