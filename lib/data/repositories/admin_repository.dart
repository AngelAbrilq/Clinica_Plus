import '../../models/doctor_schedule.dart';
import '../../models/site.dart';
import '../../models/specialty.dart';
import '../../models/staff_member.dart';
import '../../models/user_role.dart';

/// Operaciones del administrador sobre personal, médicos y horarios.
abstract interface class AdminRepository {
  /// Personal de la clínica: pendientes + médicos + recepción + admins.
  Future<List<StaffMember>> fetchStaff();

  Future<List<Site>> fetchSites();

  Future<List<Specialty>> fetchSpecialties();

  /// Asigna un rol que no requiere ficha adicional (recepción, admin…).
  Future<void> assignRole({required String userId, required UserRole role});

  /// Convierte al usuario en médico (rol + ficha) de forma atómica.
  /// Devuelve el id de la ficha médica.
  Future<int> registerDoctor({
    required String userId,
    required int specialtyId,
    required String licenseNumber,
  });

  Future<List<DoctorSchedule>> fetchSchedules(int doctorId);

  Future<void> addSchedule(NewDoctorSchedule schedule);

  Future<void> deleteSchedule(int scheduleId);
}
