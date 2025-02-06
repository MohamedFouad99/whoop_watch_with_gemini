import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'gemini_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GeminiService geminiService = GeminiService();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
    );
  }
}
