/// Ciclo de vida de una cita.
/// requested → assigned → confirmed → checkedIn → inProgress → completed
/// Ramas: cancelled, noShow.
enum AppointmentStatus {
  requested('requested', 'Solicitada'),
  assigned('assigned', 'Asignada'),
  confirmed('confirmed', 'Confirmada'),
  checkedIn('checked_in', 'En sala'),
  inProgress('in_progress', 'En consulta'),
  completed('completed', 'Atendida'),
  cancelled('cancelled', 'Cancelada'),
  noShow('no_show', 'No asistió');

  const AppointmentStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  bool get isActive => const {
        assigned,
        confirmed,
        checkedIn,
        inProgress,
      }.contains(this);

  bool get isFinal => const {completed, cancelled, noShow}.contains(this);

  static AppointmentStatus fromDb(String value) =>
      AppointmentStatus.values.firstWhere(
        (status) => status.dbValue == value,
        orElse: () => throw ArgumentError('Estado desconocido: $value'),
      );
}
