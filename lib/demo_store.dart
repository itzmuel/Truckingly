import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_trip_catalog.dart';

abstract interface class DemoPersistence {
  Future<String?> read();
  Future<void> write(String snapshot);
}

class LocalDemoPersistence implements DemoPersistence {
  static const key = 'dumptrak.demo.v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<String?> read() => _preferences.getString(key);

  @override
  Future<void> write(String snapshot) => _preferences.setString(key, snapshot);
}

class MemoryDemoPersistence implements DemoPersistence {
  String? snapshot;

  @override
  Future<String?> read() async => snapshot;

  @override
  Future<void> write(String snapshot) async => this.snapshot = snapshot;
}

class Trip {
  const Trip({
    required this.code,
    required this.vehicle,
    required this.route,
    required this.material,
    required this.status,
    required this.progress,
    required this.eta,
    this.completedAt,
    this.project,
    this.driver,
    this.events = const [],
  });

  static const statuses = [
    'Planned',
    'Dispatched',
    'At origin',
    'In transit',
    'Approaching',
    'Arrived',
    'Completed',
    'Exception',
    'Cancelled',
  ];
  static const journey = [
    'Planned',
    'Dispatched',
    'At origin',
    'In transit',
    'Approaching',
    'Arrived',
    'Completed',
  ];

  final String code;
  final String vehicle;
  final String route;
  final String material;
  final String status;
  final double progress;
  final String eta;
  final DateTime? completedAt;
  final String? project;
  final String? driver;
  final List<TripEvent> events;

  bool get isActive => status != 'Completed' && status != 'Cancelled';
  bool get canAdvance => journey.contains(status) && status != 'Completed';
  bool get canEdit => ['Planned', 'Dispatched', 'At origin'].contains(status);

  Trip advance(DateTime now) {
    if (!canAdvance) {
      throw StateError('Trip $code cannot advance from $status.');
    }
    final next = journey[journey.indexOf(status) + 1];
    return Trip(
      code: code,
      vehicle: vehicle,
      route: route,
      material: material,
      status: next,
      progress: next == 'Completed' ? 1 : journey.indexOf(next) / 6,
      eta: 'Simulated · $next',
      completedAt: next == 'Completed' ? now.toUtc() : null,
      project: project,
      driver: driver,
      events: List.unmodifiable([
        ...events,
        TripEvent(status: next, at: now.toUtc()),
      ]),
    );
  }

  Map<String, Object?> toJson() => {
        'code': code,
        'vehicle': vehicle,
        'route': route,
        'material': material,
        'status': status,
        'progress': progress,
        'eta': eta,
        'completedAt': completedAt?.toUtc().toIso8601String(),
        'project': project,
        'driver': driver,
        'events': events.map((event) => event.toJson()).toList(),
      };

  factory Trip.fromJson(Map<String, dynamic> json) {
    final status = _text(json, 'status');
    final progress = json['progress'];
    final timestamp = json['completedAt'];
    final completed = timestamp is String ? DateTime.tryParse(timestamp) : null;
    final project = json['project'] == null ? null : _text(json, 'project');
    final driver = json['driver'] == null ? null : _text(json, 'driver');
    if ((project == null) != (driver == null)) {
      throw const FormatException('Incomplete saved demo assignments.');
    }
    final rawEvents = json['events'];
    if (rawEvents != null && rawEvents is! List) {
      throw const FormatException('Invalid saved demo timeline.');
    }
    final events = <TripEvent>[];
    if (rawEvents is List) {
      for (final raw in rawEvents) {
        if (raw is! Map<String, dynamic>) {
          throw const FormatException('Invalid saved demo timeline event.');
        }
        events.add(TripEvent.fromJson(raw));
      }
    }
    if (events.isNotEmpty && events.last.status != status) {
      throw const FormatException('Timeline does not match trip status.');
    }
    if (!statuses.contains(status) ||
        progress is! num ||
        !progress.isFinite ||
        progress < 0 ||
        progress > 1 ||
        (timestamp != null && (completed == null || !completed.isUtc)) ||
        (status == 'Completed') != (completed != null)) {
      throw const FormatException('Invalid saved demo trip state.');
    }
    final trip = Trip(
      code: _text(json, 'code'),
      vehicle: _text(json, 'vehicle'),
      route: _text(json, 'route'),
      material: _text(json, 'material'),
      status: status,
      progress: progress.toDouble(),
      eta: _text(json, 'eta'),
      completedAt: completed,
      project: project,
      driver: driver,
      events: List.unmodifiable(events),
    );
    if (project != null && driver != null) {
      final stops = trip.route.split(' → ');
      if (stops.length != 2) {
        throw const FormatException('Invalid saved demo route.');
      }
      DemoTripDraft(
        project: project,
        origin: stops.first,
        destination: stops.last,
        driver: driver,
        vehicle: trip.vehicle,
        material: trip.material,
      ).validate();
    }
    return trip;
  }
}

