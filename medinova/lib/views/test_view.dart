import 'package:flutter/material.dart';
import 'ble_view.dart';

/// Vista de prueba para demostrar navegación entre pantallas
class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test View')),
      body: Center(
        child: ElevatedButton(
          // Al presionar el botón, navega a la vista BLE
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BleDeviceListScreen(),
              ),
            );
          },
          child: const Text('Ir a BLE View'),
        ),
      ),
    );
  }
}
