import 'package:supabase_flutter/supabase_flutter.dart';

class DebugHelper {
  static final supabase = Supabase.instance.client;

  static Future<void> testDatabaseConnection() async {
    try {
      print('=== PRUEBA DE CONEXIÓN A BASE DE DATOS ===');

      // Probar conexión básica
      print('1. Probando conexión básica...');
      await supabase.from('roles').select('count').limit(1);
      print('✓ Conexión exitosa');

      // Verificar tabla roles
      print('2. Verificando tabla roles...');
      final roles = await supabase.from('roles').select('*');
      print('Roles encontrados: ${roles.length}');
      for (var role in roles) {
        print('  - ID: ${role['id']}, Nombre: ${role['nombre_rol']}');
      }

      // Verificar tabla perfil
      print('3. Verificando tabla perfil...');
      final perfiles = await supabase.from('perfil').select('*').limit(5);
      print('Perfiles encontrados: ${perfiles.length}');
      for (var perfil in perfiles) {
        print('  - Email: ${perfil['email']}, Rol ID: ${perfil['id_rol']}');
      }

      print('=== PRUEBA COMPLETADA ===');
    } catch (e) {
      print('❌ Error en prueba de base de datos: $e');
    }
  }

  static Future<void> insertTestRoles() async {
    try {
      print('=== INSERTANDO ROLES DE PRUEBA ===');

      // Verificar si ya existen los roles
      final existingRoles = await supabase.from('roles').select('*');
      print('Roles existentes: ${existingRoles.length}');

      if (existingRoles.length >= 3) {
        print('Los roles ya existen, no se insertarán duplicados');
        return;
      }

      // Insertar roles de prueba uno por uno para evitar conflictos
      try {
        await supabase.from('roles').insert({
          'id': 1,
          'nombre_rol': 'usuario_app',
        });
        print('✓ Rol usuario_app insertado');
      } catch (e) {
        print('Rol usuario_app ya existe o error: $e');
      }

      try {
        await supabase.from('roles').insert({
          'id': 2,
          'nombre_rol': 'usuario_clinica',
        });
        print('✓ Rol usuario_clinica insertado');
      } catch (e) {
        print('Rol usuario_clinica ya existe o error: $e');
      }

      try {
        await supabase.from('roles').insert({'id': 3, 'nombre_rol': 'doctor'});
        print('✓ Rol doctor insertado');
      } catch (e) {
        print('Rol doctor ya existe o error: $e');
      }

      print('✓ Proceso de inserción completado');
    } catch (e) {
      print('❌ Error insertando roles: $e');
    }
  }
}
