import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class WebhookService {
  static const String _webhookUrl =
      'https://ideally-wordy-elene.ngrok-free.dev/webhook/b3780e3c-eabc-44ff-9f4d-9ce075f27ba5';
  static const String _fileWebhookUrl =
      'https://ideally-wordy-elene.ngrok-free.dev/webhook/91e80b8b-4d98-452d-ab63-99f60fa84a6a';

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Envía un mensaje al webhook de n8n con los datos del usuario
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String email,
    required String telefono,
    int? idCaso,
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
        if (idCaso != null) 'id_caso': idCaso,
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

  /// Sube un archivo al webhook de n8n
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String email,
    required String telefono,
    int? idCaso,
  }) async {
    try {
      final url = Uri.parse(_fileWebhookUrl);

      // Validar tipo de archivo
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();

      if (!['.pdf', '.doc', '.docx'].contains(fileExtension)) {
        return {
          'success': false,
          'error': 'Solo se permiten archivos PDF y Word (.pdf, .doc, .docx)',
        };
      }

      // Leer el archivo como bytes
      final fileBytes = await file.readAsBytes();

      // Crear la solicitud multipart
      final request = http.MultipartRequest('POST', url);

      // Agregar headers
      request.headers.addAll({'ngrok-skip-browser-warning': 'true'});

      // Agregar campos
      request.fields['email'] = email.toString();
      request.fields['telefono'] = telefono.toString();
      if (idCaso != null) request.fields['id_caso'] = idCaso.toString();

      // Agregar el archivo
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      print('Subiendo archivo al webhook: $fileName'); // Debug

      // Enviar la solicitud
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
        'Respuesta del webhook de archivos: ${response.statusCode} - ${response.body}',
      ); // Debug

      if (response.statusCode == 200) {
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
      print('Error en uploadFile: $e'); // Debug
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Eliminado: no insertamos mensajes manualmente en la tabla de n8n

  /// Inserta un mensaje del usuario en public.chat_general (por id_caso)
  Future<void> insertChatGeneralUser({
    required String message,
    required int idCaso,
  }) async {
    await _supabase.from('chat_general').insert({
      'id_caso': idCaso,
      'message': message,
      'type': 'user',
      // created_at es autogenerado
    });
  }

  /// Inserta un mensaje de la IA en public.chat_general (por id_caso)
  Future<void> insertChatGeneralIA({
    required String message,
    required int idCaso,
  }) async {
    await _supabase.from('chat_general').insert({
      'id_caso': idCaso,
      'message': message,
      'type': 'IA',
      // created_at es autogenerado
    });
  }

  /// Trae historial de chat_general por id_caso
  Future<List<Map<String, dynamic>>> getChatGeneralByCaso(int idCaso) async {
    try {
      final response = await _supabase
          .from('chat_general')
          .select('id, id_caso, message, type, created_at')
          .eq('id_caso', idCaso)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error al obtener chat_general: $e');
      return [];
    }
  }

  /// Obtiene el historial de mensajes del usuario basado en su teléfono
  Future<List<Map<String, dynamic>>> getChatHistory(String telefono) async {
    try {
      // Filtrar por session_id exactamente igual al teléfono del perfil
      final response = await _supabase
          .from('n8n_chat_histories')
          .select('id, session_id, message')
          .eq('session_id', telefono)
          .order('id', ascending: false);

      print(
        'Historial encontrado para teléfono $telefono: ${response.length} mensajes',
      );

      // Mapear jsonb message → { message: String, created_at: String? }
      final List<dynamic> rows = response as List<dynamic>;
      return rows.map<Map<String, dynamic>>((row) {
        final Map<String, dynamic> r = Map<String, dynamic>.from(row);
        final dynamic msg = r['message'];
        String messageText = '';
        String? createdAt;
        String? type;
        if (msg is Map<String, dynamic>) {
          messageText = (msg['content'] ?? msg['text'] ?? msg['message'] ?? '')
              .toString();
          createdAt = (msg['created_at'] ?? msg['timestamp'] ?? msg['time'])
              ?.toString();
          type = (msg['type'] ?? '').toString();
        } else {
          messageText = msg?.toString() ?? '';
        }
        return {
          'message': messageText,
          'created_at': createdAt,
          'id': r['id'],
          'session_id': r['session_id'],
          'type': type,
        };
      }).toList();
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
