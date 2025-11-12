import 'package:supabase_flutter/supabase_flutter.dart';

class StripeKeyService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  static String? _cachedPublicKey;
  static String? _cachedSecretKey;
  
  // Obtener la clave pública de Stripe desde Supabase
  static Future<String> getPublicKey() async {
    if (_cachedPublicKey != null) {
      return _cachedPublicKey!;
    }
    
    try {
      final response = await _supabase
          .from('secret')
          .select('public_key')
          .eq('id', 1)
          .single();
      
      _cachedPublicKey = response['public_key'] as String;
      return _cachedPublicKey!;
    } catch (e) {
      throw Exception('Error al obtener la clave pública de Stripe: $e');
    }
  }
  
  // Obtener la clave secreta de Stripe desde Supabase
  static Future<String> getSecretKey() async {
    if (_cachedSecretKey != null) {
      return _cachedSecretKey!;
    }
    
    try {
      final response = await _supabase
          .from('secret')
          .select('secret_key')
          .eq('id', 1)
          .single();
      
      _cachedSecretKey = response['secret_key'] as String;
      return _cachedSecretKey!;
    } catch (e) {
      throw Exception('Error al obtener la clave secreta de Stripe: $e');
    }
  }
  
  // Limpiar caché (útil si las claves cambian)
  static void clearCache() {
    _cachedPublicKey = null;
    _cachedSecretKey = null;
  }
}

