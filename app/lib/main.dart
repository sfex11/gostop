import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/lobby_page.dart';

void main() {
  runApp(const ProviderScope(child: GostopApp()));
}

class GostopApp extends StatelessWidget {
  const GostopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '고스톱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LobbyPage(),
    );
  }
}
