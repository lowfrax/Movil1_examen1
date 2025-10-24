import 'package:flutter/material.dart';
import 'package:medinova/sound_helper.dart';

class MusicControlWidget extends StatefulWidget {
  const MusicControlWidget({super.key});

  @override
  State<MusicControlWidget> createState() => _MusicControlWidgetState();
}

class _MusicControlWidgetState extends State<MusicControlWidget> {
  bool _isMusicPlaying = false;

  @override
  void initState() {
    super.initState();
    _isMusicPlaying = SoundHelper.isMusicPlaying;
  }

  Future<void> _toggleMusic() async {
    setState(() {
      _isMusicPlaying = !_isMusicPlaying;
    });

    if (_isMusicPlaying) {
      await SoundHelper.playBackgroundMusic();
    } else {
      await SoundHelper.stopBackgroundMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: _toggleMusic,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                _isMusicPlaying ? Icons.music_note : Icons.music_off,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
