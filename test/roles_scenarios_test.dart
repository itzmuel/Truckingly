import 'dart:convert';

import 'package:dumptrak_mobile_prototype/demo_store.dart';
import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_store_test.dart' show TestPersistence;

Future<void> reveal(WidgetTester tester, Finder finder,
    {double delta = 250}) async {
  await tester.scrollUntilVisible(finder, delta);
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> tab(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(ValueKey('main-tab-$label')));
  await tester.pumpAndSettle();
}

Future<void> chooseScenario(WidgetTester tester, DemoScenario scenario) async {
  final dropdown =
      find.byKey(ValueKey('guided-scenario-${DemoScenario.normal.name}'));
  await reveal(tester, dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(scenario.label).last);
  await tester.pumpAndSettle();
}

Future<void> loadScenario(WidgetTester tester, DemoScenario scenario) async {
  await chooseScenario(tester, scenario);
  final load = find.byKey(const ValueKey('load-guided-scenario'));
  await reveal(tester, load);
  await tester.tap(load);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('confirm-load-guided-scenario')));
  await tester.pumpAndSettle();
}

void main() {
  test('scenario templates persist and baseline reset restores original data',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await store.advance(DateTime.utc(2026, 11, 12));
    final changedSnapshot = persistence.snapshot;
    await store.loadScenario(DemoScenario.delayedDelivery);
    expect(store.scenario, DemoScenario.delayedDelivery);
    expect(store.trips.first.status, 'In transit');
    expect(store.trips.first.eta, 'Simulated · Running behind schedule');
    expect(store.alerts.length, 3);
    expect(store.alerts.last.id, 'alert-delay-demo');
    expect(store.alerts.every((alert) => alert.isOpen), isTrue);
    expect(persistence.snapshot, isNot(changedSnapshot));

    final loadedDelay = await DemoStore.load(persistence);
    addTearDown(loadedDelay.dispose);
    expect(loadedDelay.scenario, DemoScenario.delayedDelivery);
    expect(loadedDelay.alerts.last.title, 'Delivery running behind schedule');

    await loadedDelay.loadScenario(DemoScenario.vehicleIncident);
    expect(loadedDelay.scenario, DemoScenario.vehicleIncident);
    expect(loadedDelay.trips.first.status, 'Exception');
    expect(loadedDelay.trips.first.canAdvance, isFalse);
    expect(loadedDelay.alerts.last.id, 'alert-incident-demo');
    final loadedIncident = await DemoStore.load(persistence);
    addTearDown(loadedIncident.dispose);
    expect(loadedIncident.scenario, DemoScenario.vehicleIncident);
    expect(loadedIncident.trips.first.status, 'Exception');

    await loadedIncident.reset();
    expect(loadedIncident.scenario, DemoScenario.normal);
    expect(loadedIncident.trips.first.status, 'In transit');
    expect(loadedIncident.alerts.length, 2);
  });

  test(
      'scenario persistence is atomic and unknown saved scenarios are rejected',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final original = persistence.snapshot;
    persistence.failWrite = true;
    await expectLater(
      store.loadScenario(DemoScenario.vehicleIncident),
      throwsA(isA<PlatformException>()),
    );
    expect(store.scenario, DemoScenario.normal);
    expect(store.trips.first.status, 'In transit');
    expect(store.alerts.length, 2);
    expect(persistence.snapshot, original);

    persistence.failWrite = false;
    final invalid = jsonDecode(original!) as Map<String, dynamic>;
    invalid['scenario'] = 'production';
    persistence.snapshot = jsonEncode(invalid);
    await expectLater(
      DemoStore.load(persistence),
      throwsA(isA<FormatException>()),
    );
  });

  testWidgets('switches display-only roles without restricting actions',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    await tab(tester, 'More');
    final role = find.byKey(const ValueKey('demo-role-switcher'));
    await reveal(tester, role);
    expect(find.text('Samuel Onyenwe'), findsOneWidget);
    await tester.tap(role);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Driver').last);
    await tester.pumpAndSettle();
    expect(find.text('Ayo Bello'), findsOneWidget);
    expect(find.textContaining('No permissions, account access, or actions'),
        findsOneWidget);

    await tab(tester, 'Trips');
    expect(find.byTooltip('New trip'), findsOneWidget);
    expect(find.text('2 trips'), findsOneWidget);
    expect(store.trips.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guided scenario confirmation cancel, load, reload and reset',
      (tester) async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    await tab(tester, 'More');
    await chooseScenario(tester, DemoScenario.delayedDelivery);
    expect(find.textContaining('simulated late delivery'), findsOneWidget);
    final load = find.byKey(const ValueKey('load-guided-scenario'));
    await tester.tap(load);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.scenario, DemoScenario.normal);
    expect(store.alerts.length, 2);

    await tester.tap(load);
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('confirm-load-guided-scenario')));
    await tester.pumpAndSettle();
    expect(store.scenario, DemoScenario.delayedDelivery);
    expect(store.alerts.length, 3);
    expect(find.text('Operations overview'), findsOneWidget);

    final reopened = await DemoStore.load(persistence);
    addTearDown(reopened.dispose);
    expect(reopened.scenario, DemoScenario.delayedDelivery);
    expect(reopened.alerts.length, 3);

    await tab(tester, 'More');
    await reveal(tester, find.byKey(const ValueKey('reset-demo')));
    await tester.tap(find.byKey(const ValueKey('reset-demo')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset Demo'));
    await tester.pumpAndSettle();
    expect(store.scenario, DemoScenario.normal);
    expect(store.alerts.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed scenario save retains prior records and selected choice',
      (tester) async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    await tab(tester, 'More');
    await chooseScenario(tester, DemoScenario.vehicleIncident);
    persistence.failWrite = true;
    final load = find.byKey(const ValueKey('load-guided-scenario'));
    await reveal(tester, load);
    await tester.tap(load);
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('confirm-load-guided-scenario')));
    await tester.pumpAndSettle();
    expect(store.scenario, DemoScenario.normal);
    expect(store.trips.first.status, 'In transit');
    expect(store.alerts.length, 2);
    expect(find.textContaining('Demo could not be saved:'), findsOneWidget);
    expect(find.text('Vehicle incident'), findsOneWidget);
    persistence.failWrite = false;
    expect(tester.takeException(), isNull);
  });

  testWidgets('walkthrough shortcuts navigate directly to selected screens',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    await tab(tester, 'More');
    final step = find.byKey(const ValueKey('walkthrough-step-2'));
    await reveal(tester, step);
    await tester.tap(find.descendant(
      of: step,
      matching: find.text('Open'),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('SIMULATED — NOT LIVE GPS'), findsOneWidget);
    expect(find.byKey(const ValueKey('main-tab-Map')), findsOneWidget);
  });

  testWidgets('role and scenario controls fit narrow screens with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    await tab(tester, 'More');
    await reveal(tester, find.byKey(const ValueKey('demo-role-switcher')));
    await reveal(tester, find.byKey(const ValueKey('guided-scenario-normal')));
    await reveal(tester, find.byKey(const ValueKey('walkthrough-step-4')));
    expect(tester.takeException(), isNull);
  });
}
