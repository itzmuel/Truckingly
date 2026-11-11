import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> reveal(WidgetTester tester, Finder finder,
    {double delta = 250}) async {
  await tester.scrollUntilVisible(finder, delta);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  for (final service in ['Settlement', 'FleetOps']) {
    testWidgets('$service layout and identity explanation fit a small phone',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.pumpWidget(const DumptrakPrototypeApp());
      await tester.tap(find.text('More').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.text(service));
      await tester.tap(find.text(service));
      await tester.pumpAndSettle();
      expect(find.text('ADAPTIQ $service'), findsOneWidget);

      if (service == 'Settlement') {
        await reveal(tester, find.textContaining('NO FUNDS WILL MOVE'));
        expect(find.textContaining('NOT LEGALLY BINDING'), findsOneWidget);
        await reveal(
            tester, find.text('Held until a supervisor confirms the tonnes'));
        expect(find.text('Held until a supervisor confirms the tonnes'),
            findsOneWidget);
      } else {
        await reveal(tester, find.text('Movement data unavailable'));
        expect(find.text('Movement data unavailable'), findsOneWidget);
        expect(find.text('Reporting window · Last 24 hours'), findsOneWidget);
      }

      final link = find.byKey(ValueKey('link-geutech-$service'));
      await reveal(tester, link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.text('GEUTech linking is not connected'), findsOneWidget);
      expect(find.textContaining('No account was linked'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('GEUTech linking is not connected'), findsNothing);
      expect(link, findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Tools and account'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Operations overview'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
