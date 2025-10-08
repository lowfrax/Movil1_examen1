//#2
/**
 * Pantalla Lista BLE
 *├─ Escanea dispositivos
 *├─ Muestra cada uno en la lista
 *└─ Al tocar → conecta → va a Control LEDs
 */
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../controllers/ble_controller.dart';
import 'ble_led_control_screen.dart';

//Es un StatefulWidget porque la lista de dispositivos BLE cambia dinámicamente al escanear.
class BleDeviceListScreen extends StatefulWidget {
  const BleDeviceListScreen({super.key});

  //createState() crea la instancia del estado _BleDeviceListScreenState
  @override
  State<BleDeviceListScreen> createState() => _BleDeviceListScreenState();
}

class _BleDeviceListScreenState extends State<BleDeviceListScreen> {
  // Lista de dispositivos encontrados en el escaneo BLE
  List<ScanResult> devices = [];

  @override
  void initState() {
    super.initState();
    // Inicia el escaneo de dispositivos BLE usando el controlador
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
    // Detiene el escaneo al salir de la pantalla usando el controlador
  BleController.stopScan();
    super.dispose();
  }

  /// Conecta al dispositivo seleccionado y navega a la pantalla de control
  Future<void> _connectToDevice(BluetoothDevice device) async {
  BleController.stopScan(); // Detiene el escaneo antes de conectar
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
