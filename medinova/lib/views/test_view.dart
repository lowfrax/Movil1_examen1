//#3

import 'package:flutter/material.dart';
import 'ble_device_list_screen.dart';

/// Vista de prueba para demostrar navegación entre pantallas



/// StatelessWidget es una clase base de Flutter para widgets que no c
/// ambian de estado una vez construidos.
/// 
/// “No cambian de estado” significa que su apariencia o datos no se actuali
///  zan dinámicamente después de que se renderizan, a menos que se 
/// reconstruya todo el widget padre.

class TestScreen extends StatelessWidget {
  //contructor
  const TestScreen({super.key});

  //metodo para dibujar wigets en pantalla y ocupa un retorno
  @override
  Widget build(BuildContext context) {

    /**
     * Es un widget contenedor que proporciona la estructura básica de
     *  una pantalla en Flutter.
     * Incluye elementos comunes como AppBar, body, FloatingActionButton, Drawer,
     *  etc.
     * 
     * 
     */

    return Scaffold(
      //barra superior
      appBar: AppBar(title: const Text('Test View')),
      //centra a todos los elementos hijos
      body: Center(
        //hijo: boton con propiedades especiales similar a 
        /**
         * TextButton: botón plano, sin sombra.
         * OutlinedButton: botón con borde pero transparente.
         * IconButton: botón que solo muestra un ícono.
         */
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              // Navega a la lista de dispositivos BLE
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BleDeviceListScreen(),
                  ),
                );
              },
              child: const Text('Ir a BLE Device List'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              // Navega a la pantalla de control de LEDs BLE (requiere un BluetoothDevice real)
              onPressed: () {
                // Aquí deberías pasar un BluetoothDevice válido en una app real
                // Ejemplo:
                // Navigator.push(context, MaterialPageRoute(builder: (context) => BleLedControlScreen(device: myDevice)));
              },
              child: const Text('Ir a BLE LED Control (requiere device)'),
            ),
          ],
        ),
      ),
    );
  }
}
