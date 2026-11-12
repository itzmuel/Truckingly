import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_trip_catalog.dart';
import 'demo_visit_catalog.dart';

enum DemoScenario {
  normal,
  delayedDelivery,
  vehicleIncident;

  String get label => switch (this) {
        normal => 'Normal operations',
        delayedDelivery => 'Delivery delay',
        vehicleIncident => 'Vehicle incident',
      };

  String get summary => switch (this) {
        normal =>
          'Two active trips: one in transit and one at origin, with sample action alerts.',
        delayedDelivery =>
          'A simulated late delivery adds a progress alert to the in-transit trip.',
        vehicleIncident =>
          'DT-07 is marked stopped in an exception state with a simulated vehicle alert.',
      };

  List<({String screen, String instruction})> get walkthrough => switch (this) {
        normal => const [
            (
              screen: 'Home',
              instruction: 'Review the shared operations snapshot.'
            ),
            (
              screen: 'Trips',
              instruction: 'Open a trip to review its journey.'
            ),
            (
              screen: 'Map',
              instruction: 'Inspect the schematic vehicle lanes.'
            ),
            (screen: 'Alerts', instruction: 'Manage a sample action alert.'),
            (
              screen: 'Reports',
              instruction: 'Compare the shared demo analytics.'
            ),
          ],
        delayedDelivery => const [
            (screen: 'Trips', instruction: 'Find the in-transit delivery.'),
            (
              screen: 'Alerts',
              instruction: 'Review the delayed-progress alert.'
            ),
            (
              screen: 'Map',
              instruction: 'See the stage-based vehicle position.'
            ),
            (
              screen: 'Reports',
              instruction:
                  'Review counts without inferring actual delay duration.'
            ),
          ],
        vehicleIncident => const [
            (
              screen: 'Map',
              instruction: 'Open DT-07 and inspect its demo status.'
            ),
            (
              screen: 'Alerts',
              instruction: 'Review the simulated vehicle alert.'
            ),
            (screen: 'Trips', instruction: 'Open the exception trip timeline.'),
            (
              screen: 'Reports',
              instruction: 'Compare current trip and alert totals.'
            ),
          ],
      };

  static DemoScenario parse(Object? value) {
    for (final scenario in values) {
      if (scenario.name == value) return scenario;
    }
    throw const FormatException('Invalid saved demo scenario.');
  }
}

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

  Trip copyWith({
    String? status,
    double? progress,
    String? eta,
    DateTime? completedAt,
    List<TripEvent>? events,
  }) =>
      Trip(
        code: code,
        vehicle: vehicle,
        route: route,
        material: material,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        eta: eta ?? this.eta,
        completedAt: completedAt ?? this.completedAt,
        project: project,
        driver: driver,
        events: events ?? this.events,
      );

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

class DemoSiteVisit {
  const DemoSiteVisit({
    required this.id,
    required this.vehicle,
    required this.site,
    required this.customer,
    required this.arrivedAt,
    this.tripCode,
    this.departedAt,
    this.incomplete = false,
  });

  final String id;
  final String vehicle;
  final String site;
  final String customer;
  final DateTime arrivedAt;
  final String? tripCode;
  final DateTime? departedAt;
  final bool incomplete;

  bool get isOpen => departedAt == null;
  bool get isCompleted => departedAt != null && !incomplete;

  DemoSiteVisit close(DateTime at, {bool incomplete = false}) =>
      DemoSiteVisit(
        id: id,
        vehicle: vehicle,
        site: site,
        customer: customer,
        arrivedAt: arrivedAt,
        tripCode: tripCode,
        departedAt: at.toUtc(),
        incomplete: incomplete,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'vehicle': vehicle,
        'site': site,
        'customer': customer,
        'tripCode': tripCode,
        'arrivedAt': arrivedAt.toUtc().toIso8601String(),
        'departedAt': departedAt?.toUtc().toIso8601String(),
        'incomplete': incomplete,
      };

