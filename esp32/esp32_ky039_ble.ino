/*
 * ESP32 + KY-039 con lógica filtrada avanzada (tomada del código Arduino)
 * + Integración BLE completa para enviar BPM a una app móvil
 * + Registro serial por USB
 */

 #include <BLEDevice.h>
 #include <BLEServer.h>
 #include <BLEUtils.h>
 #include <BLE2902.h>
 
 // -------------------------
 // CONFIGURACIÓN DE PINES
 // -------------------------
 #define SENSOR_PIN 34  // GPIO34 ADC1_CH6
 
 // -------------------------
 // CONFIG BLE
 // -------------------------
 #define SERVICE_UUID            "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
 #define CHARACTERISTIC_UUID_TX  "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
 #define CHARACTERISTIC_UUID_RX  "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
 
 // Variables BLE
 BLEServer* pServer = NULL;
 BLECharacteristic* pTxCharacteristic = NULL;
 bool deviceConnected = false;
 bool oldDeviceConnected = false;
 
 // -------------------------
 // VARIABLES TOMADAS DEL CÓDIGO 1 (FILTRADO REAL)
 // -------------------------
 float factor = 0.75;           // Filtro pasa bajos
 float maximo = 0.0;           
 int minimoEntreLatidos = 300;  
 float valorAnterior = 500;      
 int latidos = 0;               
 
 unsigned long tiempoLPM = 0;
 unsigned long entreLatidos = 0;
 
 // Intervalo BLE
 const unsigned long BPM_INTERVALO_BLE = 10000; // 10 segundos
 unsigned long tiempoBLE = 0;
 
 // ---------------------------------------
 // CALLBACKS BLE
 // ---------------------------------------
 class MyServerCallbacks: public BLEServerCallbacks {
   void onConnect(BLEServer* pServer) {
     deviceConnected = true;
     Serial.println("Dispositivo BLE conectado");
   }
 
   void onDisconnect(BLEServer* pServer) {
     deviceConnected = false;
     Serial.println("Dispositivo BLE desconectado");
   }
 };
 
 class MyCallbacks: public BLECharacteristicCallbacks {
   void onWrite(BLECharacteristic *pCharacteristic) {
     String rxValue = pCharacteristic->getValue();
 
     if (rxValue.length() > 0) {
       Serial.print("Comando recibido: ");
       Serial.println(rxValue);
 
       if (rxValue == "RESET") {
         latidos = 0;
         tiempoLPM = millis();
         Serial.println("Contador BPM reiniciado.");
       }
     }
   }
 };
 
 // ---------------------------------------
 // SETUP
 // ---------------------------------------
 void setup() {
   Serial.begin(115200);
   delay(500);
 
   pinMode(SENSOR_PIN, INPUT);
 
   Serial.println("Iniciando sensor KY-039 con filtrado avanzado...");
 
   // Inicializar tiempos
   tiempoLPM = millis();
   entreLatidos = millis();
   tiempoBLE = millis();
 
   // ---- BLE ----
   BLEDevice::init("ESP32_Medinova");
   pServer = BLEDevice::createServer();
   pServer->setCallbacks(new MyServerCallbacks());
 
   BLEService *pService = pServer->createService(SERVICE_UUID);
 
   pTxCharacteristic = pService->createCharacteristic(
     CHARACTERISTIC_UUID_TX,
     BLECharacteristic::PROPERTY_NOTIFY
   );
   pTxCharacteristic->addDescriptor(new BLE2902());
 
   BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(
     CHARACTERISTIC_UUID_RX,
     BLECharacteristic::PROPERTY_WRITE
   );
   pRxCharacteristic->setCallbacks(new MyCallbacks());
 
   pService->start();
 
   BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
   pAdvertising->addServiceUUID(SERVICE_UUID);
   pAdvertising->setScanResponse(false);
   pAdvertising->setMinPreferred(0x0);
 
   BLEDevice::startAdvertising();
   Serial.println("BLE listo. Esperando conexión...");
 }
 
 // ---------------------------------------
 // LOOP PRINCIPAL (CON FILTRADO DEL CÓDIGO 1)
 // ---------------------------------------
 void loop() {
   unsigned long currentTime = millis();
 
   // --- Leer sensor analógico ---
   int valorLeido = analogRead(SENSOR_PIN);
 
   // Filtro pasa bajos
   float valorFiltrado = factor * valorAnterior + (1 - factor) * valorLeido;
   float cambio = valorFiltrado - valorAnterior;
   valorAnterior = valorFiltrado;
 
   // Detección de latido
   if ((cambio >= maximo) && (millis() > entreLatidos + minimoEntreLatidos)) {
     maximo = cambio;
     entreLatidos = millis();
     latidos++;
     Serial.println("Latido detectado");
   }
 
   maximo *= 0.97; // Decaimiento natural
 
   // -----------------------------
   // CÁLCULO DE BPM CADA 15 SEG
   // -----------------------------
   if (millis() >= tiempoLPM + 15000) {
     int bpm = latidos * 4; // 15s → x4 = BPM
 
     Serial.print("BPM actual: ");
     Serial.println(bpm);
 
     // -----------------------
     // ENVÍO BLE CADA 15s
     // -----------------------
     if (deviceConnected && pTxCharacteristic != NULL) {
       pTxCharacteristic->setValue(String(bpm).c_str());
       pTxCharacteristic->notify();
       Serial.println("BPM enviado por BLE");
     }
 
     latidos = 0;
     tiempoLPM = millis();
   }
 
   // Manejo conexión/desconexión BLE
   if (!deviceConnected && oldDeviceConnected) {
     delay(500);
     pServer->startAdvertising();
     oldDeviceConnected = deviceConnected;
     Serial.println("Reiniciando publicidad BLE...");
   }
 
   if (deviceConnected && !oldDeviceConnected) {
     oldDeviceConnected = deviceConnected;
   }
 
   delay(50);
 }