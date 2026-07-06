import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomScreen extends ConsumerWidget {
  final String roomId;

  const RoomScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Room $roomId')),
      body: const Center(
        child: Text('Room - Coming Soon'),
      ),
    );
  }
}
