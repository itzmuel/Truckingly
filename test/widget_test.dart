import 'package:flutter/material.dart';
import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('system back returns main tabs to Home and allows exit at Home',
      (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());

    for (final tab in ['Trips', 'Map', 'Alerts', 'More']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
          isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Operations overview'), findsOneWidget);
      expect(tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
          isTrue);
    }
  });

  testWidgets('system back closes trip wizard before leaving Trips',
      (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());
    await tester.tap(find.text('Trips').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('New trip'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('New demo trip'), findsNothing);
    expect(find.byTooltip('New trip'), findsOneWidget);
    expect(find.text('Operations overview'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Operations overview'), findsOneWidget);
  });

  for (final page in ['Compliance & documents', 'Reports', 'Intelligence']) {
    testWidgets('system back returns $page to More', (tester) async {
      await tester.pumpWidget(const DumptrakPrototypeApp());
      await tester.tap(find.text('More').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(page), 200);
      await tester.tap(find.text(page));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Tools and account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('alert sections fit a narrow phone with larger text',
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
    await tester.tap(find.text('Alerts').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final section in [
      'History',
      'Earlier detections',
      'Informational records'
    ]) {
      final chip = find.byKey(ValueKey('alert-section-$section'));
      await Scrollable.ensureVisible(tester.element(chip), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('alert kind filter narrows sample situations and resets',
      (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());
    await tester.tap(find.text('Alerts').last);
    await tester.pumpAndSettle();

    final filter = find.byKey(const ValueKey('situation-kind-filter'));
    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tracking').last);
    await tester.pumpAndSettle();
    expect(find.text('Vehicle reporting gap'), findsOneWidget);
    expect(find.text('Delivery confirmation needed'), findsNothing);

    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compliance').last);
    await tester.pumpAndSettle();
    expect(find.text('No situations match this kind'), findsOneWidget);

    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('All kinds').last);
    await tester.pumpAndSettle();
    expect(find.text('Vehicle reporting gap'), findsOneWidget);
    expect(find.text('Delivery confirmation needed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('alert sections show history filters and expandable guidance',
      (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());
    await tester.tap(find.text('Alerts').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('alert-section-History')));
    await tester.pumpAndSettle();

    final filter = find.byKey(const ValueKey('history-outcome-filter'));
    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Closed by a person').last);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text('More about how it left the queue')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('More about how it left the queue'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Superseded situations concerned'), findsOneWidget);
    expect(find.text('Nothing recorded for "Closed by a person".'),
        findsOneWidget);

    for (final section in ['Earlier detections', 'Informational records']) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('alert-section-$section')),
        -250,
      );
      await Scrollable.ensureVisible(
        tester.element(find.byKey(ValueKey('alert-section-$section'))),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('alert-section-$section')));
      await tester.pumpAndSettle();
      expect(find.text('Nothing recorded here.'), findsOneWidget);
      expect(find.text('0 records'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('history-outcome-filter')), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the mobile operations overview', (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());

    expect(find.text('Operations overview'), findsOneWidget);
    expect(find.text('DEMO'), findsOneWidget);
    expect(find.text('ACTIVE TRIPS'), findsOneWidget);
  });

  testWidgets('demo wizard requires selections and can be cancelled',
      (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());

    await tester.tap(find.text('Trips').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('New trip'));
    await tester.pumpAndSettle();

    expect(find.text('New demo trip'), findsOneWidget);
    expect(find.text('Project (required)'), findsOneWidget);
    expect(find.text('Origin (required)'), findsOneWidget);
    expect(find.text('Destination (required)'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a sample project.'), findsOneWidget);
    expect(find.text('Choose a sample origin.'), findsOneWidget);
    expect(find.text('Choose a sample destination.'), findsOneWidget);
    await tester.tap(find.byTooltip('Close wizard'));
    await tester.pumpAndSettle();

    expect(find.text('2 trips'), findsOneWidget);
    expect(find.textContaining('DEMO-'), findsNothing);
  });

  testWidgets('filters trips by status and shows a useful empty state',
      (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());

    await tester.tap(find.text('Trips').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trip-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completed').last);
    await tester.pumpAndSettle();

    expect(find.text('No trips in this status'), findsOneWidget);
    expect(find.textContaining('TR-2048'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('trip-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All statuses').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('TR-2048'), findsOneWidget);
  });
}
