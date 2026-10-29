import 'user_profile.dart';
import 'user_role.dart';

/// Ficha médica embebida (tabla `doctors` + nombre de la especialidad).
class DoctorInfo {
  const DoctorInfo({
    required this.id,
    required this.specialtyId,
    required this.specialtyName,
    required this.licenseNumber,
    required this.isActive,
  });

  final int id;
  final int specialtyId;
  final String specialtyName;
  final String licenseNumber;
  final bool isActive;

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    final specialty = json['specialties'] as Map<String, dynamic>?;
    return DoctorInfo(
      id: (json['id'] as num).toInt(),
      specialtyId: (json['specialty_id'] as num).toInt(),
      specialtyName: (specialty?['name'] as String?) ?? '',
      licenseNumber: json['license_number'] as String,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

/// Integrante del personal: perfil + ficha médica si la tiene.
class StaffMember {
  const StaffMember({required this.profile, this.doctor});

  final UserProfile profile;
  final DoctorInfo? doctor;

  UserRole? get role => profile.role;
  bool get isPending => profile.isPendingApproval;
  bool get isActiveDoctor => role == UserRole.doctor && (doctor?.isActive ?? false);

  String get displayName =>
      profile.fullName.trim().isEmpty ? profile.email : profile.fullName;

  /// PostgREST devuelve la relación 1:1 como objeto (o lista en versiones antiguas).
  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final rawDoctor = json['doctors'];
    final doctorJson = switch (rawDoctor) {
      final Map<String, dynamic> map => map,
      final List<dynamic> list when list.isNotEmpty => list.first as Map<String, dynamic>,
      _ => null,
    };
    return StaffMember(
      profile: UserProfile.fromJson(json),
      doctor: doctorJson == null ? null : DoctorInfo.fromJson(doctorJson),
    );
  }
}
