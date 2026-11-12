import 'package:dumptrak_mobile_prototype/demo_store.dart';
import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_store_test.dart' show TestPersistence;

Future<void> reveal(WidgetTester tester, Finder finder,
    {double delta = 250}) async {
  await tester.scrollUntilVisible(finder, delta);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> tab(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(ValueKey('main-tab-$label')));
  await tester.pumpAndSettle();
}

String? metric(WidgetTester tester, String label) {
  final card = find.ancestor(
    of: find.text(label),
    matching: find.byType(MetricCard),
  );
  return tester.widget<MetricCard>(card).value;
}

void main() {
  testWidgets(
      'advance updates Home, Trips, Alerts and Reports from shared state',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    expect(metric(tester, 'COMPLETED TODAY'), '0');
    await tab(tester, 'More');
    await reveal(tester, find.byKey(const ValueKey('advance-demo')));
    await tester.tap(find.byKey(const ValueKey('advance-demo')));
    await tester.pumpAndSettle();
    expect(store.trips.first.status, 'Approaching');

    await tab(tester, 'Home');
    expect(metric(tester, 'ACTIVE TRIPS'), '2');
    expect(metric(tester, 'IN TRANSIT'), '1');
    expect(metric(tester, 'COMPLETED TODAY'), '0');
    expect(metric(tester, 'NEEDS ACTION'), '2');
    await tab(tester, 'Trips');
    expect(find.text('APPROACHING'), findsOneWidget);
    await tab(tester, 'Alerts');
    expect(find.text('Needs Action (2)'), findsOneWidget);

    while (store.canAdvance) {
      await store.advance(DateTime.now());
    }
    await tab(tester, 'Home');
    expect(metric(tester, 'ACTIVE TRIPS'), '0');
    expect(metric(tester, 'COMPLETED TODAY'), '2');
    await tab(tester, 'More');
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('report-completed-trips')));
    expect(find.text('Completed trips: 2'), findsOneWidget);
    expect(find.text('Active trips: 0'), findsOneWidget);
    expect(find.text('Open alerts: 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset confirmation cancels safely and saves restored samples',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await store.advance(DateTime.now());
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    await tab(tester, 'More');
    final reset = find.byKey(const ValueKey('reset-demo'));
    await reveal(tester, reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.trips.first.status, 'Approaching');
    await tester.tap(reset);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset Demo'));
    await tester.pumpAndSettle();
    expect(store.trips.first.status, 'In transit');
    final restored = await DemoStore.load(persistence);
    addTearDown(restored.dispose);
    expect(restored.trips.first.status, 'In transit');
    expect(tester.takeException(), isNull);
  });

  testWidgets('write error is visible and retry succeeds', (tester) async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    await tab(tester, 'More');
    final advance = find.byKey(const ValueKey('advance-demo'));
    await reveal(tester, advance);
    persistence.failWrite = true;
    await tester.tap(advance);
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo could not be saved:'), findsOneWidget);
    expect(store.trips.first.status, 'In transit');
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();
    persistence.failWrite = false;
    await tester.tap(advance);
    await tester.pumpAndSettle();
    expect(store.trips.first.status, 'Approaching');
  });

  testWidgets('startup reloads saved trips instead of reseeding',
      (tester) async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    await store.advance(DateTime.now());
    store.dispose();
    await tester.pumpWidget(DemoStartup(persistence: persistence));
    await tester.pumpAndSettle();
    await tab(tester, 'Trips');
    expect(find.text('APPROACHING'), findsOneWidget);
  });

  testWidgets('startup corrupt data requires confirmed restore',
      (tester) async {
    final persistence = TestPersistence()..snapshot = '{broken';
    await tester.pumpWidget(DemoStartup(persistence: persistence));
    await tester.pumpAndSettle();
    expect(find.text('Saved demo could not be loaded'), findsOneWidget);
    expect(persistence.snapshot, '{broken');
    await tester.tap(find.text('Restore sample data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(persistence.snapshot, '{broken');
    await tester.tap(find.text('Restore sample data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset Demo'));
    await tester.pumpAndSettle();
    expect(find.text('Operations overview'), findsOneWidget);
    expect(metric(tester, 'ACTIVE TRIPS'), '2');
  });
}
