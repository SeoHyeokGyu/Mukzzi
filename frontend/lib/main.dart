import 'package:flutter/material.dart';

void main() {
  runApp(const MukzziApp());
}

class MukzziApp extends StatelessWidget {
  const MukzziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mukzzi',
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mukzzi Dashboard')),
      body: const Center(
        child: Text('Hello, Mukzzi!'),
      ),
    );
  }
}
