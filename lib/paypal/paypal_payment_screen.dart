import 'package:flutter/material.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:medinova/paypal/paypal_service.dart';
import 'package:medinova/paypal/paypal_key_service.dart';
import 'package:medinova/sound_helper.dart';
import 'package:medinova/models/role.dart';

class PayPalPaymentScreen extends StatefulWidget {
  final String email;
  final String password;
  final String name;
  final String phone;
  final String countryCode;
  final Role selectedRole;

  const PayPalPaymentScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    required this.countryCode,
    required this.selectedRole,
  });

  @override
  State<PayPalPaymentScreen> createState() => _PayPalPaymentScreenState();
}

class _PayPalPaymentScreenState extends State<PayPalPaymentScreen> {
  bool _isProcessing = false;
  bool _isLoadingCredentials = true;
  String? _errorMessage;

  // Credenciales de PayPal
  String? _clientId;
  String? _secretKey;
  String? _displayAppName;

  // Monto a pagar
  final double _amount = PayPalService.amount;
  final String _currency = PayPalService.currency;

  // Modo sandbox por defecto en true (modo de prueba)
  static const bool _sandboxMode = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    try {
      final credentials = await PayPalKeyService.getAllCredentials();
      setState(() {
        _clientId = credentials['clientId'];
        _secretKey = credentials['secretKey'];
        _displayAppName = credentials['displayAppName'];
        _isLoadingCredentials = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar credenciales: $e';
        _isLoadingCredentials = false;
      });
    }
  }

  Future<void> _processPayment() async {
    SoundHelper.playSelectSound();

    // Verificar que las credenciales estén cargadas
    if (_clientId == null || _secretKey == null || _displayAppName == null) {
      _reportError('Las credenciales de PayPal no están disponibles. Por favor, intenta nuevamente.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      print('PayPal Client ID: ${_clientId!.substring(0, _clientId!.length > 10 ? 10 : _clientId!.length)}...');
      print('PayPal Sandbox Mode: $_sandboxMode');

      // Crear la transacción
      final transactions = PayPalService.createTransaction(
        amount: _amount,
        currency: _currency,
        description: 'Cuota de registro en $_displayAppName',
      );

      // Navegar a la pantalla de checkout de PayPal
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (BuildContext context) => PaypalCheckoutView(
            sandboxMode: _sandboxMode,
            clientId: _clientId!,
            secretKey: _secretKey!,
            transactions: transactions,
            note: "Contacta con nosotros si tienes alguna pregunta sobre tu pedido.",
            onSuccess: (Map params) async {
              print("onSuccess: $params");
              // Retornar éxito
              Navigator.of(context).pop({'success': true, 'params': params});
            },
            onError: (error) {
              print("onError: $error");
              Navigator.of(context).pop({'success': false, 'error': error.toString()});
            },
            onCancel: () {
              print('cancelled:');
              Navigator.of(context).pop({'success': false, 'cancelled': true});
            },
          ),
        ),
      );

      // Procesar el resultado
      if (result != null) {
        if (result['success'] == true) {
          // Pago exitoso
          print('PayPal payment successful: ${result['params']}');
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else if (result['cancelled'] == true) {
          // Usuario canceló
          print('PayPal payment cancelled by user');
          setState(() {
            _isProcessing = false;
          });
        } else {
          // Error en el pago
          final errorMsg = result['error'] ?? 'Error desconocido en el pago';
          print('PayPal payment error: $errorMsg');
          _reportError('Error de PayPal: $errorMsg');
        }
      } else {
        // No se retornó resultado (usuario cerró la pantalla)
        print('PayPal payment: No result returned');
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e, stackTrace) {
      print('PayPal payment exception: $e');
      print('Stack trace: $stackTrace');
      _reportError('Error inesperado: $e');
    } finally {
      if (mounted && _isProcessing) {
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
    // Mostrar loading mientras se cargan las credenciales
    if (_isLoadingCredentials) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pago de Registro - PayPal'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago de Registro - PayPal'),
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
                // Header con logo de PayPal
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 40, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Text(
                        'PayPal',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
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
                  'Paga de forma segura con PayPal.',
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
                        '\$${_amount.toStringAsFixed(2)} $_currency',
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
                        'Información de pago',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tus datos se procesan de forma segura a través de PayPal. No almacenamos información de pago.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón para abrir PayPal Checkout
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
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Pagar con PayPal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Banner informativo (se mostrará si detecta sandbox)
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
                            'Inicia sesión con tu cuenta de PayPal para completar el pago.',
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

