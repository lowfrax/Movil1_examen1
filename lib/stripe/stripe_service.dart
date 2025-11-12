import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:medinova/stripe/stripe_key_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  // Crear un PaymentIntent en el servidor
  // En producción, esto debería hacerse en un backend seguro
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String currency,
  }) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents');

      final body = <String, String>{
        'amount': amount.toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      // Obtener la clave secreta desde Supabase
      final secretKey = await StripeKeyService.getSecretKey();

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'clientSecret': data['client_secret'],
          'paymentIntentId': data['id'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error':
              errorData['error']['message'] ?? 'Error al crear PaymentIntent',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Inicializar Payment Sheet (método seguro recomendado por Stripe)
  static Future<void> initPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.light,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Presentar Payment Sheet
  static Future<void> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      rethrow;
    }
  }

  // Verificar el estado del pago
  static Future<Map<String, dynamic>> getPaymentIntentStatus({
    required String paymentIntentId,
  }) async {
    try {
      // Obtener la clave secreta desde Supabase
      final secretKey = await StripeKeyService.getSecretKey();

      final url = Uri.parse(
        'https://api.stripe.com/v1/payment_intents/$paymentIntentId',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $secretKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'status': data['status'],
          'paymentIntent': data,
        };
      } else {
        return {'success': false, 'error': 'Error al verificar el pago'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
