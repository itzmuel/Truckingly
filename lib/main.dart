import 'package:flutter/material.dart';

import 'reports_page.dart';

const _blue = Color(0xFF1687F8);
const _background = Color(0xFF111210);
const _surface = Color(0xFF1D1E1C);
const _surfaceRaised = Color(0xFF282926);
const _border = Color(0xFF343632);
const _muted = Color(0xFF9A9D98);
const _green = Color(0xFF65D6A0);
const _amber = Color(0xFFFFC45C);

void main() {
  runApp(const DumptrakPrototypeApp());
}

class _NavItem {
  const _NavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _MoreItem {
  const _MoreItem(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}

class _SectionPreview {
  const _SectionPreview(this.icon, this.summary, this.status);

  final IconData icon;
  final String summary;
  final String status;
}

class DumptrakPrototypeApp extends StatelessWidget {
  const DumptrakPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _blue,
      brightness: Brightness.dark,
      surface: _surface,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dumptrak Mobile',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _background,
        appBarTheme: const AppBarTheme(
          backgroundColor: _background,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
        ),
      ),
      home: const OperationsShell(),
    );
  }
}

class OperationsShell extends StatefulWidget {
  const OperationsShell({super.key});

  @override
  State<OperationsShell> createState() => _OperationsShellState();
}

class _OperationsShellState extends State<OperationsShell> {
  int _tab = 0;
  String? _morePage;
  String _selectedTripStatus = 'All statuses';
  String _alertSection = 'Needs action';
  String _situationKind = 'All kinds';
  String _historyOutcome = 'All closed situations';
  int _intelligenceDays = 30;

  static const _alertSections = [
    'Needs action',
    'Earlier detections',
    'History',
    'Informational records',
  ];
  static const _situationKinds = [
    'All kinds',
    'Delivery progress',
    'Tracking',
    'Route and sites',
    'Delivered quantity',
    'Compliance',
    'Vehicle identity',
    'Vehicle condition (Intelligence)',
    'Maintenance',
    'ADAPTIQ Settlement',
    'Asset economics (FleetOps)',
  ];
  static const _historyOutcomes = [
    'All closed situations',
    'Superseded: the trip ended',
    'Closed by a person',
    'Cleared by new evidence',
    'Closed earlier, way not recorded',
  ];
  static const _sampleAlerts = [
    _SampleAlert(
      kind: 'Tracking',
      title: 'Vehicle reporting gap',
      detail: 'DT-03 · Last report 42 minutes ago · Current trip TR-2045',
      severity: 'Warning',
      icon: Icons.cell_tower_rounded,
    ),
    _SampleAlert(
      kind: 'Delivered quantity',
      title: 'Delivery confirmation needed',
      detail: 'TR-2046 · Waiting for a supervisor to confirm delivered tonnes',
      severity: 'Action',
      icon: Icons.fact_check_outlined,
    ),
  ];

  final List<Trip> _trips = [
    const Trip(
      code: 'TR-2048',
      vehicle: 'DT-07',
      route: 'Ikeja Quarry → Lekki Site',
      material: 'Granite aggregate',
      status: 'In transit',
      progress: 0.64,
      eta: 'ETA 10:45 AM',
    ),
    const Trip(
      code: 'TR-2047',
      vehicle: 'DT-12',
      route: 'Ogun Yard → Apapa Terminal',
      material: 'Laterite',
      status: 'At origin',
      progress: 0.18,
      eta: 'Started 9:12 AM',
    ),
  ];

  static const _tabs = <_NavItem>[
    _NavItem('Home', Icons.grid_view_rounded),
    _NavItem('Trips', Icons.alt_route_rounded),
    _NavItem('Map', Icons.map_outlined),
    _NavItem('Alerts', Icons.notifications_none_rounded),
    _NavItem('More', Icons.more_horiz_rounded),
  ];

