import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/supabase_data_service.dart';

class CameraPulseDetector extends StatefulWidget {
  final int casoId;
  final Function(int) onPulseSaved;

  const CameraPulseDetector({
    super.key,
    required this.casoId,
    required this.onPulseSaved,
  });

  @override
  State<CameraPulseDetector> createState() => _CameraPulseDetectorState();
}

class _CameraPulseDetectorState extends State<CameraPulseDetector> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isMeasuring = false;
  String _currentPulse = '--';
  int _pulseCount = 0;
  List<int> _pulseReadings = [];
  static const int READINGS_FOR_AVERAGE = 5;

  // Variables para detección de pulso
  final List<double> _redValues = [];
  final List<double> _greenValues = [];
  final List<double> _blueValues = [];
  final List<int> _timestamps = [];
  Timer? _measurementTimer;
  DateTime? _startTime;

  final SupabaseDataService _dataService = SupabaseDataService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _stopMeasurement();
    _measurementTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    // Solicitar permiso de cámara
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se necesita permiso de cámara para medir el pulso'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró ninguna cámara')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Buscar cámara trasera (normalmente la primera, pero verificamos)
      CameraDescription? camera;
      for (var cam in cameras) {
        if (cam.lensDirection == CameraLensDirection.back) {
          camera = cam;
          break;
        }
      }
      camera ??= cameras.first;
      
      _controller = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar cámara: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _startMeasurement() async {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isMeasuring = true;
      _currentPulse = '--';
      _pulseCount = 0;
      _pulseReadings.clear();
      _redValues.clear();
      _greenValues.clear();
      _blueValues.clear();
      _timestamps.clear();
      _startTime = DateTime.now();
    });

    // Activar flash para mejorar la detección
    try {
      await _controller!.setFlashMode(FlashMode.torch);
    } catch (e) {
      print('No se pudo activar el flash: $e');
    }
    
    // Iniciar análisis de frames
    _controller!.startImageStream(_processImage);
    
    // Timer para calcular BPM cada segundo
    _measurementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateBPM();
    });
  }

  void _stopMeasurement() {
    _measurementTimer?.cancel();
    _controller?.stopImageStream();
    
    // Desactivar flash
    try {
      _controller?.setFlashMode(FlashMode.off);
    } catch (e) {
      print('Error al desactivar flash: $e');
    }
    
    setState(() {
      _isMeasuring = false;
    });
  }

  void _processImage(CameraImage image) {
    if (!_isMeasuring) return;

    try {
      // Obtener el frame central para análisis
      final int centerX = image.width ~/ 2;
      final int centerY = image.height ~/ 2;
      final int sampleSize = 50; // Tamaño del área de muestreo

      double totalRed = 0;
      double totalGreen = 0;
      double totalBlue = 0;
      int pixelCount = 0;

      // Muestrear un área central del frame
      for (int y = centerY - sampleSize ~/ 2; y < centerY + sampleSize ~/ 2; y++) {
        if (y < 0 || y >= image.height) continue;
        for (int x = centerX - sampleSize ~/ 2; x < centerX + sampleSize ~/ 2; x++) {
          if (x < 0 || x >= image.width) continue;

          int index = y * image.width + x;
          if (image.format.group == ImageFormatGroup.yuv420) {
            // Para YUV420, usar el plano Y (luminancia)
            if (index < image.planes[0].bytes.length) {
              int yValue = image.planes[0].bytes[index];
              totalRed += yValue;
              totalGreen += yValue;
              totalBlue += yValue;
              pixelCount++;
            }
          } else if (image.format.group == ImageFormatGroup.bgra8888) {
            // Para BGRA8888
            if (index * 4 + 3 < image.planes[0].bytes.length) {
              int b = image.planes[0].bytes[index * 4];
              int g = image.planes[0].bytes[index * 4 + 1];
              int r = image.planes[0].bytes[index * 4 + 2];
              totalRed += r;
              totalGreen += g;
              totalBlue += b;
              pixelCount++;
            }
          }
        }
      }

      if (pixelCount > 0) {
        final avgRed = totalRed / pixelCount;
        final avgGreen = totalGreen / pixelCount;
        final avgBlue = totalBlue / pixelCount;

        final now = DateTime.now();
        final timestamp = now.difference(_startTime!).inMilliseconds;

        setState(() {
          _redValues.add(avgRed);
          _greenValues.add(avgGreen);
          _blueValues.add(avgBlue);
          _timestamps.add(timestamp);

          // Mantener solo los últimos 10 segundos de datos
          if (_timestamps.length > 0 && timestamp - _timestamps.first > 10000) {
            _redValues.removeAt(0);
            _greenValues.removeAt(0);
            _blueValues.removeAt(0);
            _timestamps.removeAt(0);
          }
        });
      }
    } catch (e) {
      print('Error procesando imagen: $e');
    }
  }

  void _calculateBPM() {
    if (_redValues.length < 60) {
      // Necesitamos al menos 60 muestras (aproximadamente 2 segundos)
      return;
    }

    try {
      // Usar el canal rojo para detectar cambios de pulso (PPG)
      // El canal rojo es más sensible a los cambios de volumen sanguíneo
      final List<double> signal = _redValues.toList();
      
      // Normalizar la señal
      final double mean = signal.reduce((a, b) => a + b) / signal.length;
      final List<double> normalized = signal.map((v) => v - mean).toList();
      
      // Aplicar filtro de media móvil para suavizar
      final List<double> smoothed = _movingAverage(normalized, 7);
      
      // Encontrar picos (latidos)
      final List<int> peaks = _findPeaks(smoothed);
      
      if (peaks.length >= 2) {
        // Calcular el tiempo promedio entre picos
        final List<int> intervals = [];
        for (int i = 1; i < peaks.length; i++) {
          final interval = _timestamps[peaks[i]] - _timestamps[peaks[i - 1]];
          // Filtrar intervalos razonables (300ms - 1500ms = 40-200 BPM)
          if (interval >= 300 && interval <= 1500) {
            intervals.add(interval);
          }
        }
        
        if (intervals.length >= 2) {
          // Calcular mediana para evitar outliers
          intervals.sort();
          final medianInterval = intervals[intervals.length ~/ 2];
          final bpm = (60000 / medianInterval).round();
          
          // Filtrar valores razonables (40-200 BPM)
          if (bpm >= 40 && bpm <= 200) {
            setState(() {
              _currentPulse = bpm.toString();
              _pulseReadings.add(bpm);
              _pulseCount++;
              
              // Si tenemos 5 lecturas, calcular la media y guardar
              if (_pulseReadings.length >= READINGS_FOR_AVERAGE) {
                int average = (_pulseReadings.reduce((a, b) => a + b) / READINGS_FOR_AVERAGE).round();
                _savePulseToDatabase(average);
                _pulseReadings.clear();
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error calculando BPM: $e');
    }
  }

  List<double> _movingAverage(List<double> data, int windowSize) {
    final List<double> result = [];
    for (int i = 0; i < data.length; i++) {
      int start = math.max(0, i - windowSize ~/ 2);
      int end = math.min(data.length, i + windowSize ~/ 2 + 1);
      double sum = 0;
      for (int j = start; j < end; j++) {
        sum += data[j];
      }
      result.add(sum / (end - start));
    }
    return result;
  }

  List<int> _findPeaks(List<double> data) {
    final List<int> peaks = [];
    if (data.length < 3) return peaks;

    // Calcular umbral dinámico
    final double mean = data.reduce((a, b) => a + b) / data.length;
    final double stdDev = _calculateStdDev(data, mean);
    final double threshold = mean + stdDev * 0.5;

    for (int i = 1; i < data.length - 1; i++) {
      if (data[i] > data[i - 1] && 
          data[i] > data[i + 1] && 
          data[i] > threshold) {
        // Verificar que no haya otro pico muy cercano
        if (peaks.isEmpty || i - peaks.last > 10) {
          peaks.add(i);
        }
      }
    }
    return peaks;
  }

  double _calculateStdDev(List<double> data, double mean) {
    double sumSquaredDiff = 0;
    for (double value in data) {
      sumSquaredDiff += math.pow(value - mean, 2);
    }
    return math.sqrt(sumSquaredDiff / data.length);
  }

  Future<void> _savePulseToDatabase(int pulseValue) async {
    try {
      await _dataService.insertarPulsoESP32(
        casoId: widget.casoId,
        pulso: pulseValue,
      );
      
      widget.onPulseSaved(pulseValue);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pulso guardado: $pulseValue BPM'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt, color: Colors.red),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Medir Pulso con Cámara',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    _stopMeasurement();
                    // Esperar un poco para que el flash se desactive
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_isInitialized)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_controller != null && _controller!.value.isInitialized) ...[
              // Vista previa de la cámara
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      CameraPreview(_controller!),
                      // Indicador central para colocar el dedo
                      Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isMeasuring ? Colors.red : Colors.white,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _isMeasuring ? 'Midiendo...' : 'Coloca tu dedo aquí',
                              style: TextStyle(
                                color: _isMeasuring ? Colors.red : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Display del pulso
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    const Text('Pulso Actual (BPM)', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      _currentPulse,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lecturas recibidas: $_pulseCount',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isMeasuring)
                    ElevatedButton.icon(
                      onPressed: _startMeasurement,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar Medición'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _stopMeasurement,
                      icon: const Icon(Icons.stop),
                      label: const Text('Detener Medición'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

