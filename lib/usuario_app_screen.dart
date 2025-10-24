import 'package:flutter/material.dart';
import 'package:medinova/sound_helper.dart';
import 'package:medinova/music_control_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioAppScreen extends StatefulWidget {
  const UsuarioAppScreen({super.key});

  @override
  State<UsuarioAppScreen> createState() => _UsuarioAppScreenState();
}

class _UsuarioAppScreenState extends State<UsuarioAppScreen> {
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
        title: Text('Usuario App'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _signOut, icon: Icon(Icons.logout))],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 100, color: Colors.white),
              SizedBox(height: 32),
              Text(
                'Bienvenido Usuario App',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Has iniciado sesión como Usuario de la Aplicación',
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
                        Icons.medical_services,
                        color: Colors.green,
                      ),
                      title: Text('Consultar citas médicas'),
                    ),
                    ListTile(
                      leading: Icon(Icons.person, color: Colors.blue),
                      title: Text('Ver perfil personal'),
                    ),
                    ListTile(
                      leading: Icon(Icons.history, color: Colors.orange),
                      title: Text('Historial médico'),
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