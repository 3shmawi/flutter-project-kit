import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/update/app_version.dart';
import 'package:__PROJECT_NAME__/core/update/update_dialog.dart';
import 'package:__PROJECT_NAME__/core/update/update_info.dart';

import '../../helpers/pump_app.dart';

void main() {
  UpdateInfo info(UpdateType type) => UpdateInfo(
    type: type,
    current: const AppVersion(1, 0, 0),
    config: const VersionConfig(
      latest: AppVersion(1, 1, 0),
      minSupported: AppVersion(1, 0, 0),
      storeUrl: 'https://example.com',
      changelogEn: '- Faster search\n- Dark mode fixes\n',
      changelogAr: '• بحث أسرع',
    ),
  );

  Future<void> open(
    WidgetTester tester,
    UpdateInfo updateInfo, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => unawaited(showUpdateDialog(context, updateInfo)),
          child: const Text('open'),
        ),
      ),
      locale: locale,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('changelogPoints', () {
    test('one point per line, list markers removed, blanks skipped', () {
      expect(
        changelogPoints('- One\n* Two\n\n• Three\n1. Four\n2) Five\n  Six  '),
        ['One', 'Two', 'Three', 'Four', 'Five', 'Six'],
      );
      expect(changelogPoints(''), isEmpty);
      expect(changelogPoints('\n  \n'), isEmpty);
    });

    test('keeps hostile text as plain text', () {
      expect(changelogPoints('<script>alert(1)</script>'), [
        '<script>alert(1)</script>',
      ]);
    });
  });

  testWidgets('optional update: a sheet with versions, points and Later', (
    tester,
  ) async {
    await open(tester, info(UpdateType.optional));

    expect(find.text(l10nEn.updateOptionalTitle), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('1.1.0'), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10nEn.updateVersions('1.0.0', '1.1.0')),
      findsOneWidget,
    );
    expect(find.text(l10nEn.updateWhatsNew), findsOneWidget);
    expect(find.text('Faster search'), findsOneWidget);
    expect(find.text('Dark mode fixes'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.expectAccessible();

    await tester.tap(find.byKey(const Key('update_later')));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.updateOptionalTitle), findsNothing);
  });

  testWidgets('optional update shows the Arabic changelog in Arabic', (
    tester,
  ) async {
    await open(
      tester,
      info(UpdateType.optional),
      locale: const Locale('ar'),
    );

    expect(find.text('بحث أسرع'), findsOneWidget);
    expect(find.text('Faster search'), findsNothing);
  });

  testWidgets('no Arabic changelog → the English points', (tester) async {
    final english = UpdateInfo(
      type: UpdateType.optional,
      current: const AppVersion(1, 0, 0),
      config: const VersionConfig(
        latest: AppVersion(1, 1, 0),
        minSupported: AppVersion(1, 0, 0),
        storeUrl: 'https://example.com',
        changelogEn: 'Faster search',
      ),
    );
    await open(tester, english, locale: const Locale('ar'));

    expect(find.text('Faster search'), findsOneWidget);
  });

  testWidgets('force update: a full screen with no Later and no way back', (
    tester,
  ) async {
    await open(tester, info(UpdateType.force));

    expect(find.byType(ForcedUpdatePage), findsOneWidget);
    expect(find.text(l10nEn.updateForceTitle), findsOneWidget);
    expect(find.text(l10nEn.updateForceMessage), findsOneWidget);
    expect(find.byKey(const Key('update_later')), findsNothing);
    expect(find.byKey(const Key('update_now')), findsOneWidget);
    await tester.expectAccessible();

    // System back (Android button / iOS swipe) and a tap outside do nothing.
    await tester.binding.handlePopRoute();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(ForcedUpdatePage), findsOneWidget);
  });
}
