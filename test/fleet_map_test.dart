import 'package:dumptrak_mobile_prototype/demo_fleet.dart';
import 'package:dumptrak_mobile_prototype/demo_store.dart';
import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trip_wizard_test.dart' show draft;

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 180,
      scrollable: find.byType(Scrollable).last);
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  test('fleet reflects saved assignments, journey stages, gaps and reset',
      () async {
    final persistence = MemoryDemoPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    DemoVehicle vehicle(String id) =>
        demoFleet(store).firstWhere((vehicle) => vehicle.id == id);
    expect(demoFleet(store).length, 4);
    expect(vehicle('DT-07').status, DemoVehicleStatus.reportingGap);
    expect(vehicle('DT-07').speed, isNull);
    expect(vehicle('DT-12').status, DemoVehicleStatus.loading);
    expect(vehicle('DT-15').trip, isNull);
    final trip = await store.createTrip(draft);
    expect(vehicle('DT-15').driver, draft.driver);
    expect(vehicle('DT-15').routePosition, 0);
    final now = DateTime.now();
    while (store.tripByCode(trip.code).status != 'In transit') {
      await store.advanceTrip(trip.code, now);
    }
    expect(vehicle('DT-15').status, DemoVehicleStatus.moving);
    expect(vehicle('DT-15').speed, 42);
    expect(vehicle('DT-15').routePosition, 0.5);
    await store.advanceTrip(trip.code, now);
    expect(vehicle('DT-15').routePosition, 0.8);
    expect(vehicle('DT-15').speed, 24);
    await store.advanceTrip(trip.code, now);
    expect(vehicle('DT-15').routePosition, 1);
    expect(vehicle('DT-15').status, DemoVehicleStatus.idle);
    expect(vehicle('DT-15').speed, 0);
    await store.advanceTrip(trip.code, now);
    final loaded = await DemoStore.load(persistence);
    addTearDown(loaded.dispose);
    expect(demoFleet(loaded).firstWhere((v) => v.id == 'DT-15').trip!.status,
        'Completed');
    await store.advanceTrip('TR-2048', now);
    expect(vehicle('DT-07').status, DemoVehicleStatus.reportingGap);
    await store.reset();
    expect(vehicle('DT-15').trip, isNull);
    expect(vehicle('DT-12').status, DemoVehicleStatus.loading);
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('map markers and details work at width $width', (tester) async {
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
      await tester.pumpWidget(DumptrakPrototypeApp(store: store));
      await tester.tap(find.text('Map').last);
      await tester.pumpAndSettle();
      for (final id in ['DT-07', 'DT-12', 'DT-15', 'DT-18']) {
        final marker = find.byKey(ValueKey('map-marker-$id'));
        await reveal(tester, marker);
        await tester.tap(marker);
        await tester.pumpAndSettle();
        expect(find.text('Vehicle $id'), findsOneWidget);
        expect(find.textContaining('SIMULATED — NOT LIVE GPS'), findsWidgets);
        if (id == 'DT-07') {
          await reveal(
              tester, find.text('Simulated speed: Unknown · Reporting gap'));
          expect(find.text('Simulated speed: Unknown · Reporting gap'),
              findsOneWidget);
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Vehicle $id'), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await reveal(tester, find.byKey(const ValueKey('fleet-vehicle-DT-18')));
      await tester.tap(find.byKey(const ValueKey('fleet-vehicle-DT-18')));
      await tester.pumpAndSettle();
      expect(find.text('Assigned trip: No assigned demo trip'), findsOneWidget);
      expect(find.byKey(const ValueKey('vehicle-open-trip')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Operations overview'), findsOneWidget);
    });
  }

  testWidgets('map opens assigned trip and updates position after advancing',
      (tester) async {
    final store = DemoStore.memory();
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    await tester.tap(find.text('Map').last);
    await tester.pumpAndSettle();
    final marker = find.byKey(const ValueKey('map-marker-DT-12'));
    await reveal(tester, marker);
    final start = tester.getCenter(marker);
    await tester.tap(marker);
    await tester.pumpAndSettle();
    final open = find.byKey(const ValueKey('vehicle-open-trip'));
    await reveal(tester, open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.text('Status: At origin'), findsOneWidget);
    final advance = find.byKey(const ValueKey('advance-trip'));
    await reveal(tester, advance);
    await tester.tap(advance);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await reveal(tester, marker);
    expect(tester.getCenter(marker).dx, greaterThan(start.dx));
    await tester.tap(marker);
    await tester.pumpAndSettle();
    expect(find.text('Vehicle status: Moving'), findsOneWidget);
    await reveal(tester, find.text('Simulated speed: 42 km/h'));
    expect(find.text('Simulated speed: 42 km/h'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map supports zoom and reset view', (tester) async {
    await tester.pumpWidget(const DumptrakPrototypeApp());
    await tester.tap(find.text('Map').last);
    await tester.pumpAndSettle();
    final viewer = find.byType(InteractiveViewer);
    await reveal(tester, viewer);
    final center = tester.getCenter(viewer);
    final first =
        await tester.startGesture(center - const Offset(30, 0), pointer: 1);
    final second =
        await tester.startGesture(center + const Offset(30, 0), pointer: 2);
    await first.moveTo(center - const Offset(70, 0));
    await second.moveTo(center + const Offset(70, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    final controller =
        tester.widget<InteractiveViewer>(viewer).transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
    final reset = find.byKey(const ValueKey('reset-map-view'));
    await Scrollable.ensureVisible(tester.element(reset));
    await tester.pumpAndSettle();
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), 1);
    expect(tester.takeException(), isNull);
  });
}
