import 'dart:async';
import 'dart:convert';

import 'package:dumptrak_mobile_prototype/demo_store.dart';
import 'package:dumptrak_mobile_prototype/demo_trip_catalog.dart';
import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_store_test.dart' show TestPersistence;
import 'trip_wizard_test.dart' show draft, next, select;

const changed = DemoTripDraft(
  project: 'Apapa logistics',
  origin: 'Ogun Yard',
  destination: 'Apapa Terminal',
  driver: 'Chidi Okafor',
  vehicle: 'DT-18',
  material: 'Laterite',
);

Future<void> reveal(WidgetTester tester, Finder finder,
    {double delta = 220}) async {
  await tester.scrollUntilVisible(finder, delta,
      scrollable: find.byType(Scrollable).last);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> openDetails(WidgetTester tester, DemoStore store, String code,
    {String tab = 'Trips'}) async {
  await tester.pumpWidget(DumptrakPrototypeApp(store: store));
  await tester.tap(find.text(tab).last);
  await tester.pumpAndSettle();
  await reveal(tester, find.text(code));
  await tester.tap(find.text(code));
  await tester.pumpAndSettle();
}

void main() {
  test('editing saves assignments but preserves status and recorded timeline',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final trip = await store.createTrip(draft);
    await store.advanceTrip(trip.code, DateTime.now());
    final before = store.tripByCode(trip.code);
    final edited = await store.editTrip(trip.code, changed);
    expect(edited.status, 'Dispatched');
    expect(edited.progress, before.progress);
    expect(edited.events.map((e) => e.toJson()),
        before.events.map((e) => e.toJson()));
    expect(store.availableVehicles, contains('DT-15'));
    expect(store.availableDrivers, contains('Ayo Bello'));
    final loaded = await DemoStore.load(persistence);
    addTearDown(loaded.dispose);
    expect(loaded.tripByCode(trip.code).project, changed.project);
    expect(loaded.tripByCode(trip.code).driver, changed.driver);
    expect(loaded.tripByCode(trip.code).route, 'Ogun Yard → Apapa Terminal');
    expect(loaded.tripByCode(trip.code).events.length, 2);
  });

  test('advance affects only selected trip, persists timeline and completion',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final trip = await store.createTrip(draft);
    final now = DateTime.utc(2026, 11, 12, 12);
    while (store.tripByCode(trip.code).canAdvance) {
      await store.advanceTrip(trip.code, now);
    }
    expect(store.tripByCode('TR-2048').status, 'In transit');
    expect(store.tripByCode('TR-2047').status, 'At origin');
    expect(store.completedOn(now), 1);
    expect(store.alerts.length, 2);
    final loaded = await DemoStore.load(persistence);
    addTearDown(loaded.dispose);
    expect(loaded.tripByCode(trip.code).events.map((event) => event.status),
        Trip.journey);
    expect(loaded.tripByCode(trip.code).completedAt, now);
    await expectLater(
        loaded.advanceTrip(trip.code, now), throwsA(isA<FormatException>()));
    await expectLater(
        loaded.editTrip(trip.code, changed), throwsA(isA<FormatException>()));
    await expectLater(
        loaded.advanceTrip('missing', now), throwsA(isA<FormatException>()));
  });

  test('failed edit/advance leave snapshot and timeline unchanged', () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final trip = await store.createTrip(draft);
    final before = persistence.snapshot;
    persistence.failWrite = true;
    await expectLater(
        store.editTrip(trip.code, changed), throwsA(isA<PlatformException>()));
    await expectLater(store.advanceTrip(trip.code, DateTime.now()),
        throwsA(isA<PlatformException>()));
    expect(store.tripByCode(trip.code).driver, draft.driver);
    expect(store.tripByCode(trip.code).events.length, 1);
    expect(persistence.snapshot, before);
    persistence.failWrite = false;
    await store.editTrip(trip.code, changed);
    await store.advanceTrip(trip.code, DateTime.now());
    expect(store.tripByCode(trip.code).status, 'Dispatched');
  });

  test('edits reject conflicts, invalid inputs and departed trips', () async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    final trip = await store.createTrip(draft);
    await store.editTrip(trip.code, draft);
    await expectLater(
      store.editTrip(
          trip.code,
          const DemoTripDraft(
            project: 'Lekki development',
            origin: 'Ikeja Quarry',
            destination: 'Lekki Site',
            driver: 'Chidi Okafor',
            vehicle: 'DT-07',
            material: 'Sand',
          )),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
        store.editTrip('TR-2048', changed), throwsA(isA<FormatException>()));
    await expectLater(
        store.editTrip('missing', changed), throwsA(isA<FormatException>()));
  });

  test('legacy timeline is unknown; invalid saved events are rejected',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final original = persistence.snapshot!;
    final old = jsonDecode(original) as Map<String, dynamic>;
    for (final trip in old['trips']) {
      trip.remove('events');
    }
    persistence.snapshot = jsonEncode(old);
    final legacy = await DemoStore.load(persistence);
    addTearDown(legacy.dispose);
    expect(legacy.trips.first.events, isEmpty);
    for (final events in [
      'invalid',
      [42],
      [
        {'status': 'Arrived', 'at': 'bad'}
      ],
      [
        {'status': 'Arrived', 'at': '2026-11-12T12:00:00Z'}
      ],
    ]) {
      final decoded = jsonDecode(original) as Map<String, dynamic>;
      decoded['trips'][0]['events'] = events;
      persistence.snapshot = jsonEncode(decoded);
      await expectLater(
          DemoStore.load(persistence), throwsA(isA<FormatException>()));
    }
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('trip details edit and individual journey fit width $width',
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
      final trip = await store.createTrip(draft);
      await openDetails(tester, store, trip.code);
      await reveal(tester, find.byKey(const ValueKey('edit-trip')));
      await tester.tap(find.byKey(const ValueKey('edit-trip')));
      await tester.pumpAndSettle();
      expect(find.text('Edit ${trip.code}'), findsOneWidget);
      await select(tester, 'project', changed.project);
      await next(tester);
      await select(tester, 'material', 'Laterite');
      await next(tester);
      await next(tester);
      expect(find.text('Edit ${trip.code}'), findsNothing);
      expect(store.tripByCode(trip.code).project, changed.project);
      expect(store.tripByCode(trip.code).status, 'Planned');
      final advance = find.byKey(const ValueKey('advance-trip'));
      await reveal(tester, advance);
      await tester.tap(advance);
      await tester.pumpAndSettle();
      expect(store.tripByCode(trip.code).status, 'Dispatched');
      expect(store.tripByCode('TR-2048').status, 'In transit');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Journey timeline'), findsNothing);
      expect(find.text('DISPATCHED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Home opens seed details without inventing timestamps',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await openDetails(tester, store, 'TR-2048', tab: 'Home');
    expect(find.text('Status: In transit'), findsOneWidget);
    final edit = find.byKey(const ValueKey('edit-trip'));
    await reveal(tester, edit);
    expect(tester.widget<OutlinedButton>(edit).onPressed, isNull);
    await reveal(
        tester, find.text('Current sample stage · Timestamp not recorded'));
    expect(find.text('Current sample stage · Timestamp not recorded'),
        findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Operations overview'), delta: -220);
    expect(find.text('Operations overview'), findsOneWidget);
  });

  testWidgets('detail save error is visible and retry succeeds',
      (tester) async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await openDetails(tester, store, 'TR-2048');
    final advance = find.byKey(const ValueKey('advance-trip'));
    await reveal(tester, advance);
    persistence.failWrite = true;
    await tester.tap(advance);
    await tester.pumpAndSettle();
    await reveal(tester, find.textContaining('Could not advance demo trip:'));
    expect(store.tripByCode('TR-2048').status, 'In transit');
    persistence.failWrite = false;
    await reveal(tester, advance);
    await tester.tap(advance);
    await tester.pumpAndSettle();
    expect(store.tripByCode('TR-2048').status, 'Approaching');
  });

  testWidgets('edit save error retains review and retries without changing status',
      (tester) async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final trip = await store.createTrip(draft);
    await openDetails(tester, store, trip.code);
    final edit = find.byKey(const ValueKey('edit-trip'));
    await reveal(tester, edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await select(tester, 'project', changed.project);
    await next(tester);
    await next(tester);
    persistence.failWrite = true;
    await next(tester);
    await reveal(tester, find.textContaining('Could not save demo trip:'));
    expect(store.tripByCode(trip.code).project, draft.project);
    persistence.failWrite = false;
    await next(tester);
    expect(store.tripByCode(trip.code).project, changed.project);
    expect(store.tripByCode(trip.code).status, 'Planned');
    expect(store.trips.length, 3);
  });

  testWidgets('completed trip is read-only and shows recorded completion',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    final now = DateTime.utc(2026, 11, 12, 12);
    while (store.tripByCode('TR-2048').canAdvance) {
      await store.advanceTrip('TR-2048', now);
    }
    await openDetails(tester, store, 'TR-2048');
    expect(find.text('Status: Completed'), findsOneWidget);
    final edit = find.byKey(const ValueKey('edit-trip'));
    await reveal(tester, edit);
    expect(tester.widget<OutlinedButton>(edit).onPressed, isNull);
    final advance = find.byKey(const ValueKey('advance-trip'));
    await reveal(tester, advance);
    expect(tester.widget<FilledButton>(advance).onPressed, isNull);
    expect(find.textContaining('Simulated completion:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail pending save blocks duplicate actions and Back',
      (tester) async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    await openDetails(tester, store, 'TR-2048');
    final advance = find.byKey(const ValueKey('advance-trip'));
    await reveal(tester, advance);
    persistence.writeGate = Completer<void>();
    await tester.tap(advance);
    await tester.pump();
    expect(tester.widget<FilledButton>(advance).onPressed, isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.byKey(const ValueKey('advance-trip')), findsOneWidget);
    persistence.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(store.tripByCode('TR-2048').events.length, 1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('advance-trip')), findsNothing);
  });
}
