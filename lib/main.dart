import 'package:flutter/material.dart';
import 'package:mqtt_broker_test/mqtt_test_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: MqttTestScreen()));
  }
}
