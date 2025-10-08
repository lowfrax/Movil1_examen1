import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../controllers/ble_controller.dart';

/// Vista para listar dispositivos BLE y navegar a la pantalla de control de LEDs
/// Esta pantalla se llama desde TestScreen usando Navigator.push
class BleDeviceListScreen extends StatefulWidget {
  const BleDeviceListScreen({super.key});

  @override
  State<BleDeviceListScreen> createState() => _BleDeviceListScreenState();
}

class _BleDeviceListScreenState extends State<BleDeviceListScreen> {
  // Lista de dispositivos encontrados en el escaneo BLE
  List<ScanResult> devices = [];

  @override
  void initState() {
    super.initState();
    // Inicia el escaneo de dispositivos BLE
    BleController.startScan();
    // Escucha los resultados del escaneo y actualiza la lista de dispositivos
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        devices = results.toSet().toList(); // Filtra duplicados
      });
    });
  }

  @override
  void dispose() {
    // Detiene el escaneo al salir de la pantalla
    BleController.stopScan();
    super.dispose();
  }

  /// Conecta al dispositivo seleccionado y navega a la pantalla de control
  Future<void> _connectToDevice(BluetoothDevice device) async {
    await BleController.stopScan(); // Detiene el escaneo antes de conectar
    await device.connect(); // Realiza la conexión BLE
    // Navega a la pantalla de control de LEDs
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BleLedControlScreen(device: device),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispositivos BLE')),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final d = devices[index].device;
          return ListTile(
            title: Text(d.platformName.isNotEmpty ? d.platformName : "Sin nombre"),
            subtitle: Text(d.remoteId.str),
            onTap: () => _connectToDevice(d), // Al tocar conecta y navega
          );
        },
      ),
    );
  }
}

/// Vista para controlar los LEDs del ESP32
/// Se navega aquí desde BleDeviceListScreen
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

  /// Descubre el servicio y característica BLE para enviar comandos
  Future<void> _discoverServices() async {
    characteristic = await BleController.findLedCharacteristic(widget.device);
    setState(() {}); // Actualiza la vista cuando se encuentra la característica
  }

  /// Envía el comando para encender el LED correspondiente
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
