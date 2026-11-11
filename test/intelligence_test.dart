import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openIntelligence(WidgetTester tester) async {
  await tester.pumpWidget(const DumptrakPrototypeApp());
  await tester.tap(find.text('More').last);
  await tester.pumpAndSettle();
  await reveal(tester, find.text('Intelligence'));
  await tester.tap(find.text('Intelligence'));
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 250);
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('intelligence period updates coverage and survives reopening',
      (tester) async {
    await openIntelligence(tester);
    expect(find.text('Intelligence workspace'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('intelligence-period')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 7 days').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Last 7 days · Coverage'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Intelligence'));
    await tester.pumpAndSettle();
    expect(find.text('Last 7 days'), findsOneWidget);
  });

  testWidgets('unavailable services and alert navigation fit small phones',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await openIntelligence(tester);
    await reveal(tester, find.text('Not evaluated'));
    expect(find.text('Not evaluated'), findsOneWidget);
    for (final service in ['evaluation', 'analytic findings']) {
      final retry = find.byKey(ValueKey('intelligence-retry-$service'));
      await reveal(tester, retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.textContaining('Cannot retry $service:'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
    final alerts = find.text('View situations needing action');
    await reveal(tester, alerts);
    await tester.tap(alerts);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('situation-kind-filter')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
