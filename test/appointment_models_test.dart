import 'package:clinica_plus/models/appointment_status.dart';
import 'package:clinica_plus/models/available_slot.dart';
import 'package:clinica_plus/models/patient_appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PatientAppointment.fromJson', () {
    final json = {
      'id': 5,
      'starts_at': '2026-11-02T13:00:00+00:00',
      'ends_at': '2026-11-02T13:30:00+00:00',
      'status': 'assigned',
      'symptoms': 'Fiebre',
      'cancel_reason': null,
      'confirmation_token': 'abc-123',
      'specialty_name': 'Pediatría',
      'site_name': 'Sede Principal',
      'site_address': 'Calle 1',
      'doctor_name': 'Dra. Peña',
    };

    test('convierte la fecha UTC del servidor al mismo instante local', () {
      final appointment = PatientAppointment.fromJson(json);
      expect(appointment.startsAt!.toUtc(), DateTime.utc(2026, 11, 2, 13));
      expect(appointment.status, AppointmentStatus.assigned);
    });

    test('el QR de check-in incluye el token de confirmación', () {
      expect(PatientAppointment.fromJson(json).checkInCode, 'clinicaplus:checkin:abc-123');
    });

    test('una cita cancelada no se puede volver a cancelar', () {
      final cancelled = PatientAppointment.fromJson({...json, 'status': 'cancelled'});
      expect(cancelled.canCancel(DateTime.utc(2026, 11, 1)), isFalse);
    });
  });

  test('AvailableSlot distingue mañana y tarde', () {
    final slot = AvailableSlot.fromJson({
      'starts_at': DateTime(2026, 11, 2, 14).toUtc().toIso8601String(),
      'ends_at': DateTime(2026, 11, 2, 14, 30).toUtc().toIso8601String(),
      'available_doctors': 2,
    });
    expect(slot.isMorning, isFalse);
    expect(slot.availableDoctors, 2);
  });
}
