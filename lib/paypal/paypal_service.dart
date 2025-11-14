class PayPalService {
  // Monto mínimo de PayPal: $1.00 USD
  static const double amount = 1.00;
  static const String currency = 'USD';

  // Crear la configuración de transacción para PayPal
  static List<Map<String, dynamic>> createTransaction({
    required double amount,
    String currency = 'USD',
    String description = 'Cuota de registro',
  }) {
    return [
      {
        "amount": {
          "total": amount.toStringAsFixed(2),
          "currency": currency,
          "details": {
            "subtotal": amount.toStringAsFixed(2),
            "shipping": '0.00',
            "shipping_discount": 0
          }
        },
        "description": description,
        "item_list": {
          "items": [
            {
              "name": "Registro en Medinova",
              "quantity": 1,
              "price": amount.toStringAsFixed(2),
              "currency": currency
            }
          ],
        }
      }
    ];
  }
}

