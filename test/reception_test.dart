import 'package:clinica_plus/config/navigation/app_modules.dart';
import 'package:clinica_plus/data/repositories/reception_repository.dart';
import 'package:clinica_plus/models/appointment_status.dart';
import 'package:clinica_plus/models/reception_appointment.dart';
import 'package:clinica_plus/models/site.dart';
import 'package:clinica_plus/models/user_role.dart';
import 'package:clinica_plus/providers/reception_provider.dart';
import 'package:clinica_plus/utils/app_exception.dart';
import 'package:clinica_plus/utils/check_in_code.dart';
import 'package:flutter_test/flutter_test.dart';

const String _token = '3f2b8c1e-9a4d-4e7f-b2c3-1d5e6f7a8b9c';
final DateTime _now = DateTime(2026, 11, 2, 9, 0);

ReceptionAppointment _appointment({
  int id = 1,
  required DateTime startsAt,
  AppointmentStatus status = AppointmentStatus.assigned,
}) => ReceptionAppointment(
  id: id,
  startsAt: startsAt,
  endsAt: startsAt.add(const Duration(minutes: 20)),
  status: status,
  patientName: 'Ana Gómez',
  specialtyName: 'Medicina General',
  doctorName: 'Dr. Ruiz',
);

class FakeReceptionRepository implements ReceptionRepository {
  List<ReceptionAppointment> agenda = [];
  String? lastToken;
  int fetchCount = 0;
  AppException? nextError;

  @override
  Future<List<Site>> fetchSites() async => const [
    Site(id: 1, name: 'Sede Principal', address: ''),
  ];

  @override
  Future<List<ReceptionAppointment>> fetchAgenda({
    required int siteId,
    required DateTime date,
  }) async {
    fetchCount++;
    return agenda;
  }

  @override
  Future<CheckInResult> checkInByToken(String token) async {
    final error = nextError;
    if (error != null) throw error;
    lastToken = token;
    return CheckInResult(
      appointmentId: 1,
      patientName: 'Ana Gómez',
      specialtyName: 'Medicina General',
      doctorName: 'Dr. Ruiz',
      startsAt: _now.add(const Duration(minutes: 15)),
      minutesUntilStart: 15,
    );
  }

  @override
  Future<CheckInResult> checkInById(int appointmentId) =>
      checkInByToken(_token);

  @override
  Future<void> markNoShow(int appointmentId) async {}
}

void main() {
  group('CheckInCode', () {
    test('build y parse son inversos', () {
      expect(CheckInCode.parse(CheckInCode.build(_token)), _token);
    });

    test('acepta el token solo (escrito a mano) y normaliza mayúsculas', () {
      expect(CheckInCode.parse('  ${_token.toUpperCase()} '), _token);
    });

    test('rechaza QR de otras apps', () {
      expect(CheckInCode.parse('https://otra-app.com/ticket/123'), isNull);
      expect(CheckInCode.parse('clinicaplus:checkin:no-es-uuid'), isNull);
    });
  });

  group('Reglas de ReceptionAppointment (iguales a la BD)', () {
    test('check-in permitido antes de la hora y hasta 10 min después', () {
      expect(
        _appointment(startsAt: _now.add(const Duration(hours: 1)))
            .canCheckIn(_now),
        isTrue,
      );
      expect(
        _appointment(startsAt: _now.subtract(const Duration(minutes: 10)))
            .canCheckIn(_now),
        isTrue,
      );
      expect(
        _appointment(startsAt: _now.subtract(const Duration(minutes: 11)))
            .canCheckIn(_now),
        isFalse,
      );
    });

    test('no se hace check-in de una cita de otro día', () {
      expect(
        _appointment(startsAt: _now.add(const Duration(days: 1)))
            .canCheckIn(_now),
        isFalse,
      );
    });

    test('inasistencia solo después de la tolerancia', () {
      expect(
        _appointment(startsAt: _now.subtract(const Duration(minutes: 5)))
            .canMarkNoShow(_now),
        isFalse,
      );
      expect(
        _appointment(startsAt: _now.subtract(const Duration(minutes: 10)))
            .canMarkNoShow(_now),
        isTrue,
      );
    });

    test('una cita cancelada no admite acciones', () {
      final cancelled = _appointment(
        startsAt: _now.subtract(const Duration(minutes: 30)),
        status: AppointmentStatus.cancelled,
      );
      expect(cancelled.canCheckIn(_now), isFalse);
      expect(cancelled.canMarkNoShow(_now), isFalse);
      expect(cancelled.group, ReceptionGroup.closed);
    });
  });

  group('ReceptionProvider', () {
    late FakeReceptionRepository repository;
    late ReceptionProvider provider;

    setUp(() {
      repository = FakeReceptionRepository()
        ..agenda = [
          _appointment(id: 1, startsAt: _now.add(const Duration(minutes: 15))),
          _appointment(
            id: 2,
            startsAt: _now.subtract(const Duration(minutes: 30)),
            status: AppointmentStatus.checkedIn,
          ),
          _appointment(
            id: 3,
            startsAt: _now.subtract(const Duration(hours: 1)),
            status: AppointmentStatus.completed,
          ),
        ];
      provider = ReceptionProvider(repository, clock: () => _now);
    });

    test('initialize selecciona la primera sede y cuenta por grupo', () async {
      await provider.initialize();
      expect(provider.siteId, 1);
      expect(provider.countOf(ReceptionGroup.pending), 1);
      expect(provider.countOf(ReceptionGroup.inClinic), 1);
      expect(provider.countOf(ReceptionGroup.closed), 1);
    });

    test('check-in con QR válido envía el token y recarga la agenda', () async {
      await provider.initialize();
      final fetchesBefore = repository.fetchCount;
      // Act
      final result = await provider.checkInFromCode(CheckInCode.build(_token));
      // Assert
      expect(repository.lastToken, _token);
      expect(result.patientName, 'Ana Gómez');
      expect(repository.fetchCount, fetchesBefore + 1);
      expect(provider.isProcessing, isFalse);
    });

    test('un QR ajeno se rechaza sin llamar al servidor', () async {
      await expectLater(
        provider.checkInFromCode('https://otra-app.com'),
        throwsA(isA<AppException>()),
      );
      expect(repository.lastToken, isNull);
    });

    test('el error del servidor llega a la UI y libera el estado', () async {
      repository.nextError = const AppException('Ana Gómez ya hizo check-in');
      await expectLater(
        provider.checkInFromCode(_token),
        throwsA(isA<AppException>()),
      );
      expect(provider.isProcessing, isFalse);
    });

    test('cambiar de día y volver a hoy', () async {
      await provider.initialize();
      await provider.shiftDate(1);
      expect(provider.isToday, isFalse);
      await provider.goToToday();
      expect(provider.isToday, isTrue);
    });
  });

  test('recepción tiene Inicio + Agenda + Check-in en la navegación', () {
    expect(
      AppModules.navigationFor(UserRole.receptionist)
          .map((module) => module.navigationLabel),
      ['Agenda', 'Check-in'],
    );
  });
}
