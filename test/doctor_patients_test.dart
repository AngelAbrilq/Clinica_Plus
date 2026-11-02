import 'dart:async';

import 'package:clinica_plus/data/repositories/patient_directory_repository.dart';
import 'package:clinica_plus/models/doctor_patient.dart';
import 'package:clinica_plus/models/medical_record.dart';
import 'package:clinica_plus/providers/doctor_patients_provider.dart';
import 'package:clinica_plus/utils/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

DoctorPatient _patient(String id, String name) =>
    DoctorPatient(id: id, name: name, completedVisits: 1);

class FakePatientDirectory implements PatientDirectoryRepository {
  final List<String?> searches = [];
  final Map<String?, Completer<List<DoctorPatient>>> pending = {};
  bool autoComplete = true;
  AppException? chartError;

  @override
  Future<List<DoctorPatient>> fetchMyPatients({String? search}) {
    searches.add(search);
    if (autoComplete) {
      return Future.value([
        _patient('p1', 'Ana Gómez'),
        _patient('p2', 'Luis Pérez'),
      ].where((p) => search == null || search.isEmpty || p.name.contains(search)).toList());
    }
    final completer = Completer<List<DoctorPatient>>();
    pending[search] = completer;
    return completer.future;
  }

  @override
  Future<List<MedicalRecord>> fetchPatientChart(String patientId) async {
    final error = chartError;
    if (error != null) throw error;
    return [
      MedicalRecord(
        id: 1,
        consultedAt: DateTime(2026, 10, 1),
        specialtyName: 'Pediatría',
        doctorName: 'Dr. Gómez',
        reason: 'Fiebre',
        diagnosisCode: 'R50.9',
      ),
    ];
  }
}

void main() {
  group('DoctorPatient', () {
    test('lee la fila del servidor', () {
      final patient = DoctorPatient.fromJson(const {
        'patient_id': 'u-1',
        'patient_name': 'Ángela Ruiz',
        'patient_document': 'CC 1075',
        'patient_age': 36,
        'completed_visits': 3,
        'last_visit_at': '2026-10-01T14:00:00+00:00',
        'next_visit_at': null,
      });
      expect(patient.initial, 'Á');
      expect(patient.age, 36);
      expect(patient.lastVisitAt!.toUtc(), DateTime.utc(2026, 10, 1, 14));
      expect(patient.nextVisitAt, isNull);
    });
  });

  group('DoctorPatientsProvider', () {
    test('el debounce agrupa varias teclas en una sola consulta', () async {
      final repository = FakePatientDirectory();
      final provider = DoctorPatientsProvider(
        repository,
        debounce: const Duration(milliseconds: 20),
      );
      provider
        ..onQueryChanged('A')
        ..onQueryChanged('An')
        ..onQueryChanged('Ana');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(repository.searches, ['Ana']);
      expect(provider.patients.single.name, 'Ana Gómez');
      provider.dispose();
    });

    test('una respuesta vieja no pisa la búsqueda más reciente', () async {
      final repository = FakePatientDirectory()..autoComplete = false;
      final provider = DoctorPatientsProvider(repository);
      provider.onQueryChanged('Lu');
      final first = provider.search();
      provider.onQueryChanged('Ana');
      final second = provider.search();
      repository.pending['Ana']!.complete([_patient('p1', 'Ana Gómez')]);
      await second;
      repository.pending['Lu']!.complete([_patient('p2', 'Luis Pérez')]);
      await first;
      expect(provider.patients.single.id, 'p1');
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });

    test('abre la historia y encuentra al paciente en la lista', () async {
      final provider = DoctorPatientsProvider(FakePatientDirectory());
      await provider.search();
      await provider.openChart('p2');
      expect(provider.patientById('p2')?.name, 'Luis Pérez');
      expect(provider.chart, hasLength(1));
      expect(provider.isLoadingChart, isFalse);
      provider.dispose();
    });

    test('sin relación de atención: muestra el error del servidor', () async {
      final repository = FakePatientDirectory()
        ..chartError = const AppException('No tienes citas con este paciente');
      final provider = DoctorPatientsProvider(repository);
      await provider.openChart('ajeno');
      expect(provider.chart, isNull);
      expect(provider.errorMessage, 'No tienes citas con este paciente');
      provider.dispose();
    });
  });
}
