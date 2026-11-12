import 'demo_store.dart';
import 'demo_visit_catalog.dart';

class DemoVisitAnalytics {
  DemoVisitAnalytics({
    required List<DemoSiteVisit> visits,
    required DateTime from,
    required DateTime to,
    required bool vehiclesOnly,
  }) : visits = List.unmodifiable(visits.where((visit) {
          final day = lagosDay(visit.arrivedAt);
          final start = DateTime.utc(from.year, from.month, from.day);
          final end = DateTime.utc(to.year, to.month, to.day);
          return !day.isBefore(start) &&
              !day.isAfter(end) &&
              (!vehiclesOnly ||
                  DemoVisitCatalog.vehicles.contains(visit.vehicle));
        }));

  final List<DemoSiteVisit> visits;

  List<DemoSiteVisit> get completed =>
      visits.where((visit) => visit.isCompleted).toList();
  List<DemoSiteVisit> get open =>
      visits.where((visit) => visit.isOpen).toList();
  List<DemoSiteVisit> get incomplete =>
      visits.where((visit) => visit.incomplete).toList();

  int get uniqueVehicles => visits.map((visit) => visit.vehicle).toSet().length;
  int get sitesServed => visits.map((visit) => visit.site).toSet().length;
  int get customersServed =>
      visits.map((visit) => visit.customer).toSet().length;
  int get onTrip => visits.where((visit) => visit.tripCode != null).length;
  int get outsideTrip => visits.where((visit) => visit.tripCode == null).length;

  double _durationMinutes(DemoSiteVisit visit) =>
      visit.departedAt!.difference(visit.arrivedAt).inSeconds / 60;

  double get totalDwellMinutes =>
      completed.fold(0, (total, visit) => total + _durationMinutes(visit));
  double? get averageDwellMinutes =>
      completed.isEmpty ? null : totalDwellMinutes / completed.length;

  Map<String, int> get visitsBySite => {
        for (final site in DemoVisitCatalog.sites)
          site: visits.where((visit) => visit.site == site).length,
      };

  Map<String, double> get completedDwellBySite => {
        for (final site in DemoVisitCatalog.sites)
          site: completed
              .where((visit) => visit.site == site)
              .fold(0, (total, visit) => total + _durationMinutes(visit)),
      };

  Map<String, int> get visitsByCustomer => {
        for (final customer in DemoVisitCatalog.customers.values.toSet())
          customer: visits.where((visit) => visit.customer == customer).length,
      };

  Map<DateTime, ({int visits, int completed})> dailyCounts({
    required DateTime from,
    required DateTime to,
  }) {
    final start = DateTime.utc(from.year, from.month, from.day);
    final end = DateTime.utc(to.year, to.month, to.day);
    final grouped = <DateTime, ({int visits, int completed})>{};
    for (final visit in visits) {
      final day = lagosDay(visit.arrivedAt);
      final previous = grouped[day] ?? (visits: 0, completed: 0);
      grouped[day] = (
        visits: previous.visits + 1,
        completed: previous.completed + (visit.isCompleted ? 1 : 0),
      );
    }
    final counts = <DateTime, ({int visits, int completed})>{};
    for (var day = start; !day.isAfter(end); day = day.add(const Duration(days: 1))) {
      counts[day] = grouped[day] ?? (visits: 0, completed: 0);
    }
    return counts;
  }
}