class TripEvent {
  const TripEvent({required this.status, required this.at});

  final String status;
  final DateTime at;

  Map<String, Object?> toJson() =>
      {'status': status, 'at': at.toUtc().toIso8601String()};

  factory TripEvent.fromJson(Map<String, dynamic> json) {
    final status = _text(json, 'status');
    final at = DateTime.tryParse(_text(json, 'at'));
    if (!Trip.journey.contains(status) || at == null || !at.isUtc) {
      throw const FormatException('Invalid saved simulated timeline event.');
    }
    return TripEvent(status: status, at: at);
  }
}

class DemoAlert {
  const DemoAlert({
    required this.id,
    required this.tripCode,
    required this.kind,
    required this.title,
    required this.detail,
    required this.severity,
  });

  final String id;
  final String tripCode;
  final String kind;
  final String title;
  final String detail;
  final String severity;

  Map<String, Object?> toJson() => {
        'id': id,
        'tripCode': tripCode,
        'kind': kind,
        'title': title,
        'detail': detail,
        'severity': severity,
      };

  factory DemoAlert.fromJson(Map<String, dynamic> json) {
    final severity = _text(json, 'severity');
    if (!['Warning', 'Action'].contains(severity)) {
      throw const FormatException('Invalid saved demo alert severity.');
    }
    return DemoAlert(
      id: _text(json, 'id'),
      tripCode: _text(json, 'tripCode'),
      kind: _text(json, 'kind'),
      title: _text(json, 'title'),
      detail: _text(json, 'detail'),
      severity: severity,
    );
  }
}

String _text(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid saved demo field: $key.');
  }
  return value;
}

DateTime lagosDay(DateTime instant) {
  final local = instant.toUtc().add(const Duration(hours: 1));
  return DateTime.utc(local.year, local.month, local.day);
}

class DemoStore extends ChangeNotifier {
  DemoStore._(this.persistence, this._trips, this._alerts);

  factory DemoStore.memory() =>
      DemoStore._(MemoryDemoPersistence(), _seedTrips, _seedAlerts);

  final DemoPersistence persistence;
  List<Trip> _trips;
  List<DemoAlert> _alerts;
  bool _saving = false;

  List<Trip> get trips => List.unmodifiable(_trips);
  List<DemoAlert> get alerts => List.unmodifiable(_alerts);
  List<Trip> get activeTrips => trips.where((trip) => trip.isActive).toList();
  int get inTransit =>
      trips.where((trip) => trip.status == 'In transit').length;
  bool get saving => _saving;
  bool get canAdvance => trips.any((trip) => trip.canAdvance);

  int completedOn(DateTime day) => trips
      .where((trip) =>
          trip.completedAt != null &&
          lagosDay(trip.completedAt!) == lagosDay(day))
      .length;

