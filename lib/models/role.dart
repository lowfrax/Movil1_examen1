class Role {
  final int id;
  final String nombreRol;
  final DateTime createdAt;

  Role({required this.id, required this.nombreRol, required this.createdAt});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      nombreRol: json['nombre_rol'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_rol': nombreRol,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => nombreRol;
}
