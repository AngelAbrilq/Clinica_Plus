import 'dart:async';

import 'package:clinica_plus/data/repositories/appointment_repository.dart';
import 'package:clinica_plus/models/appointment_status.dart';
import 'package:clinica_plus/models/available_slot.dart';
import 'package:clinica_plus/models/patient_appointment.dart';
import 'package:clinica_plus/models/site.dart';
import 'package:clinica_plus/models/specialty.dart';
import 'package:clinica_plus/providers/appointment_provider.dart';
import 'package:clinica_plus/utils/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime(2026, 11, 2, 7, 0);

PatientAppointment _appointment({
  required int id,
  required DateTime startsAt,
  AppointmentStatus status = AppointmentStatus.assigned,
}) =>
    PatientAppointment(
      id: id,
      startsAt: startsAt,
      endsAt: startsAt.add(const Duration(minutes: 30)),
      status: status,
      confirmationToken: 'token-$id',
      specialtyName: 'Pediatría',
      siteName: 'Sede Principal',
      siteAddress: '',
      doctorName: 'Dra. Peña',
    );

class FakeAppointmentRepository implements AppointmentRepository {
  List<PatientAppointment> appointments = [];
  AppException? nextError;
  final Map<String, Completer<List<AvailableSlot>>> pendingSlots = {};
  int? lastBookedSiteId;
  String? lastSymptoms;

  @override
  Future<List<Specialty>> fetchSpecialties() async =>
      const [Specialty(id: 2, name: 'Pediatría', slotMinutes: 30)];

  @override
  Future<List<Site>> fetchSites() async =>
      const [Site(id: 1, name: 'Sede Principal', address: '')];

  /// Se resuelve manualmente para simular respuestas que llegan en desorden.
  @override
  Future<List<AvailableSlot>> fetchAvailableSlots({
    required int specialtyId,
    required int siteId,
    required DateTime date,
  }) {
    final completer = Completer<List<AvailableSlot>>();
    pendingSlots['${date.day}'] = completer;
    return completer.future;
  }

  @override
  Future<int> bookAppointment({
    required int specialtyId,
    required int siteId,
    required DateTime startsAt,
    String? symptoms,
  }) async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    lastBookedSiteId = siteId;
    lastSymptoms = symptoms;
    appointments = [...appointments, _appointment(id: 99, startsAt: startsAt)];
    return 99;
  }

  @override
  Future<List<PatientAppointment>> fetchMyAppointments() async => appointments;

  @override
  Future<void> cancelAppointment({required int appointmentId, String? reason}) async {}
}

AvailableSlot _slot(int hour) => AvailableSlot(
      startsAt: DateTime(2026, 11, 2, hour),
      endsAt: DateTime(2026, 11, 2, hour, 30),
      availableDoctors: 1,
    );

void main() {
  late FakeAppointmentRepository repository;
  late AppointmentProvider provider;

  setUp(() {
    repository = FakeAppointmentRepository();
    provider = AppointmentProvider(repository, clock: () => _now);
  });

  test('book devuelve el id, envía síntomas recortados y recarga citas', () async {
    // Act
    final id = await provider.book(
      specialtyId: 2,
      siteId: 1,
      slot: _slot(8),
      symptoms: '  fiebre  ',
    );
    // Assert
    expect(id, 99);
    expect(repository.lastSymptoms, 'fiebre');
    expect(provider.appointments.single.id, 99);
    expect(provider.isSaving, isFalse);
  });

  test('síntomas en blanco se envían como null', () async {
    await provider.book(specialtyId: 2, siteId: 1, slot: _slot(8), symptoms: '   ');
    expect(repository.lastSymptoms, isNull);
  });

  test('si el horario ya se ocupó, book devuelve null y muestra el error', () async {
    repository.nextError = const AppException('Ese horario ya no está disponible. Elige otro.');
    final id = await provider.book(specialtyId: 2, siteId: 1, slot: _slot(8));
    expect(id, isNull);
    expect(provider.errorMessage, 'Ese horario ya no está disponible. Elige otro.');
  });

  test('una respuesta vieja de horarios no pisa la más reciente', () async {
    // Arrange: el usuario toca el día 2 y luego el día 3
    final first = provider.loadSlots(specialtyId: 2, siteId: 1, date: DateTime(2026, 11, 2));
    final second = provider.loadSlots(specialtyId: 2, siteId: 1, date: DateTime(2026, 11, 3));
    // Act: llega primero la respuesta del día 3 y DESPUÉS la del día 2
    repository.pendingSlots['3']!.complete([_slot(10)]);
    await second;
    repository.pendingSlots['2']!.complete([_slot(8), _slot(9)]);
    await first;
    // Assert: se conservan los horarios del día 3
    expect(provider.slots.map((slot) => slot.startsAt.hour), [10]);
    expect(provider.isLoadingSlots, isFalse);
  });

  test('upcoming ordena por fecha e history contiene pasadas y canceladas', () async {
    repository.appointments = [
      _appointment(id: 1, startsAt: DateTime(2026, 11, 5, 9)),
      _appointment(id: 2, startsAt: DateTime(2026, 11, 3, 9)),
      _appointment(id: 3, startsAt: DateTime(2026, 10, 1, 9), status: AppointmentStatus.completed),
      _appointment(id: 4, startsAt: DateTime(2026, 11, 4, 9), status: AppointmentStatus.cancelled),
    ];
    await provider.loadMyAppointments();
    expect(provider.upcoming.map((item) => item.id), [2, 1]);
    expect(provider.history.map((item) => item.id), containsAll([3, 4]));
  });

  test('canCancel respeta la ventana de 2 horas', () {
    final soon = _appointment(id: 1, startsAt: _now.add(const Duration(minutes: 90)));
    final later = _appointment(id: 2, startsAt: _now.add(const Duration(hours: 3)));
    expect(provider.canCancel(soon), isFalse);
    expect(provider.canCancel(later), isTrue);
  });
}
