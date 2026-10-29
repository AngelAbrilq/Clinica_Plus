import 'package:clinica_plus/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('acepta un correo válido', () {
      // Arrange
      const email = 'paciente@gmail.com';
      // Act
      final result = Validators.email(email);
      // Assert
      expect(result, isNull);
    });

    test('rechaza correo sin dominio', () {
      expect(Validators.email('paciente@'), isNotNull);
    });

    test('rechaza vacío', () {
      expect(Validators.email('   '), 'El correo es obligatorio');
    });
  });

  group('Validators.password', () {
    test('acepta letras + números con 8 caracteres', () {
      expect(Validators.password('clinica26'), isNull);
    });

    test('rechaza menos de 8 caracteres', () {
      expect(Validators.password('abc123'), 'Mínimo 8 caracteres');
    });

    test('rechaza sin números', () {
      expect(Validators.password('soloLetras'), 'Debe tener letras y números');
    });
  });

  group('Validators.documentNumber', () {
    test('acepta cédula numérica', () {
      expect(Validators.documentNumber('1075123456'), isNull);
    });

    test('rechaza puntos (igual que el CHECK de la BD)', () {
      expect(Validators.documentNumber('1.075.123'), isNotNull);
    });
  });

  group('Validators.isStaffEmail', () {
    test('detecta el dominio de la clínica sin importar mayúsculas', () {
      expect(Validators.isStaffEmail('Medico@ClinicaPlus.co', 'clinicaplus.co'), isTrue);
    });

    test('un correo personal no es del personal', () {
      expect(Validators.isStaffEmail('medico@gmail.com', 'clinicaplus.co'), isFalse);
    });

    test('no confunde subdominios parecidos', () {
      expect(Validators.isStaffEmail('x@fakeclinicaplus.co', 'clinicaplus.co'), isFalse);
    });
  });

  group('Validators.fullName', () {
    test('exige nombre y apellido', () {
      expect(Validators.fullName('Ana'), 'Escribe nombre y apellido');
      expect(Validators.fullName('Ana Gómez'), isNull);
    });
  });
}
