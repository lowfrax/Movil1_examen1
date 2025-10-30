import 'package:flutter/material.dart';
import 'package:medinova/sound_helper.dart';
import 'package:medinova/music_control_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medinova/p3_theme.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final supabase = Supabase.instance.client;

  Future<void> _signOut() async {
    await SoundHelper.playSelectSound();
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _signOut, icon: Icon(Icons.logout))],
      ),
      body: Stack(
        children: [
          Container(decoration: p3BackgroundGradient()),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services, size: 100, color: Colors.white),
                SizedBox(height: 32),
                Text(
                  'Bienvenido Doctor',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Has iniciado sesión como Doctor',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),
                Container(
                  padding: EdgeInsets.all(24),
                  margin: EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Funcionalidades disponibles:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        title: Text('Ver agenda de citas'),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.person_add,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text('Atender pacientes'),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.description,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        title: Text('Escribir recetas médicas'),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.analytics,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        title: Text('Diagnósticos médicos'),
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.history,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        title: Text('Historial de pacientes'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const MusicControlWidget(),
        ],
      ),
    );
  }
}
