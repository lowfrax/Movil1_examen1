# ESP32 con Sensor KY-039 (Sensor de Pulso Cardíaco)

Este código permite leer datos del sensor KY-039 y enviarlos por Bluetooth Low Energy (BLE) al dispositivo móvil.

**Archivo principal:** `esp32_ky039_ble.ino`

## Conexiones del Sensor KY-039 al ESP32

### Pin del Sensor KY-039 → Pin del ESP32

- **VCC (+)** → **3.3V** del ESP32
- **GND (-)** → **GND** del ESP32  
- **S (Señal analógica)** → **GPIO34** (ADC1_CH6) del ESP32

### Nota sobre el Pin GPIO34

El pin **GPIO34** es uno de los pines recomendados para lectura analógica en el ESP32 porque:
- Es un pin de solo entrada (no tiene pull-up/pull-down internos)
- Pertenece al ADC1 (12 bits, 0-4095)
- No interfiere con otras funciones del ESP32

**Alternativas:** También puedes usar GPIO35, GPIO36 o GPIO39 si GPIO34 no está disponible.

## Configuración

1. Sube el código `esp32_ky039_ble.ino` al ESP32 usando el IDE de Arduino
2. Asegúrate de tener instaladas las siguientes librerías:
   - `BLEDevice.h` (incluida en el ESP32 por defecto)
   - `BLEServer.h`
   - `BLEUtils.h`
   - `BLE2902.h`
3. El nombre del dispositivo BLE será: **ESP32_Medinova**
4. UUIDs del servicio:
   - **Servicio:** `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
   - **TX (Notify):** `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` - Para enviar datos de pulso
   - **RX (Write):** `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` - Para recibir comandos

## Funcionamiento

- El ESP32 lee el sensor KY-039 a una frecuencia de 100 Hz
- Detecta los picos (latidos) del pulso cardíaco
- Calcula el BPM (latidos por minuto) cada 10 segundos
- Envía el valor de BPM por BLE usando notificaciones (Notify) como un número entero
- El dispositivo móvil recibe estos valores y calcula la media cada 5 lecturas
- Los datos se guardan automáticamente en la tabla `esp32` de Supabase

## Formato de Datos

El ESP32 envía los datos como texto plano, un número por línea:
```
75
76
74
75
```

Cada número representa el BPM (latidos por minuto) calculado.

## Solución de Problemas

- Si no aparece el dispositivo Bluetooth, verifica que el ESP32 esté encendido y el código esté cargado correctamente
- Si las lecturas son erráticas, verifica las conexiones del sensor
- Asegúrate de que el sensor esté correctamente posicionado (generalmente en el dedo)
- El sensor KY-039 es sensible a la luz, así que evita luz directa

