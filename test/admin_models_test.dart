import 'package:clinica_plus/models/doctor_schedule.dart';
import 'package:clinica_plus/models/staff_member.dart';
import 'package:clinica_plus/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _profileJson({String? role, Object? doctors}) => {
  'id': 'u-1',
  'email': 'medico@clinicaplus.co',
  'full_name': 'Ana Ruiz',
  'role': role,
  'doctors': doctors,
};

void main() {
  group('StaffMember.fromJson', () {
    test('lee la ficha médica embebida como objeto (PostgREST 1:1)', () {
      // Arrange
      final json = _profileJson(
        role: 'doctor',
        doctors: {
          'id': 7,
          'specialty_id': 2,
          'license_number': 'RM-777',
          'is_active': true,
          'specialties': {'name': 'Pediatría'},
        },
      );
      // Act
      final member = StaffMember.fromJson(json);
      // Assert
      expect(member.role, UserRole.doctor);
      expect(member.isActiveDoctor, isTrue);
      expect(member.doctor?.specialtyName, 'Pediatría');
    });

    test('acepta la relación como lista (versiones antiguas de PostgREST)', () {
      final member = StaffMember.fromJson(
        _profileJson(
          role: 'doctor',
          doctors: [
            {
              'id': 7,
              'specialty_id': 2,
              'license_number': 'RM-777',
              'is_active': true,
            },
          ],
        ),
      );
      expect(member.doctor?.id, 7);
    });

    test('personal sin rol queda pendiente y sin ficha', () {
      final member = StaffMember.fromJson(_profileJson());
      expect(member.isPending, isTrue);
      expect(member.doctor, isNull);
      expect(member.isActiveDoctor, isFalse);
    });

    test('médico con ficha inactiva no cuenta como médico activo', () {
      final member = StaffMember.fromJson(
        _profileJson(
          role: 'receptionist',
          doctors: {
            'id': 7,
            'specialty_id': 2,
            'license_number': 'RM-777',
            'is_active': false,
          },
        ),
      );
      expect(member.isActiveDoctor, isFalse);
    });

    test('displayName usa el correo si no hay nombre', () {
      final json = _profileJson()..['full_name'] = '';
      expect(StaffMember.fromJson(json).displayName, 'medico@clinicaplus.co');
    });
  });

  group('DoctorSchedule.fromJson', () {
    test('recorta HH:mm:ss de Postgres a HH:mm', () {
      final schedule = DoctorSchedule.fromJson({
        'id': 1,
        'doctor_id': 7,
        'site_id': 1,
        'weekday': 1,
        'start_time': '08:00:00',
        'end_time': '12:30:00',
        'sites': {'name': 'Sede Norte'},
      });
      expect(schedule.startTime, '08:00');
      expect(schedule.endTime, '12:30');
      expect(schedule.siteName, 'Sede Norte');
    });
  });

  group('NewDoctorSchedule.toJson', () {
    test('usa los nombres de columna de la BD', () {
      const schedule = NewDoctorSchedule(
        doctorId: 7,
        siteId: 1,
        weekday: 3,
        startTime: '14:00',
        endTime: '18:00',
      );
      expect(schedule.toJson(), {
        'doctor_id': 7,
        'site_id': 1,
        'weekday': 3,
        'start_time': '14:00',
        'end_time': '18:00',
      });
    });
  });
}
