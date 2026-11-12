import 'package:dumptrak_mobile_prototype/demo_analytics.dart';
import 'package:dumptrak_mobile_prototype/demo_store.dart';
import 'package:dumptrak_mobile_prototype/demo_trip_catalog.dart';
import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:dumptrak_mobile_prototype/reports_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_store_test.dart' show TestPersistence;

DemoAnalytics report(DemoStore store, {String? vehicle, DateTime? now}) =>
    DemoAnalytics(
      trips: store.trips,
      alerts: store.alerts,
      now: now ?? DateTime.utc(2026, 11, 12, 12),
      vehicle: vehicle,
    );

Trip completed(String code, DateTime at) => Trip(
      code: code,
      vehicle: 'DT-07',
      route: 'Ikeja Quarry → Lekki Site',
      material: 'Sand',
      status: 'Completed',
      progress: 1,
      eta: 'Simulated',
      completedAt: at,
    );

Future<void> reveal(WidgetTester tester, Finder finder,
    {double delta = 250}) async {
  await tester.scrollUntilVisible(finder, delta);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> vehicle(WidgetTester tester, String current, String next) async {
  final finder = find.byKey(ValueKey('analytics-vehicle-$current'));
  await reveal(tester, finder, delta: -250);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.tap(find.text(next).last);
  await tester.pumpAndSettle();
}

void main() {
  test('seed reports match shared counts and include unused catalog vehicles',
      () {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    final data = report(store);
    expect(data.active, 2);
    expect(data.completed, 0);
    expect(data.statuses['In transit'], 1);
    expect(data.statuses['At origin'], 1);
    expect(data.statuses.values.reduce((a, b) => a + b), 2);
    expect(data.workload['DT-07'], (active: 1, completed: 0));
    expect(data.workload['DT-15'], (active: 0, completed: 0));
    expect(data.openAlerts, 2);
    expect(data.acknowledged, 0);
    expect(data.resolved, 0);
    expect(data.openAlertKinds, {'Tracking': 1, 'Delivered quantity': 1});
    expect(data.dailyCompletions.length, 7);
    expect(data.dailyCompletions.values.every((count) => count == 0), isTrue);
  });

  test('creation, editing, resolution, completion, reload and reset recompute',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final now = DateTime.utc(2026, 11, 12, 12);
    await store.createTrip(const DemoTripDraft(
      project: 'Lekki development',
      origin: 'Ikeja Quarry',
      destination: 'Lekki Site',
      driver: 'Ayo Bello',
      vehicle: 'DT-15',
      material: 'Sand',
    ));
    expect(report(store).statuses['Planned'], 1);
    expect(report(store, vehicle: 'DT-15').active, 1);
    await store.editTrip(
        'TR-2047',
        const DemoTripDraft(
          project: 'Apapa logistics',
          origin: 'Ogun Yard',
          destination: 'Apapa Terminal',
          driver: 'Chidi Okafor',
          vehicle: 'DT-18',
          material: 'Laterite',
        ));
    expect(report(store, vehicle: 'DT-12').trips, isEmpty);
    expect(report(store, vehicle: 'DT-12').openAlerts, 0);
    expect(report(store, vehicle: 'DT-18').openAlerts, 1);
    await store.acknowledgeAlert('alert-tracking');
    expect(report(store).acknowledged, 1);
    await store.resolveAlert('alert-tracking', 'Demo review', now);
    expect(report(store).acknowledged, 0);
    expect(report(store).openAlerts, 1);
    expect(report(store).resolved, 1);
    while (store.canAdvance) {
      await store.advance(now);
    }
    final data = report(store);
    expect(data.active, 0);
    expect(data.completed, 3);
    expect(data.dailyCompletions[lagosDay(now)], 3);
    expect(data.openAlerts, 1);
    final loaded = await DemoStore.load(persistence);
    addTearDown(loaded.dispose);
    expect(report(loaded).statuses, data.statuses);
    expect(report(loaded).dailyCompletions, data.dailyCompletions);
    expect(report(loaded).resolved, 1);
    await store.reset();
    expect(report(store).completed, 0);
    expect(report(store).openAlerts, 2);
    expect(report(store).resolved, 0);
  });

  test('seven inclusive Lagos days exclude older and future completions', () {
    final data = DemoAnalytics(
      now: DateTime.utc(2026, 11, 12, 23, 30),
      trips: [
        completed('start', DateTime.utc(2026, 11, 6, 23)),
        completed('end', DateTime.utc(2026, 11, 13, 22, 59)),
        completed('older', DateTime.utc(2026, 11, 6, 22, 59)),
        completed('future', DateTime.utc(2026, 11, 13, 23)),
      ],
      alerts: [],
    );
    expect(data.today, DateTime.utc(2026, 11, 13));
    expect(data.dailyCompletions.keys.first, DateTime.utc(2026, 11, 7));
    expect(data.dailyCompletions.keys.last, DateTime.utc(2026, 11, 13));
    expect(data.dailyCompletions[DateTime.utc(2026, 11, 7)], 1);
    expect(data.dailyCompletions[DateTime.utc(2026, 11, 13)], 1);
    expect(data.dailyCompletions.values.reduce((a, b) => a + b), 2);
    expect(data.completed, 4);
  });

  test('empty data and non-journey statuses have honest zero counts', () {
    final empty = DemoAnalytics(trips: [], alerts: [], now: DateTime.now());
    expect(empty.active, 0);
    expect(empty.openAlertKinds, isEmpty);
    expect(empty.statuses.values.every((count) => count == 0), isTrue);
    final data = DemoAnalytics(
      trips: [
        for (final status in ['Cancelled', 'Exception'])
          Trip(
            code: status,
            vehicle: 'Legacy vehicle',
            route: 'Sample route',
            material: 'Sand',
            status: status,
            progress: 0,
            eta: 'Unknown',
          ),
      ],
      alerts: [],
      now: DateTime.now(),
    );
    expect(data.statuses['Cancelled'], 1);
    expect(data.statuses['Exception'], 1);
    expect(data.active, 1);
    expect(data.vehicles, contains('Legacy vehicle'));
    expect(data.workload['Legacy vehicle'], (active: 1, completed: 0));
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('analytics fits width $width and filters unused vehicles',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final store = DemoStore.memory();
      addTearDown(store.dispose);
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: ReportsPage(
            onBack: () {},
            trips: store.trips,
            alerts: store.alerts,
          ),
        ),
      ));
      await reveal(
          tester, find.byKey(const ValueKey('analytics-status-In transit')));
      expect(find.text('In transit: 1'), findsOneWidget);
      final semantics = tester.ensureSemantics();
      await tester.pump();
      expect(find.bySemanticsLabel('In transit: 1 records'), findsOneWidget);
      semantics.dispose();
      await reveal(tester, find.text('Simulated completions · Last 7 days'));
      await reveal(
          tester, find.byKey(const ValueKey('analytics-workload-DT-18')));
      await reveal(tester, find.byKey(const ValueKey('analytics-alerts')));
      expect(find.text('2 open · 0 acknowledged (still open) · 0 resolved'),
          findsOneWidget);
      await vehicle(tester, 'all', 'DT-15');
      expect(
          find.text('0 saved trips · 0 active · 0 completed'), findsOneWidget);
      await reveal(tester, find.text('Analytics provenance'));
      expect(tester.takeException(), isNull);
      await vehicle(tester, 'DT-15', 'All vehicles');
      expect(
          find.text('2 saved trips · 2 active · 0 completed'), findsOneWidget);
      await vehicle(tester, 'all', 'DT-07');
      expect(
          find.text('1 saved trip · 1 active · 0 completed'), findsOneWidget);
      await reveal(tester, find.byKey(const ValueKey('analytics-alerts')));
      expect(find.text('1 open · 0 acknowledged (still open) · 0 resolved'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('visible report refreshes from saved changes and reset',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    await tester.tap(find.byKey(const ValueKey('main-tab-More')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    await reveal(
        tester, find.byKey(const ValueKey('analytics-status-In transit')));
    await store.advanceTrip('TR-2048', DateTime.now());
    await tester.pumpAndSettle();
    expect(find.text('In transit: 0'), findsOneWidget);
    expect(find.text('Approaching: 1'), findsOneWidget);
    await reveal(tester, find.byKey(const ValueKey('analytics-alerts')));
    await store.acknowledgeAlert('alert-tracking');
    await tester.pumpAndSettle();
    expect(find.text('2 open · 1 acknowledged (still open) · 0 resolved'),
        findsOneWidget);
    await store.resolveAlert(
        'alert-tracking', 'Demo resolution', DateTime.now());
    await tester.pumpAndSettle();
    expect(find.text('1 open · 0 acknowledged (still open) · 1 resolved'),
        findsOneWidget);
    await store.reset();
    await tester.pumpAndSettle();
    expect(find.text('2 open · 0 acknowledged (still open) · 0 resolved'),
        findsOneWidget);
  });
}
