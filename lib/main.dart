import 'package:flutter/material.dart';
import 'package:medinova/splash_screen.dart';
import 'package:medinova/login_screen.dart';
import 'package:medinova/signup_screen.dart';
import 'package:medinova/usuario_app_screen.dart';
import 'package:medinova/usuario_clinica_screen.dart';
import 'package:medinova/doctor_screen.dart';
import 'package:medinova/custom_transitions.dart';
import 'package:medinova/app_lifecycle_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fkgpdhqhsjlsjuaoyuhe.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrZ3BkaHFoc2psc2p1YW95dWhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwODkxNjQsImV4cCI6MjA3NjY2NTE2NH0.I33WxY1dadN6iRJZJv0kgdTB2daFoLoUSdjQreS4gxk',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medinova',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageRouteBuilder(),
            TargetPlatform.iOS: CustomPageRouteBuilder(),
            TargetPlatform.windows: CustomPageRouteBuilder(),
            TargetPlatform.macOS: CustomPageRouteBuilder(),
            TargetPlatform.linux: CustomPageRouteBuilder(),
          },
        ),
      ),
      home: AppLifecycleManager(child: SplashScreen()),
      routes: {
        '/login': (context) => AppLifecycleManager(child: LoginScreen()),
        '/signup': (context) => AppLifecycleManager(child: SignupScreen()),
        '/usuario_app': (context) =>
            AppLifecycleManager(child: UsuarioAppScreen()),
        '/usuario_clinica': (context) =>
            AppLifecycleManager(child: UsuarioClinicaScreen()),
        '/doctor': (context) => AppLifecycleManager(child: DoctorScreen()),
      },
    );
  }
}
