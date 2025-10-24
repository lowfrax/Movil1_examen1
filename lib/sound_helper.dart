import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundHelper {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final AudioPlayer _musicPlayer = AudioPlayer();
  static bool _isMusicPlaying = false;
  static Duration? _musicPosition;

  // Helper to load asset bytes reliably regardless of asset path mapping
  static Future<Uint8List> _loadAssetBytes(String path) async {
    // Try several common asset path mappings to be resilient across pubspec layouts
    final candidates = [
      path,
      'assets/${path.replaceFirst(RegExp(r"^(lib/)?"), "")}',
      'lib/${path.replaceFirst(RegExp(r"^(assets/)?"), "")}',
    ];
    for (final p in candidates) {
      try {
        final data = await rootBundle.load(p);
        print('Loaded asset from: $p');
        return data.buffer.asUint8List();
      } catch (e) {
        // ignore and try next
        print('No asset at $p: $e');
      }
    }
    // If none found, throw to be handled by caller
    throw Exception('Could not find asset (tried: ${candidates.join(', ')})');
  }

  static Future<void> playSelectSound() async {
    try {
      print('Reproduciendo sonido select.mp3');
      final bytes = await _loadAssetBytes('lib/sounds/select.mp3');

      // Pausar música temporalmente si está reproduciéndose
      if (_isMusicPlaying) {
        _musicPosition = await _musicPlayer.getCurrentPosition();
        await _musicPlayer.pause();
      }

      await _audioPlayer.play(BytesSource(bytes));

      // Escuchar cuando termine el sonido para reanudar la música
      _audioPlayer.onPlayerComplete.listen((_) async {
        if (_isMusicPlaying && _musicPosition != null) {
          await _musicPlayer.seek(_musicPosition!);
          await _musicPlayer.resume();
        }
      });

      print('Sonido reproducido exitosamente');
    } catch (e) {
      print('Error reproduciendo sonido: $e');
    }
  }

  static Future<void> playBackgroundMusic() async {
    try {
      if (!_isMusicPlaying) {
        print('Iniciando música de fondo music.mp3');
        final bytes = await _loadAssetBytes('lib/sounds/music.mp3');
        await _musicPlayer.play(BytesSource(bytes));
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        _isMusicPlaying = true;
        print('Música de fondo iniciada');
      }
    } catch (e) {
      print('Error reproduciendo música de fondo: $e');
    }
  }

  static Future<void> stopBackgroundMusic() async {
    try {
      if (_isMusicPlaying) {
        print('Deteniendo música de fondo');
        _musicPosition = await _musicPlayer.getCurrentPosition();
        await _musicPlayer.stop();
        _isMusicPlaying = false;
        print('Música de fondo detenida');
      }
    } catch (e) {
      print('Error deteniendo música de fondo: $e');
    }
  }

  static bool get isMusicPlaying => _isMusicPlaying;

  static Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _musicPlayer.dispose();
  }
}
