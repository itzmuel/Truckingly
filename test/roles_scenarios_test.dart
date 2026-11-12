import 'dart:convert';

import 'package:dumptrak_mobile_prototype/demo_director.dart';
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

Future<void> waitForPresentationActions(WidgetTester tester) async {
  const completeKey = ValueKey('presentation-action-complete');
  for (var attempt = 0; attempt < 240; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byKey(completeKey).evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Presentation action sequence did not finish.');
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

  testWidgets('Home opens the stakeholder walkthrough landing page',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));

    final launch = find.byKey(const ValueKey('open-stakeholder-walkthrough'));
    await reveal(tester, launch);
    await tester.tap(launch);
    await tester.pumpAndSettle();

    expect(find.text('Stakeholder walkthrough'), findsOneWidget);
    expect(find.text('A guided, simulated demo'), findsOneWidget);
    await reveal(tester, find.byKey(const ValueKey('guided-scenario-normal')));
    expect(
        find.byKey(const ValueKey('guided-scenario-normal')), findsOneWidget);
    expect(find.byKey(const ValueKey('load-guided-scenario')), findsOneWidget);
    expect(find.byKey(const ValueKey('walkthrough-step-0')), findsOneWidget);
    expect(store.scenario, DemoScenario.normal);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Operations overview'), findsOneWidget);
    expect(find.byKey(const ValueKey('main-tab-Home')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Demo Director cancel preserves data and system Back returns Home',
      (tester) async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await store.advance(DateTime.utc(2026, 11, 12));
    final snapshot = persistence.snapshot;
    final firstTripStatus = store.trips.first.status;
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));

    final launch = find.byKey(const ValueKey('open-stakeholder-walkthrough'));
    await reveal(tester, launch);
    await tester.tap(launch);
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('start-presentation')));
    await tester.tap(find.byKey(const ValueKey('start-presentation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(store.scenario, DemoScenario.normal);
    expect(store.trips.first.status, firstTripStatus);
    expect(persistence.snapshot, snapshot);

    await chooseScenario(tester, DemoScenario.vehicleIncident);
    await tester.tap(find.byKey(const ValueKey('start-presentation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-start-presentation')));
    await tester.pumpAndSettle();
    await waitForPresentationActions(tester);
    expect(find.text('STEP 1 OF 5 · HOME'), findsOneWidget);
    expect(find.byKey(const ValueKey('presentation-next')), findsOneWidget);
    expect(store.scenario, DemoScenario.vehicleIncident);
    expect(store.trips.first.status, 'Exception');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Operations overview'), findsOneWidget);
    expect(find.byKey(const ValueKey('main-tab-Home')), findsOneWidget);
    expect(find.byKey(const ValueKey('stop-presentation')), findsNothing);
    expect(store.scenario, DemoScenario.vehicleIncident);
    expect(tester.takeException(), isNull);
  });

  testWidgets('autoplay pauses, resumes, and advances its timed sequence',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    final launch = find.byKey(const ValueKey('open-stakeholder-walkthrough'));
    await reveal(tester, launch);
    await tester.tap(launch);
    await tester.pumpAndSettle();

    final mode = find.byKey(
        ValueKey('presentation-mode-${DemoPresentationMode.guided.name}'));
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tester.tap(find.text(DemoPresentationMode.autoplay.label).last);
    await tester.pumpAndSettle();

    final length = find.byKey(const ValueKey('presentation-length-5'));
    await reveal(tester, length);
    await tester.tap(length);
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 minutes').last);
    await tester.pumpAndSettle();

    final start = find.byKey(const ValueKey('start-presentation'));
    await reveal(tester, start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-start-presentation')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('presentation-pause')));
    await tester.pumpAndSettle();
    await waitForPresentationActions(tester);
    final pausedClock = tester
        .widget<Text>(find.byKey(const ValueKey('presentation-countdown')))
        .data!;
    await tester.pump(const Duration(seconds: 40));
    expect(find.text('STEP 1 OF 5 · HOME'), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('presentation-countdown')))
            .data,
        pausedClock);

    await tester.tap(find.byKey(const ValueKey('presentation-resume')));
    await tester.pump();
    final remainingParts = pausedClock.split(':');
    final remainingSeconds =
        int.parse(remainingParts[0]) * 60 + int.parse(remainingParts[1]);
    await tester.pump(Duration(seconds: remainingSeconds));
    await tester.pump();
    expect(find.text('STEP 2 OF 5 · TRIPS'), findsOneWidget);
    expect(find.text('Trip activity'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('presentation-pause')));
    await tester.pump();
    await waitForPresentationActions(tester);
    await tester.tap(find.byKey(const ValueKey('stop-presentation')));
    await tester.pumpAndSettle();
    expect(find.text('Operations overview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guided presentation records trip and alert actions once',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    final launch = find.byKey(const ValueKey('open-stakeholder-walkthrough'));
    await reveal(tester, launch);
    await tester.tap(launch);
    await tester.pumpAndSettle();
    final start = find.byKey(const ValueKey('start-presentation'));
    await reveal(tester, start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-start-presentation')));
    await tester.pumpAndSettle();
    await waitForPresentationActions(tester);

    await tester.tap(find.byKey(const ValueKey('presentation-next')));
    await tester.pumpAndSettle();
    await waitForPresentationActions(tester);
    expect(find.text('Trip activity'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('presentation-next')));
    await tester.pumpAndSettle();
    await waitForPresentationActions(tester);
    expect(store.tripByCode('TR-2048').status, 'Approaching');
    expect(find.text('STEP 3 OF 5 · MAP'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('presentation-previous')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('presentation-next')));
    await tester.pumpAndSettle();
    expect(store.tripByCode('TR-2048').status, 'Approaching');

    await tester.tap(find.byKey(const ValueKey('presentation-next')));
    await tester.pumpAndSettle();
    await waitForPresentationActions(tester);
    expect(find.text('Situation management'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('presentation-next')));
    await tester.pumpAndSettle();
    await waitForPresentationActions(tester);
    expect(store.alertById('alert-tracking').acknowledged, isTrue);
    expect(find.text('STEP 5 OF 5 · REPORTS'), findsOneWidget);
    expect(find.text('Operational reports'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('finish-presentation')));
    await tester.pumpAndSettle();
    expect(find.text('Operations overview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replay confirms before restoring a fresh presentation scenario',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    final launch = find.byKey(const ValueKey('open-stakeholder-walkthrough'));
    await reveal(tester, launch);
    await tester.tap(launch);
    await tester.pumpAndSettle();
    final mode = find.byKey(
        ValueKey('presentation-mode-${DemoPresentationMode.guided.name}'));
    await reveal(tester, mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tester.tap(find.text(DemoPresentationMode.autoplay.label).last);
    await tester.pumpAndSettle();
    final start = find.byKey(const ValueKey('start-presentation'));
    await reveal(tester, start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-start-presentation')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('presentation-pause')));
    await tester.pumpAndSettle();
    await waitForPresentationActions(tester);

    for (var index = 0; index < 4; index++) {
      await tester.tap(find.byKey(const ValueKey('presentation-next')));
      await tester.pumpAndSettle();
      await waitForPresentationActions(tester);
    }
    expect(store.tripByCode('TR-2048').status, 'Approaching');
    expect(store.alertById('alert-tracking').acknowledged, isTrue);
    expect(find.byKey(const ValueKey('replay-presentation')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('replay-presentation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.tripByCode('TR-2048').status, 'Approaching');
    expect(store.alertById('alert-tracking').acknowledged, isTrue);

    await tester.tap(find.byKey(const ValueKey('replay-presentation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-start-presentation')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('presentation-pause')));
    await tester.pumpAndSettle();
    await waitForPresentationActions(tester);
    expect(store.trips, hasLength(2));
    expect(store.tripByCode('TR-2048').status, 'Approaching');
    expect(store.alertById('alert-tracking').acknowledged, isFalse);
    expect(store.alerts, hasLength(2));
    expect(find.text('STEP 1 OF 5 · HOME'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('stop-presentation')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('automated demo shows its touch pointer and driver perspective',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    final launch = find.byKey(const ValueKey('open-stakeholder-walkthrough'));
    await reveal(tester, launch);
    await tester.tap(launch);
    await tester.pumpAndSettle();

    final mode = find.byKey(
        ValueKey('presentation-mode-${DemoPresentationMode.guided.name}'));
    await reveal(tester, mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tester.tap(find.text(DemoPresentationMode.autoplay.label).last);
    await tester.pumpAndSettle();

    final role = find.byKey(const ValueKey('presentation-role-switcher'));
    await reveal(tester, role);
    await tester.tap(role);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Driver').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('start-presentation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-start-presentation')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('presentation-pause')));
    await tester.pump();
    expect(find.textContaining('Ayo Bello · Driver'), findsOneWidget);

    var sawTouch = false;
    for (var attempt = 0; attempt < 80 && !sawTouch; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      sawTouch = find.text('Open trip').evaluate().isNotEmpty;
    }
    expect(sawTouch, isTrue);
    await waitForPresentationActions(tester);

    for (var step = 0; step < 3; step++) {
      await tester.tap(find.byKey(const ValueKey('presentation-next')));
      await tester.pumpAndSettle();
      await waitForPresentationActions(tester);
    }
    expect(find.text('STEP 4 OF 5 · ALERTS'), findsOneWidget);
    expect(store.alertById('alert-tracking').acknowledged, isFalse);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('stop-presentation')));
    await tester.pumpAndSettle();
  });

  testWidgets('stopping during pointer animation cancels pending action',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));

    final launch = find.byKey(const ValueKey('open-stakeholder-walkthrough'));
    await reveal(tester, launch);
    await tester.tap(launch);
    await tester.pumpAndSettle();

    final mode = find.byKey(
        ValueKey('presentation-mode-${DemoPresentationMode.guided.name}'));
    await reveal(tester, mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tester.tap(find.text(DemoPresentationMode.autoplay.label).last);
    await tester.pumpAndSettle();
    final start = find.byKey(const ValueKey('start-presentation'));
    await reveal(tester, start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-start-presentation')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('presentation-pause')));
    await tester.pump();

    var sawPointer = false;
    for (var attempt = 0; attempt < 80 && !sawPointer; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      sawPointer = find.text('Open trip').evaluate().isNotEmpty;
    }
    expect(sawPointer, isTrue);
    await tester.tap(find.byKey(const ValueKey('stop-presentation')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(store.tripByCode('TR-2048').status, 'In transit');
    expect(find.byKey(const ValueKey('advance-trip')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Explore loads the chosen scenario and applies display-only role',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    final launch = find.byKey(const ValueKey('open-stakeholder-walkthrough'));
    await reveal(tester, launch);
    await tester.tap(launch);
    await tester.pumpAndSettle();

    final mode = find.byKey(
        ValueKey('presentation-mode-${DemoPresentationMode.guided.name}'));
    await reveal(tester, mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tester.tap(find.text(DemoPresentationMode.explore.label).last);
    await tester.pumpAndSettle();

    final role = find.byKey(const ValueKey('presentation-role-switcher'));
    await reveal(tester, role);
    await tester.tap(role);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supervisor').last);
    await tester.pumpAndSettle();
    await chooseScenario(tester, DemoScenario.vehicleIncident);

    final start = find.byKey(const ValueKey('start-presentation'));
    await reveal(tester, start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-start-presentation')));
    await tester.pumpAndSettle();

    expect(store.scenario, DemoScenario.vehicleIncident);
    expect(store.trips.first.status, 'Exception');
    expect(find.text('Operations overview'), findsOneWidget);
    expect(find.byKey(const ValueKey('stop-presentation')), findsNothing);
    expect(find.byKey(const ValueKey('main-tab-More')), findsOneWidget);
    await tab(tester, 'More');
    await reveal(tester, find.text('Femi Adewale'));
    expect(find.text('Femi Adewale'), findsOneWidget);
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
