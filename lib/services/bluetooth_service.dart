import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

class Esp32BluetoothService {
  static final Esp32BluetoothService _instance = Esp32BluetoothService._internal();
  factory Esp32BluetoothService() => _instance;
  Esp32BluetoothService._internal();

  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _subscription;
  StreamSubscription<List<fbp.ScanResult>>? _scanSubscription;
  
  bool _isConnected = false;
  bool _isScanning = false;
  final List<fbp.BluetoothDevice> _discoveredDevices = [];
  
  // Callbacks
  Function(String)? onDataReceived;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  // Lista para almacenar los últimos 5 valores de pulso
  final List<int> _pulseReadings = [];
  static const int READINGS_FOR_AVERAGE = 5;

  Future<bool> initialize() async {
    try {
      // Solicitar permisos de Bluetooth
      if (await Permission.bluetoothScan.request().isGranted &&
          await Permission.bluetoothConnect.request().isGranted) {
        return true;
      }
      return false;
    } catch (e) {
      onError?.call('Error al inicializar Bluetooth: $e');
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      return await fbp.FlutterBluePlus.isOn;
    } catch (e) {
      return false;
    }
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isScanning) return;
    
    try {
      _discoveredDevices.clear();
      _isScanning = true;
      
      await fbp.FlutterBluePlus.startScan(timeout: timeout);
      
      _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (fbp.ScanResult result in results) {
          if (!_discoveredDevices.any((d) => d.remoteId == result.device.remoteId)) {
            _discoveredDevices.add(result.device);
          }
        }
      });
    } catch (e) {
      onError?.call('Error al escanear: $e');
      _isScanning = false;
    }
  }

  Future<void> stopScan() async {
    try {
      await fbp.FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _scanSubscription = null;
      _isScanning = false;
    } catch (e) {
      onError?.call('Error al detener escaneo: $e');
    }
  }

  List<fbp.BluetoothDevice> getDiscoveredDevices() {
    return List.unmodifiable(_discoveredDevices);
  }

  Future<bool> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      if (_isConnected && _connectedDevice != null) {
        await disconnect();
      }

      _connectedDevice = device;
      await device.connect(timeout: const Duration(seconds: 15));
      
      // Descubrir servicios
      List<fbp.BluetoothService> services = await device.discoverServices();
      
      // Buscar el servicio Serial (UUID estándar para Bluetooth Serial)
      fbp.BluetoothService? serialService;
      for (fbp.BluetoothService service in services) {
        // UUID común para Bluetooth Serial: 00001101-0000-1000-8000-00805F9B34FB
        if (service.uuid.toString().toUpperCase().contains('1101') ||
            service.uuid.toString().toUpperCase().contains('FFE0')) {
          serialService = service;
          break;
        }
      }
      
      // Si no encontramos el servicio estándar, usar el primero disponible
      if (serialService == null && services.isNotEmpty) {
        serialService = services.first;
      }
      
      if (serialService == null) {
        onError?.call('No se encontró servicio Bluetooth Serial');
        return false;
      }
      
      // Buscar característica para lectura
      for (fbp.BluetoothCharacteristic characteristic in serialService.characteristics) {
        if (characteristic.properties.read || characteristic.properties.notify) {
          _characteristic = characteristic;
          
          // Suscribirse a notificaciones si está disponible
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            _subscription = characteristic.onValueReceived.listen((value) {
              _handleReceivedData(value);
            });
          }
          break;
        }
      }
      
      if (_characteristic == null) {
        onError?.call('No se encontró característica de lectura');
        return false;
      }
      
      _isConnected = true;
      onConnected?.call();
      return true;
    } catch (e) {
      onError?.call('Error al conectar: $e');
      _isConnected = false;
      _connectedDevice = null;
      return false;
    }
  }

  void _handleReceivedData(List<int> data) {
    try {
      // Convertir bytes a string
      String dataString = String.fromCharCodes(data).trim();
      
      // Intentar parsear como número (BPM)
      int? pulseValue = int.tryParse(dataString);
      
      if (pulseValue != null && pulseValue > 0) {
        // Agregar a la lista de lecturas
        _pulseReadings.add(pulseValue);
        
        // Mantener solo los últimos 5 valores
        if (_pulseReadings.length > READINGS_FOR_AVERAGE) {
          _pulseReadings.removeAt(0);
        }
        
        // Si tenemos 5 lecturas, calcular la media
        if (_pulseReadings.length == READINGS_FOR_AVERAGE) {
          int average = (_pulseReadings.reduce((a, b) => a + b) / READINGS_FOR_AVERAGE).round();
          onDataReceived?.call(average.toString());
        } else {
          // Enviar el valor individual mientras se acumulan
          onDataReceived?.call(pulseValue.toString());
        }
      } else {
        // Si no es un número, enviar el string tal cual
        onDataReceived?.call(dataString);
      }
    } catch (e) {
      onError?.call('Error al procesar datos: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      _subscription?.cancel();
      _subscription = null;
      
      if (_characteristic != null) {
        try {
          await _characteristic!.setNotifyValue(false);
        } catch (e) {
          // Ignorar errores al desactivar notificaciones
        }
        _characteristic = null;
      }
      
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
      }
      
      _isConnected = false;
      _pulseReadings.clear();
      onDisconnected?.call();
    } catch (e) {
      onError?.call('Error al desconectar: $e');
    }
  }

  bool get isConnected => _isConnected;
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;
  
  int? getCurrentAverage() {
    if (_pulseReadings.isEmpty) return null;
    return (_pulseReadings.reduce((a, b) => a + b) / _pulseReadings.length).round();
  }
  
  void clearReadings() {
    _pulseReadings.clear();
  }
}

