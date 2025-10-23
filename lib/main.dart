import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medinova/auth_check.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future <void> main()async{

WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:'https://fkgpdhqhsjlsjuaoyuhe.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrZ3BkaHFoc2psc2p1YW95dWhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwODkxNjQsImV4cCI6MjA3NjY2NTE2NH0.I33WxY1dadN6iRJZJv0kgdTB2daFoLoUSdjQreS4gxk'
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auth',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF6366F1),
        brightness: Brightness.light,

        ),
        useMaterial3: true,

      ),

      home: AuthCheck(),

    );
  }
}