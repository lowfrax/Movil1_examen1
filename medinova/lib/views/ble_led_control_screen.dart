// Vista para controlar los LEDs del ESP32
/// Se navega aquí desde BleDeviceListScreen
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../controllers/ble_controller.dart';

class BleLedControlScreen extends StatefulWidget {
  final BluetoothDevice device;
  const BleLedControlScreen({super.key, required this.device});

  @override
  State<BleLedControlScreen> createState() => _BleLedControlScreenState();
}

class _BleLedControlScreenState extends State<BleLedControlScreen> {
  // Característica BLE para enviar comandos al ESP32
  BluetoothCharacteristic? characteristic;

  @override
  void initState() {
    super.initState();
    _discoverServices(); // Busca la característica al iniciar
  }

  /// Descubre el servicio y característica BLE para enviar comandos usando el controlador
  Future<void> _discoverServices() async {
  characteristic = await BleController.findLedCharacteristic(widget.device);
    setState(() {}); // Actualiza la vista cuando se encuentra la característica
  }

  /// Envía el comando para encender el LED correspondiente usando el controlador
  Future<void> _sendCommand(String cmd) async {
    if (characteristic != null) {
  await BleController.sendCommand(characteristic!, cmd);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Control de LEDs (${widget.device.platformName})")),
      body: Center(
        child: characteristic == null
            // Muestra un indicador de carga mientras se busca la característica
            ? const CircularProgressIndicator()
            // Muestra los botones para controlar los LEDs
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: () => _sendCommand("1"),
                      child: const Text("Encender LED 1")),
                  ElevatedButton(
                      onPressed: () => _sendCommand("2"),
                      child: const Text("Encender LED 2")),
                  ElevatedButton(
                      onPressed: () => _sendCommand("3"),
                      child: const Text("Encender LED 3")),
                ],
              ),
      ),
    );
  }
}
