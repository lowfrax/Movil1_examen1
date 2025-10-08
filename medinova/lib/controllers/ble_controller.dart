import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Controlador para manejar la lógica BLE y los métodos
class BleController {
  /// Inicia el escaneo de dispositivos BLE
  static void startScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  /// Detiene el escaneo de dispositivos BLE
  static Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Busca la característica para controlar los LEDs
  static Future<BluetoothCharacteristic?> findLedCharacteristic(BluetoothDevice device) async {
    var services = await device.discoverServices();
    for (var s in services) {
      for (var c in s.characteristics) {
        if (c.uuid.toString().toUpperCase() ==
            "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") {
          return c;
        }
      }
    }
    return null;
  }

  /// Envía el comando al ESP32 para encender el LED
  static Future<void> sendCommand(BluetoothCharacteristic characteristic, String cmd) async {
    await characteristic.write(cmd.codeUnits);
  }
}
