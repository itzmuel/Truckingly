import 'demo_store.dart';
import 'demo_trip_catalog.dart';

class DemoAnalytics {
  DemoAnalytics({
    required List<Trip> trips,
    required List<DemoAlert> alerts,
    required DateTime now,
    String? vehicle,
  })  : trips = List.unmodifiable(
            trips.where((trip) => vehicle == null || trip.vehicle == vehicle)),
        today = lagosDay(now) {
    final codes = this.trips.map((trip) => trip.code).toSet();
    this.alerts = List.unmodifiable(
        alerts.where((alert) => codes.contains(alert.tripCode)));
    vehicles = List.unmodifiable({
      ...DemoTripCatalog.vehicles,
      ...trips.map((trip) => trip.vehicle),
    }.where((name) => vehicle == null || name == vehicle));
  }

  final List<Trip> trips;
  late final List<DemoAlert> alerts;
  late final List<String> vehicles;
  final DateTime today;

  int get active => trips.where((trip) => trip.isActive).length;
  int get completed =>
      trips.where((trip) => trip.status == 'Completed').length;
  int get openAlerts => alerts.where((alert) => alert.isOpen).length;
  int get acknowledged =>
      alerts.where((alert) => alert.isOpen && alert.acknowledged).length;
  int get resolved => alerts.where((alert) => !alert.isOpen).length;

  Map<String, int> get statuses => {
        for (final status in Trip.statuses)
          status: trips.where((trip) => trip.status == status).length,
      };

  Map<String, int> get openAlertKinds => {
        for (final kind in alerts.map((alert) => alert.kind).toSet())
          kind: alerts
              .where((alert) => alert.isOpen && alert.kind == kind)
              .length,
      };

  Map<String, ({int active, int completed})> get workload => {
        for (final vehicle in vehicles)
          vehicle: (
            active: trips
                .where((trip) => trip.vehicle == vehicle && trip.isActive)
                .length,
            completed: trips
                .where((trip) =>
                    trip.vehicle == vehicle && trip.status == 'Completed')
                .length,
          ),
      };

  Map<DateTime, int> get dailyCompletions => {
        for (var daysAgo = 6; daysAgo >= 0; daysAgo--)
          today.subtract(Duration(days: daysAgo)): trips
              .where((trip) =>
                  trip.status == 'Completed' &&
                  trip.completedAt != null &&
                  lagosDay(trip.completedAt!) ==
                      today.subtract(Duration(days: daysAgo)))
              .length,
      };
}
