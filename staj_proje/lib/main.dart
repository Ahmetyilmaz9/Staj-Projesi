import 'package:flutter/material.dart';
import 'screens/login_ekrani.dart';

void main() {
  runApp(const StokApp());
}

class StokApp extends StatelessWidget {
  const StokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stok Kontrol',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1C1F26),
          primary: const Color(0xFF1C1F26),
        ),
        fontFamily: 'Roboto',
      ),
      home: const LoginEkrani(),
    );
  }
}
