/// Sede de la clínica (tabla `sites`).
class Site {
  const Site({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String address;
  final String? phone;
  final bool isActive;

  factory Site.fromJson(Map<String, dynamic> json) => Site(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    address: (json['address'] as String?) ?? '',
    phone: json['phone'] as String?,
    isActive: (json['is_active'] as bool?) ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'phone': phone,
    'is_active': isActive,
  };
}

/// Datos para crear o editar una sede (sin id: lo genera la base de datos).
class SiteDraft {
  const SiteDraft({required this.name, required this.address, this.phone});

  final String name;
  final String address;
  final String? phone;

  Map<String, dynamic> toJson() {
    final trimmedPhone = phone?.trim();
    return {
      'name': name.trim(),
      'address': address.trim(),
      'phone': (trimmedPhone == null || trimmedPhone.isEmpty) ? null : trimmedPhone,
    };
  }
}
