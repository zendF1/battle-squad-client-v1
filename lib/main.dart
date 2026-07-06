import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: BattleSquadApp()));
}

class BattleSquadApp extends StatelessWidget {
  const BattleSquadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battle Squad',
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(child: Text('Battle Squad')),
      ),
    );
  }
}
