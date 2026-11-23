import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/privacy/consent.dart';
import 'package:__PROJECT_NAME__/core/privacy/consent_sheet.dart';
import 'package:__PROJECT_NAME__/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => Consent.analytics.value = ConsentChoice.unknown);

  group(Consent, () {
    test('starts unknown (nothing collected) on a new install', () async {
      await Consent.load();
      expect(Consent.analytics.value, ConsentChoice.unknown);
      expect(Consent.analyticsAllowed, isFalse);
    });

    test('remembers the answer', () async {
      await Consent.load();
      await Consent.set(ConsentChoice.granted);
      Consent.analytics.value = ConsentChoice.unknown;

      await Consent.load();
      expect(Consent.analytics.value, ConsentChoice.granted);
      expect(Consent.analyticsAllowed, isTrue);
    });

    test('ignores a corrupted saved value', () async {
      SharedPreferences.setMockInitialValues({'consent.analytics': 'yes!!'});
      await Consent.load();
      expect(Consent.analytics.value, ConsentChoice.unknown);
    });
  });

  group(ConsentSheet, () {
    testWidgets('both answers are offered the same way', (tester) async {
      final answers = <ConsentChoice>[];
      await tester.pumpApp(
        Scaffold(body: ConsentSheet(onChoice: answers.add)),
      );
      final allow = tester.getSize(find.byKey(const Key('consent_allow')));
      final deny = tester.getSize(find.byKey(const Key('consent_deny')));
      expect(allow, deny);

      await tester.tap(find.byKey(const Key('consent_deny')));
      await tester.tap(find.byKey(const Key('consent_allow')));
      expect(answers, [ConsentChoice.denied, ConsentChoice.granted]);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      await tester.pumpApp(Scaffold(body: ConsentSheet(onChoice: (_) {})));
      await tester.expectAccessible();
    });

    testWidgets('reads right to left in Arabic', (tester) async {
      await tester.pumpApp(
        Scaffold(body: ConsentSheet(onChoice: (_) {})),
        locale: const Locale('ar'),
      );
      expect(
        Directionality.of(tester.element(find.byType(ConsentSheet))),
        TextDirection.rtl,
      );
    });
  });

  testWidgets('SettingsSwitchRow flips from anywhere on the row', (
    tester,
  ) async {
    var value = false;
    await tester.pumpApp(
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SettingsSwitchRow(
            label: 'Share usage data',
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Share usage data'));
    await tester.pump();
    expect(value, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(value, isFalse);
  });
}