  static Future<DemoStore> load(DemoPersistence persistence) async {
    final raw = await persistence.read();
    if (raw == null) {
      final store = DemoStore._(persistence, _seedTrips, _seedAlerts);
      await persistence.write(store._encode(store.trips, store.alerts));
      return store;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != 1 ||
        decoded['trips'] is! List ||
        decoded['alerts'] is! List) {
      throw const FormatException('Unsupported or invalid saved demo data.');
    }
    final trips = (decoded['trips'] as List).map((value) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid saved demo trip.');
      }
      return Trip.fromJson(value);
    }).toList();
    final alerts = (decoded['alerts'] as List).map((value) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid saved demo alert.');
      }
      return DemoAlert.fromJson(value);
    }).toList();
    final codes = trips.map((trip) => trip.code).toSet();
    if (codes.length != trips.length ||
        alerts.map((alert) => alert.id).toSet().length != alerts.length ||
        alerts.any((alert) => !codes.contains(alert.tripCode))) {
      throw const FormatException(
          'Saved demo records have invalid references.');
    }
    return DemoStore._(persistence, trips, alerts);
  }

  static Future<DemoStore> restore(DemoPersistence persistence) async {
    final store = DemoStore._(persistence, _seedTrips, _seedAlerts);
    await persistence.write(store._encode(store.trips, store.alerts));
    return store;
  }

  Future<void> reset() => _commit(_seedTrips, _seedAlerts);

  List<String> get availableVehicles => vehiclesFor(null);

  List<String> get availableDrivers => driversFor(null);

  List<String> vehiclesFor(String? tripCode) => DemoTripCatalog.vehicles
      .where((vehicle) => !activeTrips
          .any((trip) => trip.code != tripCode && trip.vehicle == vehicle))
      .toList();

  List<String> driversFor(String? tripCode) => DemoTripCatalog.drivers
      .where((driver) => !activeTrips
          .any((trip) => trip.code != tripCode && trip.driver == driver))
      .toList();

  Trip tripByCode(String code) {
    for (final trip in trips) {
      if (trip.code == code) return trip;
    }
    throw const FormatException('This demo trip no longer exists.');
  }

  void _validateAssignments(DemoTripDraft draft, {String? tripCode}) {
    draft.validate();
    if (!vehiclesFor(tripCode).contains(draft.vehicle)) {
      throw const FormatException(
          'This vehicle already has an active demo trip. Choose another.');
    }
    if (!driversFor(tripCode).contains(draft.driver)) {
      throw const FormatException(
          'This driver already has an active demo trip. Choose another.');
    }
  }

  Future<Trip> editTrip(String code, DemoTripDraft draft) async {
    final original = tripByCode(code);
    if (!original.canEdit) {
      throw const FormatException(
          'Assignments can only be edited before the demo trip leaves its origin.');
    }
    _validateAssignments(draft, tripCode: code);
    final updated = Trip(
      code: original.code,
      vehicle: draft.vehicle,
      route: '${draft.origin} → ${draft.destination}',
      material: draft.material,
      status: original.status,
      progress: original.progress,
      eta: original.eta,
      completedAt: original.completedAt,
      project: draft.project,
      driver: draft.driver,
      events: original.events,
    );
    await _commit(
        trips.map((trip) => trip.code == code ? updated : trip).toList(),
        alerts);
    return updated;
  }

  Future<void> advanceTrip(String code, DateTime now) async {
    final original = tripByCode(code);
    if (!original.canAdvance) {
      throw const FormatException('This demo trip cannot advance further.');
    }
    await _commit(
      trips
          .map((trip) => trip.code == code ? trip.advance(now) : trip)
          .toList(),
      alerts,
    );
  }

  Future<Trip> createTrip(DemoTripDraft draft) async {
    _validateAssignments(draft);
    var number = 2049;
    final codes = trips.map((trip) => trip.code).toSet();
    while (codes.contains('TR-$number')) {
      number++;
    }
    final trip = Trip(
      code: 'TR-$number',
      vehicle: draft.vehicle,
      route: '${draft.origin} → ${draft.destination}',
      material: draft.material,
      status: 'Planned',
      progress: 0,
      eta: 'Simulated · Planned',
      project: draft.project,
      driver: draft.driver,
      events: List.unmodifiable([
        TripEvent(status: 'Planned', at: DateTime.now().toUtc()),
      ]),
    );
    await _commit([trip, ...trips], alerts);
    return trip;
  }

  Future<void> advance(DateTime now) {
    if (!canAdvance) {
      throw StateError(
          'No demo trips can advance. Reset to run the demo again.');
    }
    return _commit(
      trips.map((trip) => trip.canAdvance ? trip.advance(now) : trip).toList(),
      alerts,
    );
  }

  Future<void> _commit(List<Trip> trips, List<DemoAlert> alerts) async {
    if (_saving) throw StateError('A demo save is already in progress.');
    _saving = true;
    notifyListeners();
    try {
      await persistence.write(_encode(trips, alerts));
      _trips = List.unmodifiable(trips);
      _alerts = List.unmodifiable(alerts);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  String _encode(List<Trip> trips, List<DemoAlert> alerts) => jsonEncode({
        'version': 1,
        'trips': trips.map((trip) => trip.toJson()).toList(),
        'alerts': alerts.map((alert) => alert.toJson()).toList(),
      });

  static const _seedTrips = [
    Trip(
      code: 'TR-2048',
      vehicle: 'DT-07',
      route: 'Ikeja Quarry → Lekki Site',
      material: 'Granite aggregate',
      status: 'In transit',
      progress: 0.64,
      eta: 'ETA 10:45 AM · Simulated',
    ),
    Trip(
      code: 'TR-2047',
      vehicle: 'DT-12',
      route: 'Ogun Yard → Apapa Terminal',
      material: 'Laterite',
      status: 'At origin',
      progress: 0.18,
      eta: 'Started 9:12 AM · Simulated',
    ),
  ];

  static const _seedAlerts = [
    DemoAlert(
      id: 'alert-tracking',
      tripCode: 'TR-2048',
      kind: 'Tracking',
      title: 'Vehicle reporting gap',
      detail:
          'DT-07 · TR-2048 · Simulated last report 42 minutes ago. Telemetry link needs review.',
      severity: 'Warning',
    ),
    DemoAlert(
      id: 'alert-delivery',
      tripCode: 'TR-2047',
      kind: 'Delivered quantity',
      title: 'Delivery confirmation needed',
      detail:
          'TR-2047 · Assign a site supervisor for delivery verification before departure. No delivery has been recorded.',
      severity: 'Action',
    ),
  ];
}
