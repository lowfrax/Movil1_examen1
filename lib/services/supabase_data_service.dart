import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perfil.dart';
import '../models/caso.dart';
import '../models/medicamento.dart';

class SupabaseDataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Perfil?> getCurrentPerfil() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final data = await _supabase.from('perfil').select('*').eq('email', user.email ?? '').maybeSingle();
    if (data == null) return null;
    return Perfil.fromMap(Map<String, dynamic>.from(data));
  }

  Future<List<Perfil>> getDoctores() async {
    final rows = await _supabase.from('perfil').select('id, nombre, email, telefono, id_rol').eq('id_rol', 3);
    return (rows as List).map((e) => Perfil.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<Perfil?> getPerfilById(int id) async {
    final data = await _supabase.from('perfil').select('*').eq('id', id).maybeSingle();
    if (data == null) return null;
    return Perfil.fromMap(Map<String, dynamic>.from(data));
  }

  Future<Caso> crearCaso({required int idUsuario, required int idDoctor, required String nombre}) async {
    final inserted = await _supabase.from('casos').insert({
      'id_usuario': idUsuario,
      'id_doctor': idDoctor,
      'nombre_caso': nombre,
      'estado_caso': 'pendiente',
      'deleted': 0,
    }).select().single();
    return Caso.fromMap(Map<String, dynamic>.from(inserted));
  }

  Future<List<Caso>> listarCasosPorUsuario(int idUsuario, {String? filtroNombre}) async {
    final base = _supabase.from('casos').select('*').eq('id_usuario', idUsuario).neq('deleted', 1);
    final rows = filtroNombre != null && filtroNombre.trim().isNotEmpty
        ? await base.ilike('nombre_caso', '%${filtroNombre.trim()}%').order('created_at', ascending: false)
        : await base.order('created_at', ascending: false);
    return (rows as List).map((e) => Caso.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> actualizarCaso({required int idCaso, String? nombre, int? idDoctor}) async {
    final update = <String, dynamic>{};
    if (nombre != null) update['nombre_caso'] = nombre;
    if (idDoctor != null) update['id_doctor'] = idDoctor;
    if (update.isEmpty) return;
    await _supabase.from('casos').update(update).eq('id', idCaso);
  }

  Future<void> actualizarEstadoCaso({required int idCaso, required String estado}) async {
    await _supabase.from('casos').update({'estado_caso': estado}).eq('id', idCaso);
  }

  Future<void> eliminarLogicoCaso(int idCaso) async {
    await _supabase.from('casos').update({'deleted': 1}).eq('id', idCaso);
  }

  Future<Caso?> getCasoById(int idCaso) async {
    final data = await _supabase.from('casos').select('*').eq('id', idCaso).maybeSingle();
    if (data == null) return null;
    return Caso.fromMap(Map<String, dynamic>.from(data));
  }

  // Chat General por id_caso
  Future<List<Map<String, dynamic>>> getChatGeneralByCaso(int idCaso) async {
    final rows = await _supabase
        .from('chat_general')
        .select('id, message, type, created_at, id_caso')
        .eq('id_caso', idCaso)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> insertChat({required int idCaso, required String message, required String type}) async {
    await _supabase.from('chat_general').insert({
      'id_caso': idCaso,
      'message': message,
      'type': type,
    });
  }

  // Medicamentos
  Future<List<Medicamento>> getMedicamentosByCaso(int idCaso) async {
    final rows = await _supabase
        .from('medicamentos')
        .select('id, nombre_medicamento, id_caso, prescripcion, created_at, url_web, url_drive, type, id_doctor, url_image')
        .eq('id_caso', idCaso)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Medicamento.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<Medicamento> crearMedicamento(Medicamento medic) async {
    final inserted = await _supabase.from('medicamentos').insert(medic.toInsertMap()).select().single();
    return Medicamento.fromMap(Map<String, dynamic>.from(inserted));
  }

  Future<void> actualizarMedicamento({
    required int idMedicamento,
    String? nombreMedicamento,
    String? prescripcion,
    String? urlWeb,
    String? urlDrive,
    String? urlImage,
    String? type,
  }) async {
    final update = <String, dynamic>{};
    if (nombreMedicamento != null) update['nombre_medicamento'] = nombreMedicamento;
    if (prescripcion != null) update['prescripcion'] = prescripcion;
    if (urlWeb != null) update['url_web'] = urlWeb;
    if (urlDrive != null) update['url_drive'] = urlDrive;
    if (urlImage != null) update['url_image'] = urlImage;
    if (type != null) update['type'] = type;
    if (update.isEmpty) return;
    await _supabase.from('medicamentos').update(update).eq('id', idMedicamento);
  }

  Future<void> eliminarMedicamento(int idMedicamento) async {
    await _supabase.from('medicamentos').delete().eq('id', idMedicamento);
  }

  // Método para insertar datos de pulso del ESP32
  Future<void> insertarPulsoESP32({required int casoId, required int pulso}) async {
    await _supabase.from('esp32').insert({
      'caso_id': casoId,
      'pulso': pulso,
    });
  }
}


