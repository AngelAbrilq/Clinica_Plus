/// Validadores de formularios. Las reglas replican los CHECK de la base
/// de datos para que el usuario vea el error antes de enviar.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$',
  );
  static final RegExp _documentPattern = RegExp(r'^[0-9A-Za-z]{4,20}$');
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');
  static final RegExp _hasLetter = RegExp(r'[A-Za-z]');
  static final RegExp _hasDigit = RegExp(r'[0-9]');

  static String? required(String? value, String fieldName) =>
      (value == null || value.trim().isEmpty)
      ? '$fieldName es obligatorio'
      : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'El correo es obligatorio';
    if (!_emailPattern.hasMatch(value.trim())) return 'Correo no válido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!_hasLetter.hasMatch(value) || !_hasDigit.hasMatch(value)) {
      return 'Debe tener letras y números';
    }
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'El nombre es obligatorio';
    if (value.trim().split(RegExp(r'\s+')).length < 2) {
      return 'Escribe nombre y apellido';
    }
    return null;
  }

  static String? documentNumber(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'El documento es obligatorio';
    if (!_documentPattern.hasMatch(value.trim())) {
      return 'Entre 4 y 20 caracteres, sin espacios ni puntos';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'El celular es obligatorio';
    if (!_phonePattern.hasMatch(value.trim())) return 'Celular no válido';
    return null;
  }

  /// True si el correo pertenece al dominio del personal de la clínica.
  static bool isStaffEmail(String email, String staffDomain) =>
      email.trim().toLowerCase().endsWith('@${staffDomain.toLowerCase()}');
}
