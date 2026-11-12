import 'dart:async';
import 'dart:convert';

import 'package:dumptrak_mobile_prototype/demo_store.dart';
import 'package:dumptrak_mobile_prototype/demo_trip_catalog.dart';
import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_store_test.dart' show TestPersistence;

const draft = DemoTripDraft(
  project: 'Lekki development',
  origin: 'Ikeja Quarry',
  destination: 'Lekki Site',
  driver: 'Ayo Bello',
  vehicle: 'DT-15',
  material: 'Sand',
);

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 180,
      scrollable: find.byType(Scrollable).last);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> select(WidgetTester tester, String field, String value) async {
  final finder = find.byKey(ValueKey('new-trip-$field'));
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

Future<void> next(WidgetTester tester) async {
  final finder = find.byKey(const ValueKey('wizard-next'));
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> route(WidgetTester tester) async {
  await select(tester, 'project', draft.project);
  await select(tester, 'origin', draft.origin);
  await select(tester, 'destination', draft.destination);
}

Future<void> assignments(WidgetTester tester) async {
  await select(tester, 'driver', draft.driver);
  await select(tester, 'vehicle', draft.vehicle);
  await select(tester, 'material', draft.material);
}

Future<void> open(WidgetTester tester, DemoStore store) async {
  await tester.pumpWidget(DumptrakPrototypeApp(store: store));
  await tester.tap(find.text('Trips').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('New trip'));
  await tester.pumpAndSettle();
}

void main() {
  test('created assignments persist, advance, and reset with existing records',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final trip = await store.createTrip(draft);
    expect(trip.code, 'TR-2049');
    expect(trip.status, 'Planned');
    expect(trip.progress, 0);
    expect(trip.completedAt, isNull);
    expect(store.activeTrips.length, 3);
    final loaded = await DemoStore.load(persistence);
    addTearDown(loaded.dispose);
    expect(loaded.trips.first.driver, draft.driver);
    expect(loaded.trips.first.project, draft.project);
    await loaded.advance(DateTime.now());
    expect(loaded.trips.first.status, 'Dispatched');
    expect(loaded.trips.first.driver, draft.driver);
    expect(loaded.trips.first.project, draft.project);
    await loaded.reset();
    expect(loaded.trips.length, 2);
  });

  test('invalid draft and busy assignments never change saved state', () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final before = persistence.snapshot;
    await expectLater(
      store.createTrip(const DemoTripDraft(
        project: '',
        origin: 'Ikeja Quarry',
        destination: 'Lekki Site',
        driver: 'Ayo Bello',
        vehicle: 'DT-15',
        material: 'Sand',
      )),
      throwsA(isA<FormatException>()),
    );
    expect(persistence.snapshot, before);
    await store.createTrip(draft);
    final saved = persistence.snapshot;
    await expectLater(store.createTrip(draft), throwsA(isA<FormatException>()));
    await expectLater(
      store.createTrip(const DemoTripDraft(
        project: 'Lekki development',
        origin: 'Ikeja Quarry',
        destination: 'Lekki Site',
        driver: 'Ayo Bello',
        vehicle: 'DT-18',
        material: 'Sand',
      )),
      throwsA(isA<FormatException>()),
    );
    expect(persistence.snapshot, saved);
    expect(store.trips.length, 3);
  });

  test('failed creation retries without consuming an ID; IDs remain unique',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    persistence.failWrite = true;
    await expectLater(
        store.createTrip(draft), throwsA(isA<PlatformException>()));
    expect(store.trips.length, 2);
    persistence.failWrite = false;
    expect((await store.createTrip(draft)).code, 'TR-2049');
    final second = await store.createTrip(const DemoTripDraft(
      project: 'Apapa logistics',
      origin: 'Ogun Yard',
      destination: 'Apapa Terminal',
      driver: 'Chidi Okafor',
      vehicle: 'DT-18',
      material: 'Laterite',
    ));
    expect(second.code, 'TR-2050');
    expect(store.availableVehicles, isEmpty);
    expect(store.trips.map((trip) => trip.code).toSet().length, 4);
  });

  test('older snapshots without new assignments still load', () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final snapshot = jsonDecode(persistence.snapshot!) as Map<String, dynamic>;
    for (final trip in snapshot['trips']) {
      trip.remove('project');
      trip.remove('driver');
    }
    persistence.snapshot = jsonEncode(snapshot);
    final loaded = await DemoStore.load(persistence);
    addTearDown(loaded.dispose);
    expect(loaded.trips.length, 2);
    expect(loaded.trips.first.project, isNull);
  });

  test('invalid saved assignments are reported without replacing data',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await store.createTrip(draft);
    final saved = persistence.snapshot!;
    for (final (field, value) in [
      ('project', ''),
      ('driver', 'Unknown driver'),
      ('driver', null),
      ('route', 'Invalid route'),
    ]) {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      decoded['trips'][0][field] = value;
      final raw = jsonEncode(decoded);
      persistence.snapshot = raw;
      await expectLater(
          DemoStore.load(persistence), throwsA(isA<FormatException>()));
      expect(persistence.snapshot, raw);
    }
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('wizard creates and persists trip at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
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
      await open(tester, store);
      await route(tester);
      await next(tester);
      await assignments(tester);
      await next(tester);
      await reveal(tester, find.text('Initial status: Planned'));
      expect(find.text('Initial status: Planned'), findsOneWidget);
      await next(tester);
      expect(find.text('New demo trip'), findsNothing);
      await reveal(tester, find.text('TR-2049'));
      expect(find.text('TR-2049'), findsOneWidget);
      expect(find.text('PLANNED'), findsOneWidget);
      expect(find.text('3 trips'), findsOneWidget);
      final loaded = await DemoStore.load(persistence);
      addTearDown(loaded.dispose);
      expect(loaded.trips.first.project, draft.project);
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      final metrics = tester.widgetList<MetricCard>(find.byType(MetricCard));
      expect(metrics.firstWhere((m) => m.label == 'ACTIVE TRIPS').value, '3');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('system Back preserves wizard selections between steps',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await open(tester, store);
    await route(tester);
    await next(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3 · Route & project'), findsOneWidget);
    expect(find.text(draft.project), findsOneWidget);
    await next(tester);
    await assignments(tester);
    await next(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3 · Assignments'), findsOneWidget);
    expect(find.text(draft.driver), findsOneWidget);
    expect(store.trips.length, 2);
  });

  testWidgets('save error keeps review and retry adds exactly one trip',
      (tester) async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await open(tester, store);
    await route(tester);
    await next(tester);
    await assignments(tester);
    await next(tester);
    persistence.failWrite = true;
    await next(tester);
    await reveal(tester, find.textContaining('Could not create demo trip:'));
    expect(store.trips.length, 2);
    persistence.failWrite = false;
    await next(tester);
    expect(store.trips.length, 3);
    expect(find.text('TR-2049'), findsOneWidget);
  });

  testWidgets('pending save prevents double submission and leaving wizard',
      (tester) async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await open(tester, store);
    await route(tester);
    await next(tester);
    await assignments(tester);
    await next(tester);
    final button = find.byKey(const ValueKey('wizard-next'));
    await reveal(tester, button);
    persistence.writeGate = Completer<void>();
    await tester.tap(button);
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('New demo trip'), findsOneWidget);
    expect(store.trips.length, 2);
    persistence.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(store.trips.length, 3);
    expect(find.text('New demo trip'), findsNothing);
  });

  testWidgets('creation clears a filter that would hide the new Planned trip',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    await tester.tap(find.text('Trips').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Archive'));
    await tester.pumpAndSettle();
    expect(find.text('No trips in this status'), findsOneWidget);
    await tester.tap(find.byTooltip('New trip'));
    await tester.pumpAndSettle();
    await route(tester);
    await next(tester);
    await assignments(tester);
    await next(tester);
    await next(tester);
    expect(find.text('TR-2049'), findsOneWidget);
    expect(find.text('All statuses'), findsOneWidget);
  });

  testWidgets('no free vehicles has an explicit state and cannot submit',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await store.createTrip(draft);
    await store.createTrip(const DemoTripDraft(
      project: 'Apapa logistics',
      origin: 'Ogun Yard',
      destination: 'Apapa Terminal',
      driver: 'Chidi Okafor',
      vehicle: 'DT-18',
      material: 'Laterite',
    ));
    await open(tester, store);
    await route(tester);
    await next(tester);
    expect(find.textContaining('No free demo assignments remain.'),
        findsOneWidget);
    await select(tester, 'driver', 'Tunde Adeyemi');
    await select(tester, 'material', 'Sand');
    await next(tester);
    expect(find.text('Choose a sample vehicle.'), findsOneWidget);
    expect(find.text('Step 2 of 3 · Assignments'), findsOneWidget);
    expect(store.trips.length, 4);
    expect(tester.takeException(), isNull);
  });
}
