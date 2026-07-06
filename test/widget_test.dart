import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:battle_squad_v1/main.dart';

void main() {
  testWidgets('App renders splash screen with loading indicator', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BattleSquadApp()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
