import 'package:flutter/material.dart';

import 'demo_store.dart';
import 'demo_analytics.dart';
import 'demo_visit_analytics.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    super.key,
    required this.onBack,
    this.trips = const [],
    this.alerts = const [],
    this.visits = const [],
    this.presentationCustomerVisitsKey,
    this.scrollController,
  });

  final VoidCallback onBack;
  final List<Trip> trips;
  final List<DemoAlert> alerts;
  final List<DemoSiteVisit> visits;
  final GlobalKey? presentationCustomerVisitsKey;
  final ScrollController? scrollController;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const _sections = [
    'Demo analytics',
    'Customer visits',
    'Maintenance',
    'Fleet assets and instruments',
    'Guided questions',
  ];
  late DateTime _from;
  late DateTime _to;
  String _scope = 'All tracked assets';
  String _section = 'Demo analytics';
  String? _vehicle;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month);
    _to = DateTime(now.year, now.month, now.day);
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String get _period => '${_date(_from)} to ${_date(_to)}';

  int get _days =>
      DateTime.utc(_to.year, _to.month, _to.day)
          .difference(DateTime.utc(_from.year, _from.month, _from.day))
          .inDays +
      1;

  Future<void> _pickDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? _from : _to,
      firstDate: start ? DateTime(2000) : _from,
      lastDate: start ? _to : DateTime(2100, 12, 31),
      helpText: start ? 'Report start date' : 'Report end date',
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        _from = selected;
      } else {
        _to = selected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('reports-scroll'),
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('More'),
          ),
        ),
        Text('Reports', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final section in _sections)
                KeyedSubtree(
                  key: section == 'Customer visits'
                      ? widget.presentationCustomerVisitsKey
                      : null,
                  child: ChoiceChip(
                    key: ValueKey('report-section-$section'),
                    label: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth - 72),
                      child: Text(section),
                    ),
                    selected: section == _section,
                    onSelected: (_) => setState(() => _section = section),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _panel(
          'DEMO / SIMULATED DATA',
          Text(
            _section == 'Demo analytics'
                ? 'Calculated from saved local demo trips and alerts. No live telemetry, '
                    'verified deliveries, or financial data is used.'
                : 'This report uses explicitly recorded simulated site events only. '
                    'No live GPS or geofence evidence is available. Zero sample counts do not demonstrate complete '
                    'coverage or normal fleet operation.',
          ),
        ),
        const SizedBox(height: 16),
        if (widget.trips.isNotEmpty) ...[
          _panel(
            'Shared demo operations',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active trips: ${widget.trips.where((trip) => trip.isActive).length}',
                  key: const ValueKey('report-active-trips'),
                ),
                const SizedBox(height: 8),
                Text(
                  'In transit: ${widget.trips.where((trip) => trip.status == 'In transit').length}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Completed trips: ${widget.trips.where((trip) => trip.status == 'Completed').length}',
                  key: const ValueKey('report-completed-trips'),
                ),
                const SizedBox(height: 8),
                Text(
                    'Open alerts: ${widget.alerts.where((alert) => alert.isOpen).length}'),
                const SizedBox(height: 12),
                const Text(
                  'SIMULATED DATA · All saved demo trips, independent of visit date filters. '
                  'These are trip counts, not geofence visits or verified deliveries.',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_section == 'Demo analytics')
          ..._demoAnalytics()
        else if (_section != 'Customer visits')
          _panel(
            _section,
            const Text(
              'This report is not connected in the prototype. '
              'The existing application or API is needed to load these records.',
            ),
          )
        else
          ..._customerVisits(),
      ],
    );
  }

  List<Widget> _demoAnalytics() {
    final now = DateTime.now();
    final all =
        DemoAnalytics(trips: widget.trips, alerts: widget.alerts, now: now);
    final report = DemoAnalytics(
      trips: widget.trips,
      alerts: widget.alerts,
      now: now,
      vehicle: _vehicle,
    );
    final daily = report.dailyCompletions;
    return [
      Text('Demo analytics', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text(
        'All saved records unless a chart states a time period. '
        'Vehicle scope applies to the analytics below, not the shared totals above '
        'or Customer visits filters.',
        style: TextStyle(fontSize: 12, height: 1.5),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        key: ValueKey('analytics-vehicle-${_vehicle ?? 'all'}'),
        initialValue: _vehicle ?? 'All vehicles',
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Demo vehicle scope'),
        items: [
          for (final name in ['All vehicles', ...all.vehicles])
            DropdownMenuItem(value: name, child: Text(name)),
        ],
        onChanged: (value) =>
            setState(() => _vehicle = value == 'All vehicles' ? null : value),
      ),
      const SizedBox(height: 12),
      Text(
        '${report.trips.length} saved ${report.trips.length == 1 ? 'trip' : 'trips'} · ${report.active} active · '
        '${report.completed} completed',
        key: const ValueKey('analytics-summary'),
      ),
      if (report.trips.isEmpty) ...[
        const SizedBox(height: 12),
        const Text(
            'No saved demo trips in this scope. Charts below show zero records.'),
      ],
      const SizedBox(height: 16),
      _panel(
        'Trips by current status',
        _countChart(report.statuses, 'status'),
      ),
      const SizedBox(height: 16),
      _panel(
        'Simulated completions · Last 7 days',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                '${_date(daily.keys.first)} to ${_date(daily.keys.last)} · Africa/Lagos (UTC+1)'),
            const SizedBox(height: 12),
            _countChart({
              for (final day in daily.entries) _date(day.key): day.value,
            }, 'completion'),
            const Text(
              'Counts recorded completion timestamps, including today. '
              'A simulated completion is not a verified delivery or a customer visit.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _panel(
        'Vehicle workload',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
                'Saved trip assignments, not utilization, distance, or driving hours.'),
            const SizedBox(height: 12),
            for (final entry in report.workload.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${entry.key}: ${entry.value.active} active · ${entry.value.completed} completed',
                  key: ValueKey('analytics-workload-${entry.key}'),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _panel(
        'Alert overview',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${report.openAlerts} open · ${report.acknowledged} acknowledged (still open) · '
              '${report.resolved} resolved',
              key: const ValueKey('analytics-alerts'),
            ),
            const SizedBox(height: 12),
            if (report.openAlerts == 0)
              const Text(
                  'No open demo alerts in this scope. This is not a safety assessment.')
            else
              _countChart(report.openAlertKinds, 'alert-kind'),
            const Text(
              'Includes alerts on completed trips. Only explicit demo resolution closes an alert.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _panel(
        'Analytics provenance',
        const Text(
          'Source: saved local demo snapshot. Charts refresh when saved records change. '
          'Reset Demo restores the original samples. No revenue, tonnage, dwell time, '
          'journey duration, or real-world fleet performance is inferred from sample stages.',
          style: TextStyle(height: 1.5),
        ),
      ),
    ];
  }

  Widget _countChart(Map<String, int> counts, String chart) {
    final maximum = counts.values.fold(0, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in counts.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Semantics(
              container: true,
              label: '${entry.key}: ${entry.value} records',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${entry.key}: ${entry.value}',
                      key: ValueKey('analytics-$chart-${entry.key}'),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: maximum == 0 ? 0 : entry.value / maximum,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _customerVisits() {
    final analytics = DemoVisitAnalytics(
      visits: widget.visits,
      from: _from,
      to: _to,
      vehiclesOnly: _scope == 'Vehicles only',
    );
    final daily = analytics.dailyCounts(from: _from, to: _to);
    final dailyEntries = daily.entries.toList(growable: false);
    final dwell = analytics.totalDwellMinutes;
    final average = analytics.averageDwellMinutes;
    String minutes(double value) => value < 60
        ? '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} min'
        : '${(value / 60).toStringAsFixed(1)} hr';
    final metrics = [
      (
        'Completed visits',
        '${analytics.completed.length}',
        'Explicit arrival and departure events'
      ),
      (
        'Unique assets visiting',
        '${analytics.uniqueVehicles}',
        'Sample vehicles, not visits'
      ),
      (
        'Sites served',
        '${analytics.sitesServed}',
        'Sample sites with recorded arrivals'
      ),
      (
        'Customers served',
        '${analytics.customersServed}',
        'Sample site-to-customer mapping'
      ),
      ('Total dwell', minutes(dwell), 'Completed visits only'),
      (
        'Average dwell',
        average == null ? 'Unknown' : minutes(average),
        'Completed visits only'
      ),
      (
        'Open visits',
        '${analytics.open.length}',
        'Arrival recorded; departure not recorded'
      ),
      (
        'Incomplete visits',
        '${analytics.incomplete.length}',
        'Explicitly closed as incomplete'
      ),
      ('GPS reporting gaps', 'Not evaluated', 'No GPS evidence is available'),
      (
        'On a trip / outside a trip',
        '${analytics.onTrip} / ${analytics.outsideTrip}',
        'Linked trips at arrival'
      ),
    ];

    return [
      Text(
        'Customer visits',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 6),
      Text(
        '$_period · Africa/Lagos',
        key: const ValueKey('report-period'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 16),
      _panel(
        'Report filters',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final controls = [
                  _dateButton(start: true),
                  _dateButton(start: false),
                ];
                if (constraints.maxWidth < 440) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      controls[0],
                      const SizedBox(height: 10),
                      controls[1]
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: controls[0]),
                    const SizedBox(width: 12),
                    Expanded(child: controls[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const ValueKey('report-assets'),
              initialValue: _scope,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Assets (required)'),
              items: [
                for (final scope in ['All tracked assets', 'Vehicles only'])
                  DropdownMenuItem(value: scope, child: Text(scope)),
              ],
              onChanged: (scope) {
                if (scope != null) setState(() => _scope = scope);
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Arrival date is included in the selected Africa/Lagos period. '
              'Scope filters the saved sample vehicle events.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 400 &&
                      MediaQuery.textScalerOf(context).scale(14) <= 18
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: width,
                  child: _panel(
                    metric.$1,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(metric.$2,
                            key: ValueKey('customer-metric-${metric.$1}'),
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 6),
                        Text(metric.$3,
                            style: const TextStyle(fontSize: 12, height: 1.4)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      for (final summary in [
        ('Visits by site', analytics.visitsBySite),
        ('Completed dwell by site (minutes)', analytics.completedDwellBySite),
        ('Visits by customer', analytics.visitsByCustomer),
      ]) ...[
        _panel(
          summary.$1,
          summary.$2.values.every((value) => value == 0)
              ? const Text('No recorded sample visits in this period.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in summary.$2.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('${entry.key}: ${entry.value}'),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
      ],
      _panel(
        'Asset and site activity',
        analytics.visits.isEmpty
            ? const Text('No recorded sample asset activity in this period.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final visit in analytics.visits)
                    ListTile(
                      key: ValueKey('report-visit-${visit.id}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text('${visit.vehicle} · ${visit.site}'),
                      subtitle: Text(
                        '${visit.customer} · ${visit.tripCode ?? 'Outside trip'}\n'
                        '${visit.incomplete ? 'Incomplete' : visit.isOpen ? 'Open' : 'Completed'} · '
                        '${_date(lagosDay(visit.arrivedAt))}',
                      ),
                      trailing: Text(
                        visit.isOpen
                            ? 'Open'
                            : visit.incomplete
                                ? 'Incomplete'
                                : minutes(visit.departedAt!
                                        .difference(visit.arrivedAt)
                                        .inSeconds /
                                    60),
                        textAlign: TextAlign.end,
                      ),
                    ),
                ],
              ),
      ),
      const SizedBox(height: 12),
      _panel(
        'Visits over time',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${analytics.visits.length} recorded sample arrivals · no live GPS evidence',
              key: const ValueKey('visit-series-summary'),
            ),
            const SizedBox(height: 12),
            Semantics(
              container: true,
              label:
                  'Recorded demo visits and completed visits from ${_date(_from)} to ${_date(_to)}.',
              child: SizedBox(
                height: 130,
                child: CustomPaint(
                  painter: _VisitActivityPainter(
                    color: Theme.of(context).colorScheme.primary,
                    counts: dailyEntries.map((entry) => entry.value).toList(),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(_date(_from),
                        style: const TextStyle(fontSize: 11))),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_date(_to),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 11))),
              ],
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              key: PageStorageKey('daily-visits-$_period'),
              tilePadding: EdgeInsets.zero,
              title: Text(
                  'Daily sample counts · $_days ${_days == 1 ? 'day' : 'days'}'),
              children: [
                const _DailyVisitRow(
                    day: 'Day', visits: 'Visits', completed: 'Completed'),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    key: PageStorageKey('daily-rows-$_period'),
                    itemCount: _days,
                    itemBuilder: (context, index) {
                      final entry = dailyEntries[index];
                      return _DailyVisitRow(
                        day: _date(entry.key),
                        visits: '${entry.value.visits}',
                        completed: '${entry.value.completed}',
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _panel(
        'Customer sites',
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(Icons.map_outlined, size: 36),
              const SizedBox(height: 12),
              Text(
                  analytics.visits.isEmpty
                      ? 'No sample visits to map in this period'
                      : 'Sample site names only · No coordinates',
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'The sample sites have no coordinates. This summary does not show real places.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      _panel(
        'Visits',
        Text(analytics.visits.isEmpty
            ? 'No sample visit began in this period.'
            : '${analytics.visits.length} sample visits began in this period.'),
      ),
      const SizedBox(height: 12),
      _panel(
        'Data quality and provenance',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'What this report read, how complete it was, and what was not evaluated.'),
            const SizedBox(height: 16),
            _fact('Period', _period),
            _fact('Time zone', 'Africa/Lagos'),
            _fact(
              'Evidence as of',
              analytics.visits.isEmpty
                  ? 'No sample visits recorded'
                  : 'Saved demo events only',
            ),
            _fact('Scope', _scope),
            _fact(
                'Sources', 'Locally saved simulated arrival/departure records'),
            const SizedBox(height: 8),
            const Text(
              'GPS coverage and unrecorded visits are not evaluated. '
              'This report includes only events explicitly entered in the local demo.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Each manually recorded arrival starts a separate visit. '
              'This demo does not merge or infer visits from location evidence.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      OutlinedButton(
        key: const ValueKey('report-export'),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Excel export is unavailable in this prototype. Connect the reporting API to download real reports.'),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(Icons.download_outlined),
              SizedBox(width: 10),
              Expanded(child: Text('Excel export · Not connected')),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _dateButton({required bool start}) {
    return OutlinedButton.icon(
      key: ValueKey(start ? 'report-from' : 'report-to'),
      onPressed: () => _pickDate(start: start),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.all(12),
      ),
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(
        '${start ? 'From' : 'To'} (required)\n${_date(start ? _from : _to)}',
      ),
    );
  }

  Widget _fact(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DailyVisitRow extends StatelessWidget {
  const _DailyVisitRow({
    required this.day,
    required this.visits,
    required this.completed,
  });

  final String day;
  final String visits;
  final String completed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
              flex: 2, child: Text(day, style: const TextStyle(fontSize: 12))),
          Expanded(
              child: Text(visits,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 2,
              child: Text(completed,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _VisitActivityPainter extends CustomPainter {
  const _VisitActivityPainter({required this.color, required this.counts});

  final Color color;
  final List<({int visits, int completed})> counts;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset.zero, Offset(0, size.height - 8), axis);
    canvas.drawLine(
        Offset(0, size.height - 8), Offset(size.width, size.height - 8), axis);
    final maximum = counts.fold<int>(
        0, (max, item) => item.visits > max ? item.visits : max);
    if (maximum == 0 || counts.isEmpty) return;
    final bucketCount = counts.length < 60 ? counts.length : 60;
    final bucketWidth = size.width / bucketCount;
    for (var bucket = 0; bucket < bucketCount; bucket++) {
      final start = bucket * counts.length ~/ bucketCount;
      final end = (bucket + 1) * counts.length ~/ bucketCount;
      final visits = counts
          .skip(start)
          .take(end - start)
          .fold<int>(0, (sum, item) => sum + item.visits);
      final completed = counts
          .skip(start)
          .take(end - start)
          .fold<int>(0, (sum, item) => sum + item.completed);
      final height = (size.height - 16) * visits / maximum;
      final rect = Rect.fromLTWH(
        bucket * bucketWidth + bucketWidth * 0.18,
        size.height - 8 - height,
        bucketWidth * 0.64,
        height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = color.withValues(alpha: 0.45),
      );
      if (completed > 0) {
        final completedHeight = (size.height - 16) * completed / maximum;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rect.left + rect.width * 0.3,
              size.height - 8 - completedHeight,
              rect.width * 0.4,
              completedHeight,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = Colors.greenAccent,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VisitActivityPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.counts != counts;
}
