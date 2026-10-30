/// Un diagnóstico del catálogo CIE-10.
class Cie10Entry {
  const Cie10Entry({required this.code, required this.description});

  final String code;
  final String description;

  factory Cie10Entry.fromJson(Map<String, dynamic> json) => Cie10Entry(
    code: json['code'] as String,
    description: json['description'] as String,
  );

  @override
  bool operator ==(Object other) => other is Cie10Entry && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
