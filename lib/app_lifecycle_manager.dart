import 'package:flutter/material.dart';
import 'package:medinova/sound_helper.dart';

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App volvió al primer plano - reanudar música si estaba reproduciéndose
        if (SoundHelper.isMusicPlaying) {
          SoundHelper.resumeBackgroundMusic();
        }
        break;
      case AppLifecycleState.paused:
        // App fue pausada - pausar música pero mantener posición
        if (SoundHelper.isMusicPlaying) {
          SoundHelper.pauseBackgroundMusic();
        }
        break;
      case AppLifecycleState.detached:
        // App fue cerrada completamente - detener música
        SoundHelper.stopBackgroundMusic();
        break;
      case AppLifecycleState.inactive:
        // App está inactiva (ej: llamada telefónica) - pausar música
        if (SoundHelper.isMusicPlaying) {
          SoundHelper.pauseBackgroundMusic();
        }
        break;
      case AppLifecycleState.hidden:
        // App está oculta - pausar música
        if (SoundHelper.isMusicPlaying) {
          SoundHelper.pauseBackgroundMusic();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