  factory DemoSiteVisit.fromJson(Map<String, dynamic> json) {
    final id = _text(json, 'id');
    final vehicle = _text(json, 'vehicle');
    final site = _text(json, 'site');
    final customer = _text(json, 'customer');
    final tripCode = json['tripCode'];
    final arrivedAt = DateTime.tryParse(_text(json, 'arrivedAt'));
    final rawDeparted = json['departedAt'];
    final departedAt =
        rawDeparted is String ? DateTime.tryParse(rawDeparted) : null;
    final incomplete = json['incomplete'] ?? false;
    if (!DemoVisitCatalog.vehicles.contains(vehicle) ||
        !DemoVisitCatalog.sites.contains(site) ||
        customer != DemoVisitCatalog.customerFor(site) ||
        (tripCode != null &&
            (tripCode is! String || tripCode.trim().isEmpty)) ||
        arrivedAt == null ||
        !arrivedAt.isUtc ||
        (rawDeparted != null &&
            (departedAt == null ||
                !departedAt.isUtc ||
                departedAt.isBefore(arrivedAt))) ||
        incomplete is! bool ||
        (incomplete && departedAt == null)) {
      throw const FormatException('Invalid saved demo site visit.');
    }
    return DemoSiteVisit(
      id: id,
      vehicle: vehicle,
      site: site,
      customer: customer,
      tripCode: tripCode as String?,
      arrivedAt: arrivedAt,
      departedAt: departedAt,
      incomplete: incomplete,
    );
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
    this.acknowledged = false,
    this.supervisor,
    this.notes = const [],
    this.resolvedAt,
    this.resolution,
  });

  static const supervisors = ['Samuel Onyenwe', 'Ada Nwosu', 'Femi Adewale'];
  final String id;
  final String tripCode;
  final String kind;
  final String title;
  final String detail;
  final String severity;
  final bool acknowledged;
  final String? supervisor;
  final List<String> notes;
  final DateTime? resolvedAt;
  final String? resolution;
  bool get isOpen => resolvedAt == null;

  DemoAlert update({
    bool? acknowledged,
    String? supervisor,
    List<String>? notes,
    DateTime? resolvedAt,
    String? resolution,
  }) =>
      DemoAlert(
        id: id,
        tripCode: tripCode,
        kind: kind,
        title: title,
        detail: detail,
        severity: severity,
        acknowledged: acknowledged ?? this.acknowledged,
        supervisor: supervisor ?? this.supervisor,
        notes: notes ?? this.notes,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        resolution: resolution ?? this.resolution,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'tripCode': tripCode,
        'kind': kind,
        'title': title,
        'detail': detail,
        'severity': severity,
        'acknowledged': acknowledged,
        'supervisor': supervisor,
        'notes': notes,
        'resolvedAt': resolvedAt?.toUtc().toIso8601String(),
        'resolution': resolution,
      };

  factory DemoAlert.fromJson(Map<String, dynamic> json) {
    final severity = _text(json, 'severity');
    if (!['Warning', 'Action'].contains(severity)) {
      throw const FormatException('Invalid saved demo alert severity.');
    }
    final acknowledged = json['acknowledged'] ?? false;
    final supervisor = json['supervisor'];
    final notes = json['notes'] ?? <dynamic>[];
    final timestamp = json['resolvedAt'];
    final resolvedAt =
        timestamp is String ? DateTime.tryParse(timestamp) : null;
    final resolution = json['resolution'];
    if (acknowledged is! bool ||
        (supervisor != null && !supervisors.contains(supervisor)) ||
        notes is! List ||
        notes.any((note) =>
            note is! String || note.trim().isEmpty || note.length > 500) ||
        (timestamp != null && (resolvedAt == null || !resolvedAt.isUtc)) ||
        (resolvedAt != null &&
            (resolution is! String ||
                resolution.trim().isEmpty ||
                resolution.length > 500)) ||
        (resolvedAt == null && resolution != null)) {
      throw const FormatException('Invalid saved demo alert lifecycle.');
    }
    return DemoAlert(
      id: _text(json, 'id'),
      tripCode: _text(json, 'tripCode'),
      kind: _text(json, 'kind'),
      title: _text(json, 'title'),
      detail: _text(json, 'detail'),
      severity: severity,
      acknowledged: acknowledged,
      supervisor: supervisor as String?,
      notes: List<String>.unmodifiable(notes),
      resolvedAt: resolvedAt,
      resolution: resolution as String?,
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
  DemoStore._(this.persistence, this._trips, this._alerts,
      [this._scenario = DemoScenario.normal, this._visits = const []]);

  factory DemoStore.memory() =>
      DemoStore._(MemoryDemoPersistence(), _seedTrips, _seedAlerts);

  final DemoPersistence persistence;
  List<Trip> _trips;
  List<DemoAlert> _alerts;
  List<DemoSiteVisit> _visits;
  DemoScenario _scenario;
  bool _saving = false;

  List<Trip> get trips => List.unmodifiable(_trips);
  List<DemoAlert> get alerts => List.unmodifiable(_alerts);
  List<DemoAlert> get openAlerts =>
      alerts.where((alert) => alert.isOpen).toList();
  List<DemoAlert> get resolvedAlerts =>
      alerts.where((alert) => !alert.isOpen).toList();
  List<DemoSiteVisit> get visits => List.unmodifiable(_visits);
  List<DemoSiteVisit> get openVisits =>
      visits.where((visit) => visit.isOpen).toList();
  List<Trip> get activeTrips => trips.where((trip) => trip.isActive).toList();
  int get inTransit =>
      trips.where((trip) => trip.status == 'In transit').length;
  bool get saving => _saving;
  DemoScenario get scenario => _scenario;
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
    final scenario = decoded.containsKey('scenario')
        ? DemoScenario.parse(decoded['scenario'])
        : DemoScenario.normal;
    final rawVisits = decoded['visits'] ?? <dynamic>[];
    if (rawVisits is! List) {
      throw const FormatException('Invalid saved demo site visits.');
    }
    final visits = rawVisits.map((value) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid saved demo site visit.');
      }
      return DemoSiteVisit.fromJson(value);
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
        alerts.any((alert) => !codes.contains(alert.tripCode)) ||
        visits.map((visit) => visit.id).toSet().length != visits.length ||
        visits.any((visit) =>
            visit.tripCode != null && !codes.contains(visit.tripCode)) ||
        visits.where((visit) => visit.isOpen).map((visit) => visit.vehicle).toSet().length !=
            visits.where((visit) => visit.isOpen).length) {
      throw const FormatException(
          'Saved demo records have invalid references.');
    }
    return DemoStore._(persistence, trips, alerts, scenario, visits);
  }

  static Future<DemoStore> restore(DemoPersistence persistence) async {
    final store = DemoStore._(persistence, _seedTrips, _seedAlerts);
    await persistence.write(store._encode(store.trips, store.alerts));
    return store;
  }

  Future<void> reset() => loadScenario(DemoScenario.normal);

  Future<void> loadScenario(DemoScenario scenario) {
    final data = _scenarioData(scenario);
    return _commit(data.trips, data.alerts,
        scenario: scenario, visits: []);
  }

  Future<void> recordSiteArrival({
    required String vehicle,
    required String site,
    required String? tripCode,
    required DateTime now,
  }) async {
    if (!DemoVisitCatalog.vehicles.contains(vehicle)) {
      throw const FormatException('Choose a sample vehicle.');
    }
    final customer = DemoVisitCatalog.customerFor(site);
    if (_visits.any((visit) => visit.isOpen && visit.vehicle == vehicle)) {
      throw const FormatException(
          'This vehicle already has an open demo site visit.');
    }
    if (tripCode != null) {
      final trip = tripByCode(tripCode);
      if (trip.vehicle != vehicle) {
        throw const FormatException(
            'Choose an active demo trip assigned to this vehicle.');
      }
      if (!trip.isActive) {
        throw const FormatException('Only active demo trips can be linked.');
      }
    }
    var number = 1;
    final ids = visits.map((visit) => visit.id).toSet();
    while (ids.contains('VIS-$number')) {
      number++;
    }
    final visit = DemoSiteVisit(
      id: 'VIS-$number',
      vehicle: vehicle,
      site: site,
      customer: customer,
      tripCode: tripCode,
      arrivedAt: now.toUtc(),
    );
    await _commit(trips, alerts, visits: [...visits, visit]);
  }

  Future<void> recordSiteDeparture(String id, DateTime now) =>
      _closeSiteVisit(id, now);

  Future<void> closeSiteVisitIncomplete(String id, DateTime now) =>
      _closeSiteVisit(id, now, incomplete: true);

  Future<void> _closeSiteVisit(String id, DateTime now,
      {bool incomplete = false}) async {
    final index = _visits.indexWhere((visit) => visit.id == id);
    if (index < 0) throw const FormatException('Demo site visit not found.');
    final visit = _visits[index];
    if (!visit.isOpen) {
      throw const FormatException('This demo site visit is already closed.');
    }
    if (now.toUtc().isBefore(visit.arrivedAt)) {
      throw const FormatException(
          'Departure cannot be earlier than the recorded arrival.');
    }
    final updated = [...visits];
    updated[index] = visit.close(now, incomplete: incomplete);
    await _commit(trips, alerts, visits: updated);
  }

  static ({List<Trip> trips, List<DemoAlert> alerts}) _scenarioData(
      DemoScenario scenario) {
    if (scenario == DemoScenario.normal) {
      return (trips: _seedTrips, alerts: _seedAlerts);
    }
    final trips = [..._seedTrips];
    if (scenario == DemoScenario.delayedDelivery) {
      return (
        trips: List.unmodifiable([
          trips.first.copyWith(eta: 'Simulated · Running behind schedule'),
          ...trips.skip(1),
        ]),
        alerts: List.unmodifiable([
          ..._seedAlerts,
          const DemoAlert(
            id: 'alert-delay-demo',
            tripCode: 'TR-2048',
            kind: 'Delivery progress',
            title: 'Delivery running behind schedule',
            detail:
                'DT-07 · TR-2048 · Simulated delay for this walkthrough. No actual arrival time or delay duration is known.',
            severity: 'Warning',
          ),
        ]),
      );
    }
    return (
      trips: List.unmodifiable([
        trips.first.copyWith(
          status: 'Exception',
          progress: 0.64,
          eta: 'Simulated · Vehicle stopped',
          events: const [],
        ),
        ...trips.skip(1),
      ]),
      alerts: List.unmodifiable([
        ..._seedAlerts,
        const DemoAlert(
          id: 'alert-incident-demo',
          tripCode: 'TR-2048',
          kind: 'Vehicle condition (Intelligence)',
          title: 'Vehicle stopped · demo incident',
          detail:
              'DT-07 · TR-2048 · Simulated stopped state for this walkthrough. No real vehicle condition has been evaluated.',
          severity: 'Warning',
        ),
      ]),
    );
  }

  DemoAlert alertById(String id) {
    for (final alert in alerts) {
      if (alert.id == id) return alert;
    }
    throw const FormatException('This demo alert no longer exists.');
  }

  Future<void> _changeAlert(
      String id, DemoAlert Function(DemoAlert) change) async {
    final original = alertById(id);
    if (!original.isOpen) {
      throw const FormatException('Resolved demo alerts are read-only.');
    }
    final updated = change(original);
    await _commit(trips,
        alerts.map((alert) => alert.id == id ? updated : alert).toList());
  }

  Future<void> acknowledgeAlert(String id) =>
      _changeAlert(id, (alert) => alert.update(acknowledged: true));

  Future<void> assignAlert(String id, String supervisor) =>
      _changeAlert(id, (alert) {
        if (!DemoAlert.supervisors.contains(supervisor)) {
          throw const FormatException('Choose a sample supervisor.');
        }
        return alert.update(supervisor: supervisor);
      });

  String _validateNote(String text) {
    final note = text.trim();
    if (note.isEmpty || note.length > 500) {
      throw const FormatException('Enter between 1 and 500 characters.');
    }
    return note;
  }

  Future<void> addAlertNote(String id, String text) => _changeAlert(
      id,
      (alert) => alert.update(
            notes: List.unmodifiable([...alert.notes, _validateNote(text)]),
          ));

  Future<void> resolveAlert(String id, String reason, DateTime now) =>
      _changeAlert(
          id,
          (alert) => alert.update(
                resolvedAt: now.toUtc(),
                resolution: _validateNote(reason),
              ));

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

  Future<void> _commit(List<Trip> trips, List<DemoAlert> alerts,
      {DemoScenario? scenario, List<DemoSiteVisit>? visits}) async {
    if (_saving) throw StateError('A demo save is already in progress.');
    final savedScenario = scenario ?? _scenario;
    final savedVisits = visits ?? _visits;
    _saving = true;
    notifyListeners();
    try {
      await persistence
          .write(_encode(trips, alerts, savedScenario, savedVisits));
      _trips = List.unmodifiable(trips);
      _alerts = List.unmodifiable(alerts);
      _scenario = savedScenario;
      _visits = List.unmodifiable(savedVisits);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  String _encode(List<Trip> trips, List<DemoAlert> alerts,
          [DemoScenario? scenario, List<DemoSiteVisit>? visits]) =>
      jsonEncode({
        'version': 1,
        'scenario': (scenario ?? _scenario).name,
        'trips': trips.map((trip) => trip.toJson()).toList(),
        'alerts': alerts.map((alert) => alert.toJson()).toList(),
        'visits': (visits ?? _visits).map((visit) => visit.toJson()).toList(),
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
