import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DeviceListScreen(),
    );
  }
}

// 📡 Pantalla para escanear y elegir el dispositivo
class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  List<ScanResult> devices = [];

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        // Filtramos duplicados
        devices = results.toSet().toList();
      });
    });
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    await device.connect();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LedControlScreen(device: device),
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
            onTap: () => _connectToDevice(d),
          );
        },
      ),
    );
  }
}

// 💡 Pantalla para controlar LEDs
class LedControlScreen extends StatefulWidget {
  final BluetoothDevice device;
  const LedControlScreen({super.key, required this.device});

  @override
  State<LedControlScreen> createState() => _LedControlScreenState();
}

class _LedControlScreenState extends State<LedControlScreen> {
  BluetoothCharacteristic? characteristic;

  @override
  void initState() {
    super.initState();
    _discoverServices();
  }

  Future<void> _discoverServices() async {
    var services = await widget.device.discoverServices();
    for (var s in services) {
      for (var c in s.characteristics) {
        if (c.uuid.toString().toUpperCase() ==
            "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") {
          characteristic = c;
          setState(() {});
        }
      }
    }
  }

  void _sendCommand(String cmd) async {
    if (characteristic != null) {
      await characteristic!.write(cmd.codeUnits);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Control de LEDs (${widget.device.platformName})")),
      body: Center(
        child: characteristic == null
            ? const CircularProgressIndicator()
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
