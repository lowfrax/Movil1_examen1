import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:medinova/stripe/stripe_service.dart';
import 'package:medinova/sound_helper.dart';
import 'package:medinova/models/role.dart';

class PaymentScreen extends StatefulWidget {
  final String email;
  final String password;
  final String name;
  final String phone;
  final String countryCode;
  final Role selectedRole;

  const PaymentScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    required this.countryCode,
    required this.selectedRole,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  // Monto mínimo de Stripe: $0.50 USD = 50 centavos
  final int _amount = 100; // $1.00 USD en centavos
  final String _currency = 'usd';

  Future<void> _processPayment() async {
    SoundHelper.playSelectSound();

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Crear PaymentIntent
      final paymentIntentResult = await StripeService.createPaymentIntent(
        amount: _amount,
        currency: _currency,
      );

      if (!paymentIntentResult['success']) {
        _reportError(
          'No se pudo crear el intento de pago: ${paymentIntentResult['error']}',
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final clientSecret = paymentIntentResult['clientSecret'] as String;
      final paymentIntentId = paymentIntentResult['paymentIntentId'] as String;

      // Inicializar Payment Sheet
      await StripeService.initPaymentSheet(
        clientSecret: clientSecret,
        merchantDisplayName: 'Medinova',
      );

      // Presentar Payment Sheet
      await StripeService.presentPaymentSheet();

      // Verificar el estado del pago
      final statusResult = await StripeService.getPaymentIntentStatus(
        paymentIntentId: paymentIntentId,
      );

      if (statusResult['success'] && statusResult['status'] == 'succeeded') {
        // Pago exitoso
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('El pago no se completó correctamente');
      }
    } on StripeException catch (e) {
      // StripeException puede ser cancelado por el usuario
      if (e.error.code == 'FailureCode.Canceled') {
        // Usuario canceló, no mostrar error
        setState(() {
          _isProcessing = false;
        });
        return;
      }
      final message = e.error.message ?? 'Error desconocido de Stripe';
      _reportError('Error de Stripe: $message');
    } catch (e) {
      _reportError('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _reportError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago de Registro'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade400],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Icon(Icons.credit_card, size: 60, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  'Completa tu registro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Introduce los datos de tu tarjeta para confirmar la cuota de registro.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 30),

                // Monto a pagar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Text(
                        'Monto a pagar:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      Text(
                        '\$${(_amount / 100).toStringAsFixed(2)} USD',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Información sobre seguridad
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de la tarjeta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tus datos se envían cifrados a Stripe y no se almacenan en nuestros servidores.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón para abrir Payment Sheet
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Ingresar datos de tarjeta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón cancelar
                TextButton(
                  onPressed: () {
                    SoundHelper.playSelectSound();
                    Navigator.of(context).pop(false);
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Banner informativo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Modo de prueba activo. Utiliza tarjetas de prueba de Stripe (por ejemplo: 4242 4242 4242 4242, cualquier fecha futura y CVC 123).',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
