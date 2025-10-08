import 'package:flutter/material.dart';
import 'views/test_view.dart'; // Vista de prueba, navega a BLE

void main() {
  runApp(const MyApp());
}

/// Punto de entrada de la app, solo muestra la vista principal
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
  home: TestScreen(), // ← Ahora la vista inicial es TestScreen
    );
  }
}
