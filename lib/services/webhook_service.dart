import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class WebhookService {
  static const String _webhookUrl =
      'https://ideally-wordy-elene.ngrok-free.dev/webhook/b3780e3c-eabc-44ff-9f4d-9ce075f27ba5';

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Envía un mensaje al webhook de n8n con los datos del usuario
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String email,
    required String telefono,
  }) async {
    try {
      // Validar y convertir parámetros a String
      final String messageStr = message.toString();
      final String emailStr = email.toString();
      final String telefonoStr = telefono.toString();

      final url = Uri.parse(_webhookUrl);
      final body = {
        'mensaje': messageStr,
        'email': emailStr,
        'telefono': telefonoStr,
      };

      print('Enviando al webhook: $body'); // Debug

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Para evitar warnings de ngrok
        },
        body: jsonEncode(body),
      );

      print(
        'Respuesta del webhook: ${response.statusCode} - ${response.body}',
      ); // Debug

      if (response.statusCode == 200) {
        // Guardar el mensaje en la base de datos
        await _saveMessageToDatabase(messageStr, emailStr, telefonoStr);

        return {
          'success': true,
          'statusCode': response.statusCode,
          'response': response.body,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'response': response.body,
          'error': 'Error en el servidor',
        };
      }
    } catch (e) {
      print('Error en sendMessage: $e'); // Debug
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Guarda el mensaje en la base de datos
  Future<void> _saveMessageToDatabase(
    String message,
    String email,
    String telefono,
  ) async {
    try {
      // Generar un session_id único basado en el teléfono
      final sessionId =
          'session_${telefono}_${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('n8n_chat_histories').insert({
        'session_id': sessionId,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al guardar mensaje en la base de datos: $e');
    }
  }

  /// Obtiene el historial de mensajes del usuario basado en su teléfono
  Future<List<Map<String, dynamic>>> getChatHistory(String telefono) async {
    try {
      // Buscar todos los mensajes que coincidan con el teléfono del usuario
      final response = await _supabase
          .from('n8n_chat_histories')
          .select('*')
          .like('session_id', 'session_${telefono}_%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error al obtener historial de chat: $e');
      return [];
    }
  }

  /// Obtiene los datos del perfil del usuario actual
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('perfil')
          .select('*')
          .eq('email', user.email ?? '')
          .single();

      // Convertir los campos a String para evitar errores de tipo
      final Map<String, dynamic> profile = Map<String, dynamic>.from(response);

      // Asegurar que telefono sea String
      if (profile['telefono'] != null) {
        profile['telefono'] = profile['telefono'].toString();
      }

      // Asegurar que email sea String
      if (profile['email'] != null) {
        profile['email'] = profile['email'].toString();
      }

      return profile;
    } catch (e) {
      print('Error al obtener perfil del usuario: $e');
      return null;
    }
  }
}
