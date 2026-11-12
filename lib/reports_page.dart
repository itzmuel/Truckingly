import 'package:flutter/material.dart';

import 'demo_store.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    super.key,
    required this.onBack,
    this.trips = const [],
    this.openAlerts = 0,
  });

  final VoidCallback onBack;
  final List<Trip> trips;
  final int openAlerts;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const _sections = [
    'Customer visits',
    'Maintenance',
    'Fleet assets and instruments',
    'Guided questions',
  ];
  late DateTime _from;
  late DateTime _to;
  String _scope = 'All tracked assets';
  String _section = 'Customer visits';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month - 1);
    _to = DateTime(now.year, now.month, 0);
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
                ChoiceChip(
                  key: ValueKey('report-section-$section'),
                  label: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: constraints.maxWidth - 72),
                    child: Text(section),
                  ),
                  selected: section == _section,
                  onSelected: (_) => setState(() => _section = section),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _panel(
          'Presentation prototype',
          const Text(
            'Empty sample report only. No live evidence has been read. '
            'Zero sample counts do not demonstrate complete coverage or normal fleet operation.',
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
                Text('Open alerts: ${widget.openAlerts}'),
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
        if (_section != 'Customer visits')
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

  List<Widget> _customerVisits() {
    const metrics = [
      ('Completed visits', '0', '0 visits in all'),
      ('Unique assets visiting', '0', 'Assets, not visits'),
      ('Sites served', '0', 'No sample sites visited'),
      ('Customers served', '0', 'Visits attributed to one customer'),
      ('Total dwell', '0 min', 'Completed visits only'),
      ('Average dwell', 'Unknown', 'No completed visit to average'),
      ('Open or incomplete', '0', '0 open · 0 incomplete'),
      (
        'Assets affected by reporting gaps',
        '0',
        'Sample count, not verified coverage'
      ),
      ('On a trip / outside a trip', '0 / 0', 'Sample visits'),
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
              'Both dates are included, using the company reporting timezone. '
              'Assets chooses every tracked asset or vehicles only.',
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
        ('Visits by site', 'No sample site was visited in this period.'),
        (
          'Completed dwell by site',
          'No completed sample dwell in this period.'
        ),
        (
          'Visits by customer',
          'No sample visit was attributed to one customer.'
        ),
        (
          'Asset and site activity',
          'No sample asset visited a site in this period.'
        ),
      ]) ...[
        _panel(summary.$1, Text(summary.$2)),
        const SizedBox(height: 12),
      ],
      _panel(
        'Visits over time',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Empty sample series · No live evidence'),
            const SizedBox(height: 12),
            Semantics(
              label:
                  'Sample visits and completed visits are zero for each of the $_days selected days. Live evidence is unavailable.',
              child: SizedBox(
                height: 130,
                child: CustomPaint(
                  painter: _EmptyVisitsPainter(
                    color: Theme.of(context).colorScheme.primary,
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
                    itemBuilder: (context, index) => _DailyVisitRow(
                      day: _date(DateTime.utc(
                          _from.year, _from.month, _from.day + index)),
                      visits: '0',
                      completed: '0',
                    ),
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
          child: const Column(
            children: [
              Icon(Icons.map_outlined, size: 36),
              SizedBox(height: 12),
              Text('No customer-site map connected',
                  textAlign: TextAlign.center),
              SizedBox(height: 8),
              Text(
                'Real site coordinates and a map provider are needed. '
                'No sample locations are presented as actual customer sites.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      _panel('Visits', const Text('No sample visit began in this period.')),
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
            _fact('Evidence as of', 'No evidence read'),
            _fact('Scope', _scope),
            _fact('Sources', 'None connected · Empty sample records'),
            const SizedBox(height: 8),
            const Text(
              'Coverage is not evaluated in this prototype. '
              'This report does not claim complete evidence for the period.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'VISIT_MERGE_GAP_SECONDS: provisional. The allowed unseen interval '
              'inside a site before a return counts as a new visit requires calibration against live geofence behaviour.',
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

class _EmptyVisitsPainter extends CustomPainter {
  const _EmptyVisitsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset.zero, Offset(0, size.height - 8), axis);
    canvas.drawLine(
        Offset(0, size.height - 8), Offset(size.width, size.height - 8), axis);
    final series = Paint()..color = color;
    for (var index = 0; index <= 12; index++) {
      canvas.drawCircle(
          Offset(size.width * index / 12, size.height - 8), 3, series);
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyVisitsPainter oldDelegate) =>
      oldDelegate.color != color;
}
