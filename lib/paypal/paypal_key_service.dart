import 'package:supabase_flutter/supabase_flutter.dart';

class PayPalKeyService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  static String? _cachedClientId;
  static String? _cachedSecretKey;
  static String? _cachedDisplayAppName;
  
  // Obtener el Client ID de PayPal desde Supabase
  static Future<String> getClientId() async {
    if (_cachedClientId != null) {
      return _cachedClientId!;
    }
    
    try {
      final response = await _supabase
          .from('paypal')
          .select('clientId')
          .eq('id', 1)
          .single();
      
      _cachedClientId = response['clientId'] as String;
      return _cachedClientId!;
    } catch (e) {
      throw Exception('Error al obtener el Client ID de PayPal: $e');
    }
  }
  
  // Obtener el Secret Key de PayPal desde Supabase
  static Future<String> getSecretKey() async {
    if (_cachedSecretKey != null) {
      return _cachedSecretKey!;
    }
    
    try {
      final response = await _supabase
          .from('paypal')
          .select('secretKey')
          .eq('id', 1)
          .single();
      
      _cachedSecretKey = response['secretKey'] as String;
      return _cachedSecretKey!;
    } catch (e) {
      throw Exception('Error al obtener el Secret Key de PayPal: $e');
    }
  }
  
  // Obtener el Display App Name de PayPal desde Supabase
  static Future<String> getDisplayAppName() async {
    if (_cachedDisplayAppName != null) {
      return _cachedDisplayAppName!;
    }
    
    try {
      final response = await _supabase
          .from('paypal')
          .select('displayAppName')
          .eq('id', 1)
          .single();
      
      _cachedDisplayAppName = response['displayAppName'] as String;
      return _cachedDisplayAppName!;
    } catch (e) {
      throw Exception('Error al obtener el Display App Name de PayPal: $e');
    }
  }
  
  // Obtener todas las credenciales de una vez
  static Future<Map<String, String>> getAllCredentials() async {
    try {
      final response = await _supabase
          .from('paypal')
          .select('clientId, secretKey, displayAppName')
          .eq('id', 1)
          .single();
      
      final clientId = response['clientId'] as String?;
      final secretKey = response['secretKey'] as String?;
      final displayAppName = response['displayAppName'] as String?;
      
      if (clientId == null || clientId.isEmpty) {
        throw Exception('Client ID de PayPal no encontrado o vacío');
      }
      if (secretKey == null || secretKey.isEmpty) {
        throw Exception('Secret Key de PayPal no encontrado o vacío');
      }
      if (displayAppName == null || displayAppName.isEmpty) {
        throw Exception('Display App Name de PayPal no encontrado o vacío');
      }
      
      _cachedClientId = clientId;
      _cachedSecretKey = secretKey;
      _cachedDisplayAppName = displayAppName;
      
      return {
        'clientId': clientId,
        'secretKey': secretKey,
        'displayAppName': displayAppName,
      };
    } catch (e) {
      throw Exception('Error al obtener las credenciales de PayPal: $e');
    }
  }
  
  // Limpiar caché (útil si las claves cambian)
  static void clearCache() {
    _cachedClientId = null;
    _cachedSecretKey = null;
    _cachedDisplayAppName = null;
  }
}

