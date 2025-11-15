// Controlador BLE para comunicación con ESP32
// Basado en el patrón del ejemplo proporcionado

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Controlador BLE para comunicación con ESP32
/// Todas sus funciones son static, lo que significa que no necesitas
/// instanciar la clase para usarlas.
class BleController {
  // UUIDs del servicio y características del ESP32
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID_TX = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"; // Para recibir datos (notify)
  static const String CHARACTERISTIC_UUID_RX = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // Para enviar comandos (write)

  /// Inicia el escaneo de dispositivos BLE
  static void startScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  /// Detiene cualquier escaneo activo
  static Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Busca la característica para recibir datos del ESP32 (TX - Notify)
  /// 
  /// Future<BluetoothCharacteristic?> La función es asíncrona, devuelve
  /// un Future, porque descubrir servicios en BLE toma tiempo y no bloquea la UI.
  /// El tipo de retorno es BluetoothCharacteristic?:
  /// Devuelve un objeto BluetoothCharacteristic si encuentra la característica.
  /// Devuelve null si no encuentra la característica.
  static Future<BluetoothCharacteristic?> findTxCharacteristic(BluetoothDevice device) async {
    // Método de Flutter Blue Plus que pide al dispositivo BLE 
    // todos los servicios disponibles.
    var services = await device.discoverServices();

    // Por cada servicio s que encuentre en la lista services… haz lo siguiente
    for (var s in services) {
      // Por cada característica c dentro del servicio s… haz lo siguiente
      for (var c in s.characteristics) {
        // Cuando encuentre la característica correcta, que coincide con la indicada devuelvela
        // y deja de buscar
        if (c.uuid.toString().toUpperCase() == CHARACTERISTIC_UUID_TX.toUpperCase()) {
          return c;
        }
      }
    }
    // sino encuentra retorna null
    return null;
  }

  /// Busca la característica para enviar comandos al ESP32 (RX - Write)
  static Future<BluetoothCharacteristic?> findRxCharacteristic(BluetoothDevice device) async {
    var services = await device.discoverServices();

    for (var s in services) {
      for (var c in s.characteristics) {
        if (c.uuid.toString().toUpperCase() == CHARACTERISTIC_UUID_RX.toUpperCase()) {
          return c;
        }
      }
    }
    return null;
  }

  /// Envía un comando al ESP32
  /// 
  /// Convierte el String cmd en una lista de bytes (List<int>).
  /// BLE no entiende strings directamente, necesita enviar bytes.
  static Future<void> sendCommand(BluetoothCharacteristic characteristic, String cmd) async {
    await characteristic.write(cmd.codeUnits, withoutResponse: false);
  }
}

