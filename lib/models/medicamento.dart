class Medicamento {
  final int id;
  final String nombreMedicamento;
  final int idCaso;
  final String? prescripcion;
  final DateTime? createdAt;
  final String? urlWeb;
  final String? urlDrive;
  final String type; // IA | doctor
  final int? idDoctor;
  final String? urlImage;

  const Medicamento({
    required this.id,
    required this.nombreMedicamento,
    required this.idCaso,
    required this.type,
    this.prescripcion,
    this.createdAt,
    this.urlWeb,
    this.urlDrive,
    this.idDoctor,
    this.urlImage,
  });

  factory Medicamento.fromMap(Map<String, dynamic> map) {
    return Medicamento(
      id: (map['id'] ?? 0) is int ? map['id'] as int : int.parse(map['id'].toString()),
      nombreMedicamento: (map['nombre_medicamento'] ?? '').toString(),
      idCaso: (map['id_caso'] ?? 0) is int ? map['id_caso'] as int : int.parse(map['id_caso'].toString()),
      prescripcion: map['prescripcion']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      urlWeb: map['url_web']?.toString(),
      urlDrive: map['url_drive']?.toString(),
      type: (map['type'] ?? 'IA').toString(),
      idDoctor: map['id_doctor'] == null ? null : ((map['id_doctor'] is int) ? map['id_doctor'] as int : int.tryParse(map['id_doctor'].toString())),
      urlImage: map['url_image']?.toString(),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'nombre_medicamento': nombreMedicamento,
      'id_caso': idCaso,
      'prescripcion': prescripcion,
      'url_web': urlWeb,
      'url_drive': urlDrive,
      'type': type,
      'id_doctor': idDoctor,
      'url_image': urlImage,
    };
  }
}


