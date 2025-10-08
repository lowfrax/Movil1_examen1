#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// --- Pines elegidos para los 3 LEDs ---
#define LED1 2   // D2
#define LED2 4   // D4
#define LED3 5   // D5

// --- UUIDs para el servicio BLE ---
#define SERVICE_UUID            "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID_RX  "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

// --- Variables BLE ---
BLEServer* pServer = NULL;
bool deviceConnected = false;

// --- Clase para saber si se conecta o desconecta ---
class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
  }
  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
  }
};

// --- Clase para recibir datos desde Flutter ---
class MyCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String rxValue = pCharacteristic->getValue();
    if (rxValue.length() > 0) {
      char cmd = rxValue[0]; // primer caracter enviado
      Serial.print("Comando recibido: ");
      Serial.println(cmd);

      // Apagar todos primero
      digitalWrite(LED1, LOW);
      digitalWrite(LED2, LOW);
      digitalWrite(LED3, LOW);

      // Encender según el comando
      if (cmd == '1') digitalWrite(LED1, HIGH);
      else if (cmd == '2') digitalWrite(LED2, HIGH);
      else if (cmd == '3') digitalWrite(LED3, HIGH);
    }
  }
};

void setup() {
  Serial.begin(115200);

  // Configurar los pines como salida
  pinMode(LED1, OUTPUT);
  pinMode(LED2, OUTPUT);
  pinMode(LED3, OUTPUT);

  // Iniciar BLE
  BLEDevice::init("ESP32_LED");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_RX,
    BLECharacteristic::PROPERTY_WRITE
  );
  pRxCharacteristic->setCallbacks(new MyCallbacks());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  BLEDevice::startAdvertising();

  Serial.println("Esperando conexión Bluetooth...");
}

void loop() {
  // No se necesita hacer nada aquí
}
