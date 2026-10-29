/// Hora disponible para agendar (resultado de `get_available_slots`).
class AvailableSlot {
  const AvailableSlot({
    required this.startsAt,
    required this.endsAt,
    required this.availableDoctors,
  });

  /// En hora local del dispositivo.
  final DateTime startsAt;
  final DateTime endsAt;
  final int availableDoctors;

  bool get isMorning => startsAt.hour < 12;

  factory AvailableSlot.fromJson(Map<String, dynamic> json) => AvailableSlot(
        startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
        endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
        availableDoctors: (json['available_doctors'] as num).toInt(),
      );
}
