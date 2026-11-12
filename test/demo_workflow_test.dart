import 'package:dumptrak_mobile_prototype/demo_analytics.dart';
import 'package:dumptrak_mobile_prototype/demo_store.dart';
import 'package:dumptrak_mobile_prototype/demo_trip_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_store_test.dart' show TestPersistence;

void main() {
  test(
      'trip creation, progression, alert resolution, reports, reload and reset',
      () async {
    final persistence = TestPersistence();
    final store = await DemoStore.load(persistence);
    addTearDown(store.dispose);
    final now = DateTime.utc(2026, 11, 12, 12);

    final trip = await store.createTrip(const DemoTripDraft(
      project: 'Lekki development',
      origin: 'Ikeja Quarry',
      destination: 'Lekki Site',
      driver: 'Tunde Adeyemi',
      vehicle: 'DT-15',
      material: 'Sand',
    ));
    expect(store.activeTrips, hasLength(3));
    expect(trip.status, 'Planned');

    for (final expected in [
      'Dispatched',
      'At origin',
      'In transit',
      'Approaching',
      'Arrived',
      'Completed',
    ]) {
      await store.advanceTrip(trip.code, now);
      expect(store.tripByCode(trip.code).status, expected);
    }

    await store.resolveAlert(
      'alert-tracking',
      'Reviewed during the integrated demo',
      now,
    );
    final report = DemoAnalytics(
      trips: store.trips,
      alerts: store.alerts,
      now: now,
    );
    expect(report.completed, 1);
    expect(report.active, 2);
    expect(report.openAlerts, 1);
    expect(report.resolved, 1);

    final reopened = await DemoStore.load(persistence);
    addTearDown(reopened.dispose);
    final reopenedReport = DemoAnalytics(
      trips: reopened.trips,
      alerts: reopened.alerts,
      now: now,
    );
    expect(reopened.tripByCode(trip.code).status, 'Completed');
    expect(reopenedReport.completed, 1);
    expect(reopenedReport.openAlerts, 1);
    expect(reopenedReport.resolved, 1);

    await reopened.reset();
    final reset = await DemoStore.load(persistence);
    addTearDown(reset.dispose);
    expect(reset.trips, hasLength(2));
    expect(reset.trips.any((item) => item.code == trip.code), isFalse);
    expect(reset.openAlerts, hasLength(2));
    expect(reset.resolvedAlerts, isEmpty);
  });
}
