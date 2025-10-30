class Caso {
  final int id;
  final int idUsuario;
  final int idDoctor;
  final String nombreCaso;
  final String estadoCaso; // pendiente | analizando | finalizado
  final DateTime? createdAt;
  final int deleted;

  const Caso({
    required this.id,
    required this.idUsuario,
    required this.idDoctor,
    required this.nombreCaso,
    required this.estadoCaso,
    required this.deleted,
    this.createdAt,
  });

  factory Caso.fromMap(Map<String, dynamic> map) {
    return Caso(
      id: (map['id'] ?? 0) is int ? map['id'] as int : int.parse(map['id'].toString()),
      idUsuario: (map['id_usuario'] ?? 0) is int
          ? map['id_usuario'] as int
          : int.parse(map['id_usuario'].toString()),
      idDoctor: (map['id_doctor'] ?? 0) is int
          ? map['id_doctor'] as int
          : int.parse(map['id_doctor'].toString()),
      nombreCaso: (map['nombre_caso'] ?? '').toString(),
      estadoCaso: (map['estado_caso'] ?? 'pendiente').toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      deleted: (map['deleted'] ?? 0) is int ? map['deleted'] as int : int.parse(map['deleted'].toString()),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'id_usuario': idUsuario,
      'id_doctor': idDoctor,
      'nombre_caso': nombreCaso,
      'estado_caso': estadoCaso,
      'deleted': deleted,
    };
  }
}