  static const _tripStatuses = [
    'All statuses',
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

  List<Trip> get _visibleTrips {
    if (_selectedTripStatus == 'All statuses') return _trips;
    return _trips
        .where((trip) => trip.status == _selectedTripStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _tab == 0 && _morePage == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          if (_morePage != null) {
            _morePage = null;
          } else {
            _tab = 0;
          }
        });
      },
      child: Scaffold(
      appBar: AppBar(
        toolbarHeight: 62,
        titleSpacing: 20,
        title: Row(
          children: [
            const Icon(Icons.local_shipping_outlined, color: _blue, size: 23),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                'DUMPTRAK',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'DEMO',
              style: TextStyle(
                color: _blue,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildPage(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          setState(() {
            _tab = index;
            _morePage = null;
          });
        },
        destinations: [
          for (final item in _tabs)
            NavigationDestination(
              icon: Icon(item.icon),
              label: item.label,
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildPage() {
    if (_tab == 4 && _morePage != null) return _moreDetailPage();

    switch (_tab) {
      case 0:
        return _homePage();
      case 1:
        return _tripsPage();
      case 2:
        return _mapPage();
      case 3:
        return _alertsPage();
      default:
        return _morePageView();
    }
  }

  Widget _pageScroll(List<Widget> children) {
    return ListView(
      key: ValueKey('page-$_tab-${_morePage ?? 'main'}'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: children,
    );
  }

  Widget _homePage() {
    return _pageScroll([
      _pageHeading(
        'Operations overview',
        'Today · Africa/Lagos',
      ),
      const DemoNotice(),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: MetricCard(
              label: 'ACTIVE TRIPS',
              value: '${_trips.length}',
              icon: Icons.route_rounded,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: MetricCard(
              label: 'IN TRANSIT',
              value: '1',
              icon: Icons.local_shipping_outlined,
              accent: _blue,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Row(
        children: [
          Expanded(
            child: MetricCard(
              label: 'COMPLETED TODAY',
              value: '8',
              icon: Icons.task_alt_rounded,
              accent: _green,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: MetricCard(
              label: 'NEEDS ACTION',
              value: '2',
              icon: Icons.warning_amber_rounded,
              accent: _amber,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      SectionHeading(
        title: 'Needs your attention',
        action: TextButton(
          onPressed: () => setState(() => _tab = 3),
          child: const Text('View alerts'),
        ),
      ),
      const SizedBox(height: 10),
      const AlertCard(
        title: 'Vehicle reporting gap',
        detail: 'DT-03 has not reported for 42 minutes.',
        severity: 'Warning',
        icon: Icons.cell_tower_rounded,
      ),
      const SizedBox(height: 10),
      const AlertCard(
        title: 'Delivery confirmation needed',
        detail: 'TR-2046 is awaiting a site delivery check.',
        severity: 'Action',
        icon: Icons.fact_check_outlined,
      ),
      const SizedBox(height: 24),
      SectionHeading(
        title: 'Active trips',
        action: TextButton(
          onPressed: () => setState(() => _tab = 1),
          child: const Text('All trips'),
        ),
      ),
      const SizedBox(height: 10),
      for (final trip in _trips.take(2)) ...[
        TripCard(trip: trip),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 12),
      const PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(title: 'Fleet intelligence'),
            SizedBox(height: 10),
            Text(
              'Early view · sample data',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.insights_rounded, color: _blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '4 of 12 vehicles have a completed evaluation.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _tripsPage() {
    final visibleTrips = _visibleTrips;
    final tripCountLabel =
        visibleTrips.length == 1 ? '1 trip' : '${visibleTrips.length} trips';

    return _pageScroll([
      _pageHeading('Trips', 'Monitor material movement'),
      const DemoNotice(compact: true),
      const SizedBox(height: 14),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                key: const ValueKey('trip-status-filter'),
                initialValue: _selectedTripStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Trip status',
                  prefixIcon: Icon(Icons.filter_list_rounded),
                ),
                items: [
                  for (final status in _tripStatuses)
                    DropdownMenuItem(value: status, child: Text(status)),
                ],
                onChanged: (status) {
                  if (status != null) {
                    setState(() => _selectedTripStatus = status);
                  }
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Optional · Show only trips in one status.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _showCreateTrip,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New trip'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: _blue,
          foregroundColor: Colors.white,
        ),
      ),
      const SizedBox(height: 18),
      Text(
        _selectedTripStatus == 'All statuses'
            ? tripCountLabel
            : '$tripCountLabel · $_selectedTripStatus',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      if (visibleTrips.isEmpty)
        EmptyState(
          icon: Icons.alt_route_rounded,
          title: _trips.isEmpty ? 'No trips' : 'No trips in this status',
          detail: _trips.isEmpty
              ? 'Create your first trip to begin tracking material movement.'
              : 'No trips match "$_selectedTripStatus". Try another status or create a trip.',
        )
      else
        for (final trip in visibleTrips) ...[
          TripCard(trip: trip, showProgress: true),
          const SizedBox(height: 12),
        ],
      const SizedBox(height: 4),
      const Text(
        'Trip creation is stored on this device for the demo only.',
        style: TextStyle(color: _muted, fontSize: 12),
      ),
    ]);
  }

  Widget _mapPage() {
    return _pageScroll([
      _pageHeading('Live map', 'Fleet locations and trip activity'),
      const DemoNotice(compact: true),
      const SizedBox(height: 14),
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 330,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _DemoMapPainter()),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _background.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _border),
                  ),
                  child: const Text(
                    'DEMO MAP · NOT LIVE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 60,
                top: 105,
                child: MapVehiclePin(label: 'DT-07'),
              ),
              const Positioned(
                right: 56,
                bottom: 76,
                child: MapVehiclePin(label: 'DT-12'),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: Column(
                  children: [
                    _mapControl(Icons.add_rounded),
                    const SizedBox(height: 6),
                    _mapControl(Icons.remove_rounded),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                bottom: 15,
                child: Text(
                  'Illustrative route · Lagos',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
      const SectionHeading(title: 'Vehicles on active trips'),
      const SizedBox(height: 10),
      for (final trip in _trips) ...[
        TripCard(trip: trip),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 8),
      const Text(
        'Connect the production map and telemetry feed to show real vehicle locations.',
        style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
      ),
    ]);
  }

  Widget _mapControl(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: _background),
    );
  }

  Widget _alertsPage() {
    final visibleAlerts = _sampleAlerts
        .where((alert) =>
            _situationKind == 'All kinds' || alert.kind == _situationKind)
        .toList();
    final needsAction = _alertSection == 'Needs action';
    final isHistory = _alertSection == 'History';
    final explanation = switch (_alertSection) {
      'Needs action' =>
        'Current trips first, then completed work whose figures are held back for confirmation, then vehicle condition with no trip waiting. Within each group: critical, warning and information, then ungraded situations, then longest-waiting first. The order is provisional.\n\nDumptrak alerts, overdue maintenance positions and completion evidence refused by Settlement are included. FleetOps asset economics is shown to administrators only.',
      'Earlier detections' =>
        'Conditions found on an earlier day, with no evidence from today that they continue, and findings without an explanation Dumptrak can show. None is resolved: each stays open until closed or seen again today, when it returns to Needs action.',
      'History' =>
        'How each situation left the queue. Nothing here is deleted; a closed or superseded situation does not mean the vehicle is now fine.',
      _ =>
        'Completed deliveries, published documents and manual overrides. These records are kept for later questions and are never counted as work.',
    };

    return _pageScroll([
      _pageHeading(
        'Alerts',
        'Open situations, earlier detections and records kept alongside them.',
      ),
      const DemoNotice(compact: true),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final section in _alertSections)
            ChoiceChip(
              key: ValueKey('alert-section-$section'),
              label: Text(section),
              selected: _alertSection == section,
              onSelected: (_) => setState(() => _alertSection = section),
            ),
        ],
      ),
      const SizedBox(height: 16),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(title: _alertSection),
            const SizedBox(height: 6),
            Text(
              needsAction ? '${visibleAlerts.length} open sample situations' : '0 records',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            if (needsAction) ...[
              _alertFilter(
                filterKey: 'situation-kind-filter',
                label: 'Kind of situation (optional)',
                value: _situationKind,
                options: _situationKinds,
                onChanged: (value) => setState(() => _situationKind = value),
              ),
              const SizedBox(height: 8),
              const Text(
                'Shows one kind of situation, such as delivery progress or maintenance. Filtering preserves the queue order.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              if (visibleAlerts.isEmpty)
                const EmptyState(
                  icon: Icons.help_outline_rounded,
                  title: 'No situations match this kind',
                  detail: 'Try All kinds to see the sample action queue. Missing reports are not proof that vehicles are operating normally.',
                )
              else
                for (final alert in visibleAlerts) ...[
                  AlertCard(
                    title: alert.title,
                    detail: alert.detail,
                    severity: alert.severity,
                    icon: alert.icon,
                  ),
                  const SizedBox(height: 10),
                ],
            ] else ...[
              if (isHistory) ...[
                _alertFilter(
                  filterKey: 'history-outcome-filter',
                  label: 'How it left the queue (optional)',
                  value: _historyOutcome,
                  options: _historyOutcomes,
                  onChanged: (value) => setState(() => _historyOutcome = value),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Shows how situations left the queue: superseded when their trip ended, closed by a person, or cleared by new evidence.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                ),
                const ExpansionTile(
                  key: PageStorageKey('history-guidance'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'More about how it left the queue',
                    style: TextStyle(fontSize: 13),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Superseded situations concerned a trip that was completed or cancelled. Closed situations were dealt with by a person; this does not say the condition cleared. Cleared situations ended because evidence changed, such as a tracker reporting again or tonnes being confirmed. Closed earlier means the way it ended was not recorded.',
                        style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  isHistory && _historyOutcome != 'All closed situations'
                      ? 'Nothing recorded for "$_historyOutcome".'
                      : 'Nothing recorded here.',
                  style: const TextStyle(color: _muted),
                ),
              ),
            ],
            const Divider(color: _border, height: 28),
            Text(
              explanation,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _alertFilter({
    required String filterKey,
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey(filterKey),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(option, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }

  Widget _morePageView() {
    const items = <_MoreItem>[
      _MoreItem(
        'Compliance & documents',
        'Chain-of-custody records and generated PDFs',
        Icons.verified_user_outlined,
      ),
      _MoreItem(
        'Reports',
        'Customer visits, fleet activity and exports',
        Icons.bar_chart_rounded,
      ),
      _MoreItem(
        'Intelligence',
        'Fleet condition, trends and data quality',
        Icons.insights_rounded,
      ),
      _MoreItem(
        'Settlement',
        'Work offers and completion evidence',
        Icons.account_balance_wallet_outlined,
      ),
      _MoreItem(
        'FleetOps',
        'Vehicle movement and tracker activity',
        Icons.directions_car_filled_outlined,
      ),
    ];

    return _pageScroll([
      _pageHeading('More', 'Tools and account'),
      const DemoNotice(compact: true),
      const SizedBox(height: 16),
      for (final item in items) ...[
        Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            leading: Icon(item.icon, color: _blue),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                item.description,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
            onTap: () => setState(() => _morePage = item.title),
          ),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 12),
      const PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(title: 'Account'),
            SizedBox(height: 14),
            Text('Samuel Onyenwe',
                style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Gonimos · Operations', style: TextStyle(color: _muted)),
            SizedBox(height: 16),
            Text(
              'GEUTech sign-in linking is not connected in this prototype.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _moreDetailPage() {
    final title = _morePage!;
    if (title == 'Reports') {
      return ReportsPage(
        onBack: () => setState(() => _morePage = null),
      );
    }
    if (title == 'Intelligence') return _intelligencePage();
    if (title == 'Settlement' || title == 'FleetOps') {
      return _partnerPage(isSettlement: title == 'Settlement');
    }
    const previews = <String, _SectionPreview>{
      'Compliance & documents': _SectionPreview(
        Icons.verified_user_outlined,
        'Keep chain-of-custody records and generated trip documents together.',
        'No compliance records in this demo.',
      ),
    };
    final detail = previews[title] ??
        const _SectionPreview(
          Icons.info_outline_rounded,
          'This section is not available in the prototype.',
          'Sample presentation only',
        );

    return _pageScroll([
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _morePage = null),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('More'),
        ),
      ),
      const SizedBox(height: 8),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(detail.icon, size: 30, color: _blue),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              detail.summary,
              style: const TextStyle(color: _muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surfaceRaised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(detail.status, style: const TextStyle(color: _muted)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sample presentation only · Connect the existing application to load live records.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _pageHeading(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _partnerPage({required bool isSettlement}) {
    final service = isSettlement ? 'Settlement' : 'FleetOps';
    return _pageScroll([
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _morePage = null),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('More'),
        ),
      ),
      _pageHeading(
        'ADAPTIQ $service',
        isSettlement
            ? 'Work Offers to subcontractors and evidence of delivered work.'
            : 'Your fleet movement over the last 24 hours, measured from trackers.',
      ),
      const DemoNotice(compact: true),
      const SizedBox(height: 16),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isSettlement
                      ? Icons.storefront_outlined
                      : Icons.directions_car_filled_outlined,
                  color: _blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSettlement ? 'Work Offers' : 'Movement',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isSettlement) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE58A),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFCE7100), width: 4),
                  ),
                ),
                child: const Text(
                  'DEMO — NOT LEGALLY BINDING — NO FUNDS WILL MOVE',
                  style: TextStyle(
                    color: Color(0xFF302000),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Work Offers are not connected in this prototype. In the live system, your Settlement administrator registers ADAPTIQ-Dumptrak as a source through Work Offers administration. Nothing needs to change in Dumptrak.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              _partnerStatus('Last answer from Settlement', 'None yet'),
              _partnerStatus('Completion reports waiting to be sent', '0'),
              _partnerStatus('Held until a supervisor confirms the tonnes', '0'),
              _partnerStatus('Refused by Settlement', '0'),
              const SizedBox(height: 8),
              const Text(
                'Sample counts only, not live queue totals. In the live system, offer a trip as work from the trip itself.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
            ] else ...[
              const Text(
                'Reporting window · Last 24 hours',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vehicle · Movements · Time moving · Last movement',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              const EmptyState(
                icon: Icons.route_outlined,
                title: 'Movement data unavailable',
                detail:
                    'No tracker or FleetOps service is connected. Missing records do not mean vehicles have not moved.',
              ),
              const SizedBox(height: 12),
              const Text(
                'When connected, open a vehicle to review each movement in the reporting window.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeading(title: 'GEUTech sign-in'),
            const SizedBox(height: 12),
            Text(
              'ADAPTIQ $service uses GEUTech sign-in. In the live app, password users link their identity once: GEUTech verifies who you are, then Dumptrak asks for your password to confirm the link. After linking, sign in with GEUTech.',
              style: const TextStyle(color: _muted, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Not linked in this prototype. No credentials are requested or stored.',
              style: TextStyle(color: _amber, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: ValueKey('link-geutech-$service'),
              onPressed: () => _showIdentityLinkInfo(service),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Link my GEUTech sign-in',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _partnerStatus(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _showIdentityLinkInfo(String service) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('GEUTech linking is not connected'),
        content: Text(
          'This prototype cannot link your $service account. The production identity configuration and approved sign-in flow are needed. No account was linked and no credentials were requested.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _intelligencePage() {
    return _pageScroll([
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _morePage = null),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('More'),
        ),
      ),
      _pageHeading(
        'Intelligence workspace',
        'Fleet analytics, trends and reporting over the last $_intelligenceDays days.',
      ),
      const DemoNotice(compact: true),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
        key: const ValueKey('intelligence-period'),
        initialValue: _intelligenceDays,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Period (required)'),
        items: [
          for (final days in [7, 30, 90])
            DropdownMenuItem(value: days, child: Text('Last $days days')),
        ],
        onChanged: (days) {
          if (days != null) setState(() => _intelligenceDays = days);
        },
      ),
      const SizedBox(height: 8),
      const Text(
        'The period findings are listed for. Changing it updates the prototype view only.',
        style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
      ),
      const SizedBox(height: 20),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(title: 'Fleet condition'),
            const SizedBox(height: 8),
            Text(
              'Last $_intelligenceDays days · Coverage determines what may be concluded.',
              key: const ValueKey('intelligence-coverage-period'),
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Not evaluated',
              style: TextStyle(color: _amber, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'No fleet evidence is connected. A fleet condition score cannot be shown; missing evaluations do not mean the fleet is operating normally.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(title: 'Vehicles requiring attention'),
            SizedBox(height: 8),
            Text(
              'Ranking requires the existing server evaluation.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            SizedBox(height: 16),
            Text(
              'Not available',
              style: TextStyle(color: _amber, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'No completed evaluation is available for fuel, maintenance, utilization or telemetry confidence. Connect the evaluation service before showing a ranked vehicle list.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(title: 'Evaluation service'),
            const SizedBox(height: 12),
            _intelligenceUnavailable('evaluation'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(title: 'Analytic findings'),
            const SizedBox(height: 8),
            const Text(
              'Evidence for reporting and optimization. These never raise alerts and never appear in alert counts.',
              style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 14),
            _intelligenceUnavailable('analytic findings'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(title: 'Before drawing conclusions'),
            SizedBox(height: 10),
            Text(
              'Thresholds are provisional and have not been calibrated against operating data. Treat findings as indicative, not established fact.',
              style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => setState(() {
          _tab = 3;
          _morePage = null;
          _alertSection = 'Needs action';
        }),
        icon: const Icon(Icons.notifications_none_rounded),
        label: const Text('View situations needing action'),
      ),
    ]);
  }

  Widget _intelligenceUnavailable(String service) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5C58).withValues(alpha: 0.1),
        border: Border.all(color: const Color(0xFFFF5C58).withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5C58)),
          const SizedBox(height: 8),
          Text(
            'The $service service is not connected in this prototype.',
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: ValueKey('intelligence-retry-$service'),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cannot retry $service: no API is configured. No live request was made.',
                ),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateTrip() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (context) => const TripSetupSheet(),
    );
  }
}

class _SampleAlert {
  const _SampleAlert({
    required this.kind,
    required this.title,
    required this.detail,
    required this.severity,
    required this.icon,
  });

  final String kind;
  final String title;
  final String detail;
  final String severity;
  final IconData icon;
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
  });

  final String code;
  final String vehicle;
  final String route;
  final String material;
  final String status;
  final double progress;
  final String eta;
}

class TripSetupSheet extends StatelessWidget {
  const TripSetupSheet({super.key});

  static const _requirements = [
    _TripSetupRequirement(
      name: 'Project',
      isRequired: true,
      description:
          'Every trip belongs to a project. Assign a customer to it for portal visibility.',
    ),
    _TripSetupRequirement(
      name: 'Site',
      isRequired: true,
      description:
          'Add at least one site with coordinates and geofence radii. Destinations are chosen per trip.',
    ),
    _TripSetupRequirement(
      name: 'Driver',
      isRequired: false,
      description: 'Needed for a complete chain-of-custody record.',
    ),
    _TripSetupRequirement(
      name: 'Vehicle',
      isRequired: false,
      description: 'Needed for a complete chain-of-custody record.',
    ),
    _TripSetupRequirement(
      name: 'Telemetry device',
      isRequired: false,
      description: 'Required for live GPS tracking and automatic geofence detection.',
    ),
    _TripSetupRequirement(
      name: 'Material',
      isRequired: false,
      description:
          'Defines what is being hauled; load quantity is entered per trip.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 14),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: _amber),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Before you can create a trip',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                children: [
                  const _SetupBlockerNotice(),
                  const SizedBox(height: 12),
                  for (final requirement in _requirements)
                    _TripSetupRequirementTile(requirement: requirement),
                  const SizedBox(height: 8),
                  const Divider(color: _border),
                  const SizedBox(height: 10),
                  const Text(
                    'Ask your administrator to finish the required project and site setup. Recommended records can be added to improve trip tracking and chain-of-custody.',
                    style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripSetupRequirement {
  const _TripSetupRequirement({
    required this.name,
    required this.isRequired,
    required this.description,
  });

  final String name;
  final bool isRequired;
  final String description;
}

class _TripSetupRequirementTile extends StatelessWidget {
  const _TripSetupRequirementTile({required this.requirement});

  final _TripSetupRequirement requirement;

  @override
  Widget build(BuildContext context) {
    final color = requirement.isRequired ? const Color(0xFFFF5C58) : _amber;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.circle_outlined, size: 14, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${requirement.name}${requirement.isRequired ? ' (required)' : ' (recommended)'}',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  requirement.description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'Ask your admin',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupBlockerNotice extends StatelessWidget {
  const _SetupBlockerNotice();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF5C58);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 17),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Some required setup is missing. Trips need these before they can be created.',
              style: TextStyle(color: color, fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class DemoNotice extends StatelessWidget {
  const DemoNotice({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 11 : 14),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.09),
        border: Border.all(color: _blue.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _blue, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              compact
                  ? 'Prototype with sample data · Not connected to live operations'
                  : 'Presentation prototype. Sample records and actions are not connected to the live system.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = Colors.white,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: accent),
            const SizedBox(height: 13),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class PanelCard extends StatelessWidget {
  const PanelCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.title,
    required this.detail,
    required this.severity,
    required this.icon,
  });

  final String title;
  final String detail;
  final String severity;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = severity == 'Warning' ? _amber : _blue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StatusPill(label: severity, color: color),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, this.showProgress = false});

  final Trip trip;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final color = switch (trip.status) {
      'In transit' || 'Approaching' || 'Arrived' => _green,
      'At origin' || 'Exception' => _amber,
      _ => _blue,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  trip.code,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                StatusPill(label: trip.status, color: color),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_shipping_outlined,
                    color: _blue, size: 19),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    trip.route,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              '${trip.vehicle} · ${trip.material} · ${trip.eta}',
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.5),
            ),
            if (showProgress) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: trip.progress,
                  minHeight: 5,
                  backgroundColor: _surfaceRaised,
                  color: _blue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        children: [
          Icon(icon, color: _muted, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class MapVehiclePin extends StatelessWidget {
  const MapVehiclePin({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_shipping, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.location_on, color: _blue, size: 25),
      ],
    );
  }
}

class _DemoMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = const Color(0xFF202923));

    final terrainPaint = Paint()
      ..color = const Color(0xFF29352D)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 7; i++) {
      final top = (i * 61.0) % size.height;
      final left = (i * 79.0) % size.width;
      canvas.drawOval(
        Rect.fromLTWH(left - 30, top - 18, 110, 56),
        terrainPaint,
      );
    }

    final minorRoad = Paint()
      ..color = const Color(0xFF4A5149)
      ..strokeWidth = 2;
    for (var i = 0; i < 6; i++) {
      final path = Path()
        ..moveTo(-20, size.height * (i / 6))
        ..cubicTo(
          size.width * 0.28,
          size.height * ((i + 1) / 7),
          size.width * 0.7,
          size.height * ((i + 2) / 8),
          size.width + 20,
          size.height * ((i + 1) / 6),
        );
      canvas.drawPath(path, minorRoad);
    }

    final route = Path()
      ..moveTo(size.width * 0.16, size.height * 0.34)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.3,
        size.width * 0.55,
        size.height * 0.74,
        size.width * 0.82,
        size.height * 0.68,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = _blue
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final river = Path()
      ..moveTo(0, size.height * 0.82)
      ..cubicTo(
        size.width * 0.23,
        size.height * 0.68,
        size.width * 0.43,
        size.height * 1.08,
        size.width * 0.7,
        size.height * 0.85,
      )
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.72,
        size.width * 0.93,
        size.height * 0.9,
        size.width,
        size.height * 0.78,
      );
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF294350)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DemoMapPainter oldDelegate) => false;
}
