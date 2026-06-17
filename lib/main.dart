import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const EkibimNeredeApp());
}

class EkibimNeredeApp extends StatelessWidget {
  const EkibimNeredeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ekibim Nerede',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
