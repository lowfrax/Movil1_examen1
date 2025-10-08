//#1

// ignore_for_file: slash_for_doc_comments

//imprtacion de libreria de bluetooth
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// definimos una clase para el controlador
/// Todas sus funciones son static, lo que significa que no necesitas
///  instanciar la clase para usarlas.
/// Esto simplifica llamar funciones desde tu UI, por ejemplo: BleController.startScan()
class BleController {

  /**
   * Secuencia lógica: 
   * Primero hay que escanear para obtener dispositivos antes de intentar conectarse.
   * 
   * una vez conectado: Secuencia: Siempre se debe detener el escaneo antes de conectar a un dispositivo,
   *  para evitar conflictos
   * 
   * 
   */



  /// metodo Inicia el escaneo de dispositivos BLE
  static void startScan() {
    //método de la librería que comienza a buscar dispositivos cercanos por 15 seg
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  /// metodo Detiene cualquier escaneo activo.
  /**
   * Es asíncrona (Future<void>) porque detener el escaneo puede tardar un momento en completarse.
   * await asegura que el escaneo realmente se detenga antes de continuar.
   */

  static Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }



  /// metodo Busca la característica para controlar los LEDs
  
  /**
   * Future<BluetoothCharacteristic?>La función es asíncrona, devuelve
   *  un Future, porque descubrir servicios en BLE toma tiempo y no bloquea la UI.
   * El tipo de retorno es BluetoothCharacteristic?:
   * Devuelve un objeto BluetoothCharacteristic si encuentra la característica.
   * Devuelve null si no encuentra la característica.
   * 
   * findLedCharacteristic(BluetoothDevice device)
   * Recibe un dispositivo Bluetooth previamente conectado.
   * El objetivo es buscar dentro de ese dispositivo la característica específica que controla los LEDs.
   * 
   */


  static Future<BluetoothCharacteristic?> findLedCharacteristic(BluetoothDevice device) async {
    //Método de Flutter Blue Plus que pide al dispositivo BLE 
    //todos los servicios disponibles.

    //Piensa en services como una lista de cajas, y cada caja tiene varias cosas adentro (las características).
    var services = await device.discoverServices();

    //Por cada servicio s que encuentre en la lista services… haz lo siguiente
    for (var s in services) {
      //Por cada característica c dentro del servicio s… haz lo siguiente
      for (var c in s.characteristics) {
        //Cuando encuentre la característica correcta, que coincide con la indicada devuelvela
        //y deja de buscar
        if (c.uuid.toString().toUpperCase() ==
            "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") {
          return c;
        }
      }
    }
    //sino encuentra retorna null
    return null;
  }


  /// No devuelve valor solo se utiliza para enviar texo al cmd de el esp32
  /**
   * Convierte el String cmd en una lista de bytes (List<int>).
   * BLE no entiende strings directamente, necesita enviar bytes.
   * 
   * 
   *  */ 
  static Future<void> sendCommand(BluetoothCharacteristic characteristic, String cmd) async {
    await characteristic.write(cmd.codeUnits);
  }
}
