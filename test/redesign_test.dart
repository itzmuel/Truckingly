import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(ValueKey('main-tab-$label')));
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 200);
  await Scrollable.ensureVisible(tester.element(target.first), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 430.0]) {
    testWidgets('redesigned main screens fit width $width with enlarged text',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.pumpWidget(const DumptrakPrototypeApp());
      await reveal(tester, find.text('Fleet intelligence'));
      expect(tester.takeException(), isNull);

      await openTab(tester, 'Trips');
      expect(find.byTooltip('New trip'), findsOneWidget);
      await reveal(tester, find.text('Granite aggregate'));
      expect(find.text('ORIGIN'), findsWidgets);
      expect(find.text('DESTINATION'), findsWidgets);
      await reveal(tester, find.textContaining('Sample data only.'));
      expect(tester.takeException(), isNull);

      await openTab(tester, 'Map');
      expect(find.textContaining('SIMULATED — NOT LIVE GPS'), findsOneWidget);
      expect(find.text('LIVE TRACKING ACTIVE'), findsNothing);
      expect(tester.takeException(), isNull);

      await openTab(tester, 'Alerts');
      expect(find.text('Needs Action (2)'), findsOneWidget);
      await reveal(tester, find.byKey(const ValueKey('alert-card-alert-tracking')));
      await reveal(tester, find.text('UNDERSTANDING ALERTS'));
      expect(tester.takeException(), isNull);

      await openTab(tester, 'More');
      await reveal(tester, find.text('Samuel Onyenwe'));
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('archive shortcut updates the status control and results',
      (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());
    await openTab(tester, 'Trips');
    await tester.tap(find.text('View Archive'));
    await tester.pumpAndSettle();
    expect(find.text('No trips in this status'), findsOneWidget);
    final filter = find.byKey(const ValueKey('trip-status-filter'));
    expect(
      tester.widget<DropdownButtonFormField<String>>(filter).initialValue,
      'Completed',
    );
    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('All statuses').last);
    await tester.pumpAndSettle();
    expect(find.text('TR-2048'), findsOneWidget);
  });

  testWidgets('alert actions open explicitly simulated management',
      (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());
    await openTab(tester, 'Alerts');
    for (final label in ['Manage demo alert', 'Assign demo supervisor']) {
      final action = find.descendant(
          of: find.byKey(ValueKey(label == 'Manage demo alert'
              ? 'alert-card-alert-tracking'
              : 'alert-card-alert-delivery')),
          matching: find.text(label));
      await reveal(tester, action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('Demo alert'), findsOneWidget);
      expect(find.textContaining('No real operational action'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
