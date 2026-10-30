import 'package:clinica_plus/config/navigation/app_modules.dart';
import 'package:clinica_plus/data/repositories/doctor_repository.dart';
import 'package:clinica_plus/data/repositories/in_memory_cie10_repository.dart';
import 'package:clinica_plus/models/appointment_status.dart';
import 'package:clinica_plus/models/cie10_entry.dart';
import 'package:clinica_plus/models/doctor_appointment.dart';
import 'package:clinica_plus/models/medical_record.dart';
import 'package:clinica_plus/models/user_role.dart';
import 'package:clinica_plus/providers/doctor_provider.dart';
import 'package:clinica_plus/utils/app_exception.dart';
import 'package:clinica_plus/utils/search_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime(2026, 11, 2, 9, 0);

ConsultationDetail _consultation(AppointmentStatus status) =>
    ConsultationDetail(
      id: 7,
      startsAt: _now,
      status: status,
      patientName: 'Ana Gómez',
      specialtyName: 'Medicina General',
      siteName: 'Sede Principal',
      symptoms: 'Fiebre',
    );

class FakeDoctorRepository implements DoctorRepository {
  AppointmentStatus status = AppointmentStatus.checkedIn;
  ConsultationNote? savedNote;
  int historyCalls = 0;
  AppException? nextError;

  @override
  Future<List<DoctorAppointment>> fetchAgenda(DateTime date) async => [
    DoctorAppointment(
      id: 7,
      startsAt: _now,
      endsAt: _now.add(const Duration(minutes: 20)),
      status: status,
      checkedInAt: _now.subtract(const Duration(minutes: 12)),
      patientName: 'Ana Gómez',
      siteName: 'Sede Principal',
      specialtyName: 'Medicina General',
      hasRecord: status == AppointmentStatus.completed,
    ),
  ];

  @override
  Future<ConsultationDetail> fetchConsultation(int appointmentId) async =>
      _consultation(status);

  @override
  Future<void> startConsultation(int appointmentId) async {
    final error = nextError;
    if (error != null) throw error;
    status = AppointmentStatus.inProgress;
  }

  @override
  Future<int> completeConsultation(
    int appointmentId,
    ConsultationNote note,
  ) async {
    savedNote = note;
    status = AppointmentStatus.completed;
    return 99;
  }

  @override
  Future<List<MedicalRecord>> fetchPatientHistory(int appointmentId) async {
    historyCalls++;
    return const [];
  }
}

void main() {
  group('CIE-10 local', () {
    final repository = InMemoryCie10Repository(
      loader: () async => const [
        Cie10Entry(code: 'G43.9', description: 'Migraña, no especificada'),
        Cie10Entry(
          code: 'J06.9',
          description: 'Infección aguda de las vías respiratorias superiores',
        ),
        Cie10Entry(code: 'M54.5', description: 'Lumbago no especificado'),
      ],
    );

    test('busca sin tildes: "migrana" encuentra "Migraña"', () async {
      final results = await repository.search('migrana');
      expect(results.map((entry) => entry.code), ['G43.9']);
    });

    test('busca por prefijo de código', () async {
      final results = await repository.search('j06');
      expect(results.single.code, 'J06.9');
    });

    test('consulta vacía no devuelve nada', () async {
      expect(await repository.search('   '), isEmpty);
    });

    test('SearchNormalizer quita tildes y ñ', () {
      expect(
        SearchNormalizer.normalize('  Migraña Cefálea '),
        'migrana cefalea',
      );
    });
  });

  group('DoctorAppointment', () {
    test('minutos en sala solo para pacientes con check-in', () {
      final waiting = DoctorAppointment(
        id: 1,
        startsAt: _now,
        endsAt: _now,
        status: AppointmentStatus.checkedIn,
        checkedInAt: _now.subtract(const Duration(minutes: 12)),
        patientName: 'Ana',
        siteName: 'Sede',
        specialtyName: 'General',
        hasRecord: false,
      );
      expect(waiting.minutesWaiting(_now), 12);
      expect(waiting.group, DoctorAgendaGroup.waiting);
    });
  });

  group('DoctorProvider: flujo de consulta', () {
    late FakeDoctorRepository repository;
    late DoctorProvider provider;

    setUp(() {
      repository = FakeDoctorRepository();
      provider = DoctorProvider(repository, clock: () => _now);
    });

    test(
      'abrir → iniciar → finalizar guarda la nota y cierra la cita',
      () async {
        // Arrange
        await provider.openConsultation(7);
        expect(provider.consultation!.canStart, isTrue);
        // Act
        expect(await provider.startConsultation(), isTrue);
        expect(provider.consultation!.isInProgress, isTrue);
        final saved = await provider.completeConsultation(
          const ConsultationNote(
            reason: 'Fiebre de 2 días',
            diagnosisCode: 'R50.9',
            diagnosisDescription: 'Fiebre, no especificada',
          ),
        );
        // Assert
        expect(saved, isTrue);
        expect(repository.savedNote!.diagnosisCode, 'R50.9');
        expect(provider.consultation!.isCompleted, isTrue);
        expect(provider.agenda.single.group, DoctorAgendaGroup.done);
      },
    );

    test(
      'la historia NO se carga al abrir: solo cuando el médico la pide',
      () async {
        await provider.openConsultation(7);
        expect(provider.history, isNull);
        expect(repository.historyCalls, 0);
        await provider.loadHistory();
        expect(provider.history, isEmpty);
        expect(repository.historyCalls, 1);
      },
    );

    test('el error del servidor se muestra y no cambia el estado', () async {
      repository.nextError = const AppException(
        'El paciente aún no ha hecho check-in',
      );
      await provider.openConsultation(7);
      final started = await provider.startConsultation();
      expect(started, isFalse);
      expect(provider.errorMessage, 'El paciente aún no ha hecho check-in');
      expect(provider.isSaving, isFalse);
    });
  });

  test('médico tiene Inicio + Agenda en la navegación', () {
    expect(
      AppModules.navigationFor(UserRole.doctor)
          .map((module) => module.navigationLabel),
      ['Agenda'],
    );
  });
}
