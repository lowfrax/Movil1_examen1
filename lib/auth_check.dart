import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medinova/home_screen.dart';
import 'package:medinova/login_screen.dart';
import 'package:medinova/usuario_app_screen.dart';
import 'package:medinova/usuario_clinica_screen.dart';
import 'package:medinova/doctor_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final session = supabase.auth.currentSession;
    if (mounted) {
      if (session != null) {
        try {
          // Buscar el rol del usuario en la tabla perfil
          print('Buscando perfil para email: ${session.user.email}');
          final perfilResponse = await supabase
              .from('perfil')
              .select('id_rol')
              .eq('email', session.user.email!)
              .single();

          print('Respuesta del perfil: $perfilResponse');
          int roleId = perfilResponse['id_rol'];
          print('Role ID encontrado: $roleId');

          // Redireccionar según el rol
          Widget targetScreen;
          switch (roleId) {
            case 1:
              targetScreen = UsuarioAppScreen();
              break;
            case 2:
              targetScreen = UsuarioClinicaScreen();
              break;
            case 3:
              targetScreen = DoctorScreen();
              break;
            default:
              targetScreen = HomeScreen();
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        } catch (e) {
          print('Error obteniendo perfil en auth_check: $e');
          // Si hay error al obtener el rol, redirigir al login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
