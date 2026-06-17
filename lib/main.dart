import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

import 'services/localization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalizationService.init();
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
