import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/purchases/premium_gate.dart';
import 'package:__PROJECT_NAME__/core/purchases/purchases.dart';

import '../../helpers/pump_app.dart';

void main() {
  tearDown(() => Premium.active.value = false);

  testWidgets('shows the locked card until premium is active', (tester) async {
    await tester.pumpApp(
      const Scaffold(body: PremiumGate(child: Text('secret export'))),
    );

    expect(find.text('secret export'), findsNothing);
    expect(find.byType(PremiumLockedCard), findsOneWidget);

    Premium.active.value = true;
    await tester.pump();

    expect(find.text('secret export'), findsOneWidget);
    expect(find.byType(PremiumLockedCard), findsNothing);
  });

  testWidgets('uses a custom locked widget', (tester) async {
    await tester.pumpApp(
      const Scaffold(
        body: PremiumGate(locked: Text('locked'), child: Text('open')),
      ),
    );
    expect(find.text('locked'), findsOneWidget);
  });
}
