/// Sede de la clínica (tabla `sites`).
class Site {
  const Site({
    required this.id,
    required this.name,
    required this.address,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String address;
  final bool isActive;

  factory Site.fromJson(Map<String, dynamic> json) => Site(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    address: (json['address'] as String?) ?? '',
    isActive: (json['is_active'] as bool?) ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'is_active': isActive,
  };
}
