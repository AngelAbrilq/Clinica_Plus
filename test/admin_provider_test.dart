import 'package:clinica_plus/data/repositories/admin_repository.dart';
import 'package:clinica_plus/models/doctor_schedule.dart';
import 'package:clinica_plus/models/site.dart';
import 'package:clinica_plus/models/specialty.dart';
import 'package:clinica_plus/models/staff_member.dart';
import 'package:clinica_plus/models/user_profile.dart';
import 'package:clinica_plus/models/user_role.dart';
import 'package:clinica_plus/providers/admin_provider.dart';
import 'package:clinica_plus/utils/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio falso en memoria: prueba el provider sin Supabase.
class FakeAdminRepository implements AdminRepository {
  final List<StaffMember> staff = [
    const StaffMember(
      profile: UserProfile(
        id: 'p-1',
        email: 'nuevo@clinicaplus.co',
        fullName: 'Nuevo',
      ),
    ),
    const StaffMember(
      profile: UserProfile(
        id: 'r-1',
        email: 'recepcion@clinicaplus.co',
        fullName: 'Laura',
        role: UserRole.receptionist,
      ),
    ),
  ];
  AppException? nextError;
  final List<String> calls = [];

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }

  @override
  Future<List<StaffMember>> fetchStaff() async => List.of(staff);

  @override
  Future<List<Site>> fetchSites() async => const [
    Site(id: 1, name: 'Sede Principal', address: ''),
  ];

  @override
  Future<List<Specialty>> fetchSpecialties() async => const [
    Specialty(id: 1, name: 'Medicina General', slotMinutes: 20),
  ];

  @override
  Future<void> assignRole({
    required String userId,
    required UserRole role,
  }) async {
    calls.add('assignRole:$userId:${role.name}');
    _throwIfNeeded();
  }

  @override
  Future<int> registerDoctor({
    required String userId,
    required int specialtyId,
    required String licenseNumber,
  }) async {
    calls.add('registerDoctor:$userId:$specialtyId:$licenseNumber');
    _throwIfNeeded();
    return 1;
  }

  @override
  Future<List<DoctorSchedule>> fetchSchedules(int doctorId) async => const [];

  @override
  Future<void> addSchedule(NewDoctorSchedule schedule) async {
    calls.add('addSchedule');
    _throwIfNeeded();
  }

  @override
  Future<void> deleteSchedule(int scheduleId) async {}
}

void main() {
  late FakeAdminRepository repository;
  late AdminProvider provider;

  setUp(() {
    repository = FakeAdminRepository();
    provider = AdminProvider(repository);
  });

  test('loadStaff carga personal y catálogos, y separa pendientes', () async {
    // Act
    await provider.loadStaff();
    // Assert
    expect(provider.staff, hasLength(2));
    expect(provider.pending.single.profile.id, 'p-1');
    expect(provider.withRole(UserRole.receptionist), hasLength(1));
    expect(provider.sites, hasLength(1));
    expect(provider.specialties, hasLength(1));
    expect(provider.isLoading, isFalse);
  });

  test('registerDoctor exitoso llama al repositorio y devuelve true', () async {
    final success = await provider.registerDoctor(
      userId: 'p-1',
      specialtyId: 1,
      licenseNumber: 'RM-1',
    );
    expect(success, isTrue);
    expect(repository.calls, ['registerDoctor:p-1:1:RM-1']);
    expect(provider.errorMessage, isNull);
    expect(provider.isSaving, isFalse);
  });

  test(
    'error del repositorio se expone como mensaje y devuelve false',
    () async {
      // Arrange
      repository.nextError = const AppException(
        'Ese registro médico ya está asignado.',
      );
      // Act
      final success = await provider.assignRole(
        userId: 'p-1',
        role: UserRole.receptionist,
      );
      // Assert
      expect(success, isFalse);
      expect(provider.errorMessage, 'Ese registro médico ya está asignado.');
      expect(provider.isSaving, isFalse);
    },
  );

  test('clearError limpia el mensaje', () async {
    repository.nextError = const AppException('x');
    await provider.addSchedule(
      const NewDoctorSchedule(
        doctorId: 1,
        siteId: 1,
        weekday: 1,
        startTime: '08:00',
        endTime: '09:00',
      ),
    );
    provider.clearError();
    expect(provider.errorMessage, isNull);
  });
}
