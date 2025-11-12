import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medinova/models/role.dart';

class RoleService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<Role>> getRoles() async {
    try {
      final response = await _supabase
          .from('roles')
          .select('id, nombre_rol, created_at')
          .order('nombre_rol');

      return response.map<Role>((json) => Role.fromJson(json)).toList();
    } catch (e) {
      print('Error obteniendo roles: $e');
      // Retornar roles por defecto si hay error
      return [
        Role(id: 1, nombreRol: 'Usuario App', createdAt: DateTime.now()),
        Role(id: 2, nombreRol: 'Usuario Clínica', createdAt: DateTime.now()),
        Role(id: 3, nombreRol: 'Doctor', createdAt: DateTime.now()),
      ];
    }
  }

  static Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _supabase
          .from('perfil')
          .select('email')
          .eq('email', email)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error verificando email: $e');
      return false;
    }
  }

  static Future<bool> checkPhoneExists(String phone) async {
    try {
      final response = await _supabase
          .from('perfil')
          .select('telefono')
          .eq('telefono', phone)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error verificando teléfono: $e');
      return false;
    }
  }
}
