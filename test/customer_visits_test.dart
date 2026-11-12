import 'dart:convert';

import 'package:dumptrak_mobile_prototype/demo_store.dart';
import 'package:dumptrak_mobile_prototype/demo_visit_analytics.dart';
import 'package:dumptrak_mobile_prototype/main.dart';
import 'package:dumptrak_mobile_prototype/reports_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_store_test.dart' show TestPersistence;

DateTime day(int day, [int hour = 12, int minute = 0]) =>
    DateTime.utc(2026, 11, day, hour, minute);

DemoVisitAnalytics analytics(
  DemoStore store, {
  DateTime? from,
  DateTime? to,
  bool vehiclesOnly = false,
}) =>
    DemoVisitAnalytics(
      visits: store.visits,
      from: from ?? day(13),
      to: to ?? day(13),
      vehiclesOnly: vehiclesOnly,
    );

Future<void> reveal(WidgetTester tester, Finder finder,
    {double delta = 250}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(ValueKey('main-tab-$label')));
  await tester.pumpAndSettle();
}

void main() {
  test('arrival, departure and incomplete visit validate and persist',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final arrived = day(12, 21);
    await store.recordSiteArrival(
      vehicle: 'DT-07',
      site: 'Lekki Site',
      tripCode: 'TR-2048',
      now: arrived,
    );
    expect(store.openVisits.single.id, 'VIS-1');
    expect(store.visits.single.customer, 'Lekki Development');
    expect(store.visits.single.arrivedAt, arrived);
    expect(analytics(store).visits, isEmpty);
    await expectLater(
      store.recordSiteArrival(
        vehicle: 'DT-07',
        site: 'Apapa Terminal',
        tripCode: 'TR-2048',
        now: day(13),
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      store.recordSiteDeparture('VIS-1', day(12, 20)),
      throwsA(isA<FormatException>()),
    );
    await store.recordSiteDeparture('VIS-1', day(13, 1));
    expect(store.openVisits, isEmpty);
    expect(store.visits.single.isCompleted, isTrue);
    await expectLater(
      store.closeSiteVisitIncomplete('VIS-1', day(13, 2)),
      throwsA(isA<FormatException>()),
    );

    await store.recordSiteArrival(
      vehicle: 'DT-12',
      site: 'Apapa Terminal',
      tripCode: null,
      now: day(13, 10),
    );
    await store.closeSiteVisitIncomplete(
        'VIS-2',
        day(
          13,
          10,
        ));
    expect(store.visits.last.incomplete, isTrue);
    expect(store.visits.last.isCompleted, isFalse);

    final loaded = await DemoStore.load(persistence);
    addTearDown(loaded.dispose);
    expect(loaded.visits.length, 2);
    expect(loaded.visits.first.departedAt, day(13, 1));
    expect(loaded.visits.last.incomplete, isTrue);
    await loaded.reset();
    expect(loaded.visits, isEmpty);
    final afterReset = await DemoStore.load(persistence);
    addTearDown(afterReset.dispose);
    expect(afterReset.visits, isEmpty);
  });

  test(
      'invalid input, orphan links, corrupt visits and failed writes are explicit',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final snapshot = persistence.snapshot;
    await expectLater(
      store.recordSiteArrival(
        vehicle: 'bad',
        site: 'Lekki Site',
        tripCode: null,
        now: day(13),
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      store.recordSiteArrival(
        vehicle: 'DT-07',
        site: 'Unknown Site',
        tripCode: null,
        now: day(13),
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      store.recordSiteArrival(
        vehicle: 'DT-07',
        site: 'Lekki Site',
        tripCode: 'TR-2047',
        now: day(13),
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      store.recordSiteArrival(
        vehicle: 'DT-07',
        site: 'Lekki Site',
        tripCode: 'missing',
        now: day(13),
      ),
      throwsA(isA<FormatException>()),
    );
    persistence.failWrite = true;
    await expectLater(
      store.recordSiteArrival(
        vehicle: 'DT-07',
        site: 'Lekki Site',
        tripCode: null,
        now: day(13),
      ),
      throwsA(isA<PlatformException>()),
    );
    expect(store.visits, isEmpty);
    expect(persistence.snapshot, snapshot);

    persistence.failWrite = false;
    await store.recordSiteArrival(
      vehicle: 'DT-07',
      site: 'Lekki Site',
      tripCode: null,
      now: day(13),
    );
    final valid = jsonDecode(persistence.snapshot!) as Map<String, dynamic>;
    final visit = valid['visits'][0] as Map<String, dynamic>;
    for (final (field, value) in [
      ('site', 'unmapped'),
      ('customer', 'someone else'),
      ('arrivedAt', 'not a timestamp'),
      ('incomplete', true),
      ('departedAt', day(12).toIso8601String()),
    ]) {
      final changed = jsonDecode(persistence.snapshot!) as Map<String, dynamic>;
      changed['visits'][0][field] = value;
      persistence.snapshot = jsonEncode(changed);
      await expectLater(
        DemoStore.load(persistence),
        throwsA(isA<FormatException>()),
      );
    }
    visit['tripCode'] = 'missing';
    persistence.snapshot = jsonEncode(valid);
    await expectLater(
      DemoStore.load(persistence),
      throwsA(isA<FormatException>()),
    );
  });

  test('old snapshots without visits remain readable', () async {
    final persistence = TestPersistence();
    final saved = await DemoStore.load(persistence);
    addTearDown(saved.dispose);
    final old = jsonDecode(persistence.snapshot!) as Map<String, dynamic>
      ..remove('visits');
    persistence.snapshot = jsonEncode(old);
    final loaded = await DemoStore.load(persistence);
    addTearDown(loaded.dispose);
    expect(loaded.visits, isEmpty);
    expect(loaded.activeTrips.length, 2);
  });

  test('visit analytics uses arrival-day timezone, status, scope and dwell',
      () async {
    final store = await DemoStore.load(TestPersistence());
    addTearDown(store.dispose);
    await store.recordSiteArrival(
      vehicle: 'DT-07',
      site: 'Lekki Site',
      tripCode: 'TR-2048',
      now: DateTime.utc(2026, 11, 12, 23, 30),
    );
    await store.recordSiteDeparture('VIS-1', DateTime.utc(2026, 11, 13, 1, 30));
    await store.recordSiteArrival(
      vehicle: 'DT-12',
      site: 'Apapa Terminal',
      tripCode: null,
      now: day(13, 10),
    );
    await store.closeSiteVisitIncomplete('VIS-2', day(13, 10, 30));
    await store.recordSiteArrival(
      vehicle: 'DT-15',
      site: 'Lekki Site',
      tripCode: null,
      now: day(14),
    );

    final data = analytics(store);
    expect(data.visits.length, 2);
    expect(data.completed.length, 1);
    expect(data.incomplete.length, 1);
    expect(data.open, isEmpty);
    expect(data.uniqueVehicles, 2);
    expect(data.sitesServed, 2);
    expect(data.customersServed, 2);
    expect(data.totalDwellMinutes, 120);
    expect(data.averageDwellMinutes, 120);
    expect(data.onTrip, 1);
    expect(data.outsideTrip, 1);
    expect(data.visitsBySite, {'Lekki Site': 1, 'Apapa Terminal': 1});
    expect(data.completedDwellBySite['Lekki Site'], 120);
    expect(data.visitsByCustomer['Lekki Development'], 1);
    expect(
      data
          .dailyCounts(from: day(13), to: day(13))[DateTime.utc(2026, 11, 13)]!
          .visits,
      2,
    );
    expect(analytics(store, from: day(14), to: day(14)).visits.length, 1);
    expect(analytics(store, vehiclesOnly: true).visits.length, 2);
    expect(analytics(store, from: day(13), to: day(12)).visits, isEmpty);
  });

  testWidgets('record arrival, depart, and view filtered customer report',
      (tester) async {
    final store = await DemoStore.load(TestPersistence());
    addTearDown(store.dispose);
    await tester.pumpWidget(DumptrakPrototypeApp(store: store));
    await tapTab(tester, 'More');
    final vehicleDropdown = find.byKey(const ValueKey('visit-vehicle-DT-07'));
    await reveal(tester, vehicleDropdown);
    await tester.tap(vehicleDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DT-15').last);
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('record-site-arrival')));
    await tester.tap(find.byKey(const ValueKey('record-site-arrival')));
    await tester.pumpAndSettle();
    expect(store.visits.single.vehicle, 'DT-15');
    expect(store.visits.single.tripCode, isNull);
    expect(find.text('No open sample site visits.'), findsNothing);
    final departure = find.byKey(const ValueKey('depart-site-VIS-1'));
    await reveal(tester, departure);
    await tester.tap(departure);
    await tester.pumpAndSettle();
    expect(store.visits.single.isCompleted, isTrue);

    await tapTab(tester, 'More');
    final reports = find.byKey(const ValueKey('more-item-Reports'));
    await reveal(tester, reports, delta: -200);
    await tester
        .tap(find.descendant(of: reports, matching: find.text('Reports')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('report-section-Customer visits')));
    await tester.pumpAndSettle();
    final visitsMetric =
        find.byKey(const ValueKey('customer-metric-Completed visits'));
    await reveal(tester, visitsMetric);
    expect(tester.widget<Text>(visitsMetric).data, '1');
    await reveal(tester, find.byKey(const ValueKey('report-visit-VIS-1')));
    expect(find.text('DT-15 · Lekki Site'), findsOneWidget);
    expect(find.text('1 recorded sample arrivals · no live GPS evidence'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'customer visits data fits narrow screens and shows empty evidence',
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
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: ReportsPage(
          onBack: () {},
          trips: store.trips,
          alerts: store.alerts,
          visits: store.visits,
        ),
      ),
    ));
    await tester
        .tap(find.byKey(const ValueKey('report-section-Customer visits')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('visit-series-summary')));
    expect(find.text('0 recorded sample arrivals · no live GPS evidence'),
        findsOneWidget);
    final gaps =
        find.byKey(const ValueKey('customer-metric-GPS reporting gaps'));
    await reveal(tester, gaps, delta: -250);
    expect(tester.widget<Text>(gaps).data, 'Not evaluated');
    expect(tester.takeException(), isNull);
  });
}
