import 'demo_store.dart';
import 'demo_trip_catalog.dart';

enum DemoVehicleStatus {
  moving('Moving'),
  loading('Loading'),
  idle('Idle'),
  reportingGap('Reporting gap');

  const DemoVehicleStatus(this.label);
  final String label;
}

class DemoVehicle {
  const DemoVehicle({
    required this.id,
    required this.trip,
    required this.status,
    required this.routePosition,
    required this.location,
    required this.speed,
  });

  final String id;
  final Trip? trip;
  final DemoVehicleStatus status;
  final double routePosition;
  final String location;
  final int? speed;

  String get driver => trip?.driver ?? 'Not assigned in this sample';
  String get report => status == DemoVehicleStatus.reportingGap
      ? 'Simulated reporting gap · Last sample 42 minutes ago'
      : 'Sample position derived from saved trip stage · Not a GPS report';
}

List<DemoVehicle> demoFleet(DemoStore store) {
  return [
    for (final id in DemoTripCatalog.vehicles) _vehicle(store, id),
  ];
}

DemoVehicle _vehicle(DemoStore store, String id) {
  final active = store.trips.where((trip) => trip.vehicle == id && trip.isActive);
  final ended = store.trips.where(
      (trip) => trip.vehicle == id && trip.status == 'Completed');
  final trip =
      active.isNotEmpty ? active.first : ended.isNotEmpty ? ended.first : null;
  final gap = store.openAlerts.any(
    (alert) =>
        alert.kind == 'Tracking' &&
        store.trips.any(
            (trip) => trip.code == alert.tripCode && trip.vehicle == id),
  );
  final moving = trip != null &&
      ['In transit', 'Approaching'].contains(trip.status);
  final status = gap
      ? DemoVehicleStatus.reportingGap
      : trip?.status == 'At origin'
          ? DemoVehicleStatus.loading
          : moving
              ? DemoVehicleStatus.moving
              : DemoVehicleStatus.idle;
  final position = switch (trip?.status) {
    'In transit' => 0.5,
    'Approaching' => 0.8,
    'Arrived' || 'Completed' => 1.0,
    _ => 0.0,
  };
  final stops = trip?.route.split(' → ');
  final location = stops == null
      ? 'Demo depot'
      : position == 0
          ? 'Sample origin · ${stops.first}'
          : position == 1
              ? 'Sample destination · ${stops.last}'
              : 'Sample route · ${(position * 100).round()}% toward ${stops.last}';
  return DemoVehicle(
    id: id,
    trip: trip,
    status: status,
    routePosition: position,
    location: location,
    speed: gap ? null : moving ? (trip.status == 'Approaching' ? 24 : 42) : 0,
  );
}
