class Perfil {
  final int id;
  final String nombre;
  final String email;
  final String telefono;
  final int idRol;

  const Perfil({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.idRol,
  });

  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      id: (map['id'] ?? 0) is int ? map['id'] as int : int.parse(map['id'].toString()),
      nombre: (map['nombre'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      telefono: (map['telefono'] ?? '').toString(),
      idRol: (map['id_rol'] ?? 0) is int ? map['id_rol'] as int : int.parse(map['id_rol'].toString()),
    );
  }
}


