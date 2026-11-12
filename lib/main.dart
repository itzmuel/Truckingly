import 'dart:async';

import 'package:flutter/material.dart';

import 'demo_director.dart';
import 'demo_store.dart';
import 'reports_page.dart';
import 'trip_wizard.dart';
import 'trip_details.dart';
import 'fleet_map_page.dart';
import 'alert_details.dart';
import 'demo_visit_catalog.dart';
import 'demo_touch_pointer.dart';

const _blue = Color(0xFF0088FF);
const _background = Color(0xFF080A0B);
const _surface = Color(0xFF171719);
const _surfaceRaised = Color(0xFF28282B);
const _border = Color(0xFF29292C);
const _muted = Color(0xFF9B9DA5);
const _green = Color(0xFF22C55E);
const _amber = Color(0xFFFFAA00);

void main() {
  runApp(const DemoStartup());
}

class DemoStartup extends StatefulWidget {
  const DemoStartup({super.key, this.persistence});

  final DemoPersistence? persistence;

  @override
  State<DemoStartup> createState() => _DemoStartupState();
}

class _DemoStartupState extends State<DemoStartup> {
  late final DemoPersistence _persistence =
      widget.persistence ?? LocalDemoPersistence();
  DemoStore? _store;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool restore = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final store = restore
          ? await DemoStore.restore(_persistence)
          : await DemoStore.load(_persistence);
      if (!mounted) {
        store.dispose();
        return;
      }
      setState(() => _store = store);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_store != null) return DumptrakPrototypeApp(store: _store);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _busy
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading saved demo…'),
                      ],
                    )
                  : Builder(
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Saved demo could not be loaded',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          Text(_error ?? 'Local storage is unavailable.'),
                          const SizedBox(height: 12),
                          const Text(
                            'Your saved demo has not been replaced. Retry, or explicitly restore the sample data.',
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Retry loading'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final reset = await _confirmDemoReset(context);
                              if (reset && mounted) {
                                await _load(restore: true);
                              }
                            },
                            child: const Text('Restore sample data'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmDemoReset(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset simulated data?'),
        content: const Text(
          'This replaces all saved demo changes on this device with the original sample records. No production data is affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset Demo'),
          ),
        ],
      ),
    ) ??
    false;

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

enum _DemoRole {
  administrator('Administrator', 'Ada Nwosu', 'Gonimos · Administration'),
  dispatcher('Dispatcher', 'Samuel Onyenwe', 'Gonimos · Operations'),
  supervisor('Supervisor', 'Femi Adewale', 'Gonimos · Site supervision'),
  driver('Driver', 'Ayo Bello', 'Gonimos · Fleet operations');

  const _DemoRole(this.label, this.name, this.organization);

  final String label;
  final String name;
  final String organization;
}

class DumptrakPrototypeApp extends StatelessWidget {
  const DumptrakPrototypeApp({super.key, this.store});

  final DemoStore? store;

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
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _border),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _surfaceRaised,
          selectedColor: _blue,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
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
      home: OperationsShell(store: store),
    );
  }
}

class OperationsShell extends StatefulWidget {
  const OperationsShell({super.key, this.store});

  final DemoStore? store;

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
  String _visitVehicle = 'DT-07';
  String _visitSite = 'Lekki Site';
  String? _visitTripCode;
  late final DemoStore _demo = widget.store ?? DemoStore.memory();
  _DemoRole _demoRole = _DemoRole.dispatcher;
  DemoScenario _scenarioChoice = DemoScenario.normal;
  DemoPresentationMode _presentationMode = DemoPresentationMode.guided;
  _DemoRole _presentationRole = _DemoRole.dispatcher;
  int _presentationLength = 5;
  int _presentationStep = 0;
  int _presentationSecondsRemaining = 0;
  bool _presentationActive = false;
  bool _presentationPlaying = false;
  bool _presentationActionInProgress = false;
  int _presentationTouchGeneration = 0;
  final GlobalKey<TripDetailsState> _presentationTripDetailsKey = GlobalKey();
  final GlobalKey<TripDetailsState> _presentationMapTripDetailsKey =
      GlobalKey();
  final GlobalKey<FleetMapPageState> _presentationMapPageKey = GlobalKey();
  final GlobalKey<AlertDetailsState> _presentationAlertDetailsKey = GlobalKey();
  final GlobalKey _presentationPrimaryTargetKey = GlobalKey();
  final GlobalKey _presentationSecondaryTargetKey = GlobalKey();
  final GlobalKey _presentationTertiaryTargetKey = GlobalKey();
  final GlobalKey _presentationFourthTargetKey = GlobalKey();
  final ScrollController _presentationHomeScrollController = ScrollController();
  final ScrollController _presentationTripsScrollController =
      ScrollController();
  final ScrollController _presentationMapScrollController = ScrollController();
  final ScrollController _presentationAlertsScrollController =
      ScrollController();
  final ScrollController _presentationReportsScrollController =
      ScrollController();
  final ScrollController _presentationDetailsScrollController =
      ScrollController();
  final ScrollController _presentationVehicleSheetScrollController =
      ScrollController();
  final Set<int> _completedPresentationActions = {};
  Timer? _presentationTimer;

  @override
  void initState() {
    super.initState();
    _scenarioChoice = _demo.scenario;
    _presentationRole = _demoRole;
    _demo.addListener(_refreshDemo);
  }

  void _refreshDemo() {
    if (!mounted) return;
    final activeTripCodes = _demo.activeTrips
        .where((trip) => trip.vehicle == _visitVehicle)
        .map((trip) => trip.code)
        .toSet();
    setState(() {
      if (_visitTripCode != null && !activeTripCodes.contains(_visitTripCode)) {
        _visitTripCode = null;
      }
    });
  }

  @override
  void dispose() {
    _presentationTimer?.cancel();
    _presentationHomeScrollController.dispose();
    _presentationTripsScrollController.dispose();
    _presentationMapScrollController.dispose();
    _presentationAlertsScrollController.dispose();
    _presentationReportsScrollController.dispose();
    _presentationDetailsScrollController.dispose();
    _presentationVehicleSheetScrollController.dispose();
    _demo.removeListener(_refreshDemo);
    if (widget.store == null) _demo.dispose();
    super.dispose();
  }

  List<Trip> get _trips => _demo.trips;
  Trip? get _presentationTrip {
    for (final trip in _demo.activeTrips) {
      if (trip.canAdvance) return trip;
    }
    return _demo.activeTrips.isEmpty ? null : _demo.activeTrips.first;
  }

  String get _presentationAlertId => switch (_demo.scenario) {
        DemoScenario.normal => 'alert-tracking',
        DemoScenario.delayedDelivery => 'alert-delay-demo',
        DemoScenario.vehicleIncident => 'alert-incident-demo',
      };

  String _presentationNarration(DemoPresentationStep step) {
    final focus = switch (_presentationRole) {
      _DemoRole.administrator =>
        'Administrator ${_presentationRole.name} oversees fleet-wide activity and operational reporting.',
      _DemoRole.dispatcher =>
        'Dispatcher ${_presentationRole.name} checks assignments and monitors trip progress.',
      _DemoRole.supervisor =>
        'Supervisor ${_presentationRole.name} reviews exceptions and coordinates alert follow-up.',
      _DemoRole.driver =>
        'Driver ${_presentationRole.name} follows an assigned journey and reports what the app records.',
    };
    return '$focus ${step.narration} Perspective is a demo lens, not access control.';
  }

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
  static const _tabs = <_NavItem>[
    _NavItem('Home', Icons.grid_view_rounded),
    _NavItem('Trips', Icons.alt_route_rounded),
    _NavItem('Map', Icons.map_outlined),
    _NavItem('Alerts', Icons.notifications_none_rounded),
    _NavItem('More', Icons.more_horiz_rounded),
  ];

  static const _tripStatuses = [
    'All statuses',
    ...Trip.statuses,
  ];

  List<Trip> get _visibleTrips {
    if (_selectedTripStatus == 'All statuses') return _trips;
    return _trips.where((trip) => trip.status == _selectedTripStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: !_presentationActive && _tab == 0 && _morePage == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_presentationActive) {
          _stopPresentation();
          return;
        }
        setState(() {
          if (_morePage == 'Walkthrough') {
            _tab = 0;
            _morePage = null;
          } else if (_morePage != null) {
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
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  'DUMPTRAK',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        letterSpacing: 0.6,
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
        bottomNavigationBar: _presentationActive
            ? null
            : _BottomTabs(
                selectedIndex: _tab,
                items: _tabs,
                onSelected: (index) {
                  setState(() {
                    _tab = index;
                    _morePage = null;
                  });
                },
              ),
      ),
    );
  }

  Widget _buildPage() {
    if (_presentationActive) return _presentationPage();
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

  Widget _pageScroll(
    List<Widget> children, {
    ScrollController? controller,
  }) {
    return ListView(
      key: ValueKey(
          'page-${_presentationActive ? _presentationStep : '$_tab-${_morePage ?? 'main'}'}'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
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
              value: '${_demo.activeTrips.length}',
              icon: Icons.route_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MetricCard(
              label: 'IN TRANSIT',
              value: '${_demo.inTransit}',
              icon: Icons.local_shipping_outlined,
              accent: _blue,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: MetricCard(
              label: 'COMPLETED TODAY',
              value: '${_demo.completedOn(DateTime.now())}',
              icon: Icons.task_alt_rounded,
              accent: _green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MetricCard(
              label: 'NEEDS ACTION',
              value: '${_demo.openAlerts.length}',
              icon: Icons.warning_amber_rounded,
              accent: _amber,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.present_to_all_rounded, color: _blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Stakeholder walkthrough',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Start a guided ${_demo.scenario.label.toLowerCase()} demo.',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const ValueKey('open-stakeholder-walkthrough'),
              onPressed: () => setState(() {
                _tab = 4;
                _morePage = 'Walkthrough';
              }),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Choose a walkthrough'),
            ),
          ],
        ),
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
      for (final alert in _demo.openAlerts) ...[
        AlertCard(
          title: alert.title,
          detail: alert.detail,
          severity: alert.severity,
          icon: _alertIcon(alert),
          onTap: () => _openAlert(alert.id),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 24),
      SectionHeading(
        title: 'Active trips',
        action: TextButton(
          onPressed: () => setState(() => _tab = 1),
          child: const Text('All trips'),
        ),
      ),
      const SizedBox(height: 10),
      if (_demo.activeTrips.isEmpty)
        const EmptyState(
          icon: Icons.task_alt_rounded,
          title: 'No active demo trips',
          detail: 'All simulated trips have ended. Reset Demo to start again.',
        ),
      for (final trip in _demo.activeTrips.take(2)) ...[
        KeyedSubtree(
          key: _presentationActive &&
                  _presentationStep == 0 &&
                  trip.code == _presentationTrip?.code
              ? _presentationPrimaryTargetKey
              : null,
          child: TripCard(trip: trip, onTap: () => _openTrip(trip.code)),
        ),
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
                    'Vehicle evaluations are not connected in this demo.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ], controller: _presentationHomeScrollController);
  }

  Widget _tripsPage() {
    final visibleTrips = _visibleTrips;
    final tripCountLabel =
        visibleTrips.length == 1 ? '1 trip' : '${visibleTrips.length} trips';

    return _pageScroll([
      _pageHeading('Trips', 'Monitor real-time material movement'),
      const DemoNotice(
        title: 'PROTOTYPE ENVIRONMENT',
        message:
            'Currently using sample data. Live operational connection is pending configuration.',
      ),
      const SizedBox(height: 18),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: KeyedSubtree(
              key: ValueKey('trip-filter-$_selectedTripStatus'),
              child: DropdownButtonFormField<String>(
                key: const ValueKey('trip-status-filter'),
                initialValue: _selectedTripStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Trip status',
                  fillColor: _surface,
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
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'New trip',
            onPressed: _showCreateTrip,
            style: IconButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(54, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      const SizedBox(height: 16),
      SectionHeading(
        title: 'DEMO TRIPS (${visibleTrips.length})',
        action: TextButton(
          onPressed: () => setState(() => _selectedTripStatus = 'Completed'),
          child: const Text('View Archive'),
        ),
      ),
      Text(tripCountLabel, style: const TextStyle(color: _muted, fontSize: 12)),
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
        for (var index = 0; index < visibleTrips.length; index++) ...[
          KeyedSubtree(
            key: _presentationActive &&
                    _presentationStep == 1 &&
                    visibleTrips[index].code == _presentationTrip?.code
                ? _presentationPrimaryTargetKey
                : null,
            child: TripCard(
              trip: visibleTrips[index],
              showProgress: true,
              onTap: () => _openTrip(visibleTrips[index].code),
            ),
          ),
          const SizedBox(height: 12),
        ],
      const SizedBox(height: 4),
      const Text(
        'Sample data only. Demo changes are saved on this device.\nCloud synchronization is not connected.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
      ),
    ], controller: _presentationTripsScrollController);
  }

  Widget _mapPage() {
    final isPresentationMap = _presentationActive && _presentationStep == 2;
    return FleetMapPage(
      key: isPresentationMap ? _presentationMapPageKey : null,
      store: _demo,
      presentationVehicleId:
          isPresentationMap ? _presentationTrip?.vehicle : null,
      presentationMarkerKey:
          isPresentationMap ? _presentationPrimaryTargetKey : null,
      presentationOpenTripKey:
          isPresentationMap ? _presentationSecondaryTargetKey : null,
      presentationBackKey:
          isPresentationMap ? _presentationFourthTargetKey : null,
      presentationTripDetailsKey:
          isPresentationMap ? _presentationMapTripDetailsKey : null,
      scrollController: _presentationMapScrollController,
      vehicleDetailsScrollController: _presentationVehicleSheetScrollController,
      tripDetailsScrollController: _presentationDetailsScrollController,
    );
  }

  Widget _alertsPage() {
    final visibleAlerts = _demo.openAlerts
        .where((alert) =>
            _situationKind == 'All kinds' || alert.kind == _situationKind)
        .toList();
    final needsAction = _alertSection == 'Needs action';
    final isHistory = _alertSection == 'History';
    final history = _historyOutcome == 'All closed situations' ||
            _historyOutcome == 'Closed by a person'
        ? _demo.resolvedAlerts
        : <DemoAlert>[];
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
        'Real-time incident detection & fleet status',
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final section in _alertSections)
            ChoiceChip(
              key: ValueKey('alert-section-$section'),
              showCheckmark: false,
              label: Text(switch (section) {
                'Needs action' => 'Needs Action (${_demo.openAlerts.length})',
                'Earlier detections' => 'Recent Detections',
                'History' => 'System History',
                _ => 'Info Records',
              }),
              selected: _alertSection == section,
              onSelected: (_) => setState(() => _alertSection = section),
            ),
        ],
      ),
      const SizedBox(height: 16),
      const DemoNotice(
        message:
            'Operating in simulation mode. All incidents are sample records and do not reflect real-time physical assets.',
        neutral: true,
      ),
      const SizedBox(height: 20),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: needsAction ? 'Pending Actions' : _alertSection,
            action: needsAction
                ? PopupMenuButton<String>(
                    key: const ValueKey('situation-kind-filter'),
                    tooltip: 'Filter incidents by kind',
                    initialValue: _situationKind,
                    onSelected: (value) =>
                        setState(() => _situationKind = value),
                    itemBuilder: (context) => [
                      for (final kind in _situationKinds)
                        PopupMenuItem(value: kind, child: Text(kind)),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _situationKind == 'All kinds'
                                ? 'All incidents'
                                : 'Filtered',
                            style: const TextStyle(color: _blue, fontSize: 12),
                          ),
                          const Icon(Icons.expand_more_rounded,
                              size: 16, color: _blue),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            needsAction
                ? '${visibleAlerts.length} open sample situations'
                : '${isHistory ? history.length : 0} records',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          if (needsAction) ...[
            if (_situationKind != 'All kinds') ...[
              Text('Kind: $_situationKind',
                  style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 12),
            ],
            if (visibleAlerts.isEmpty)
              const EmptyState(
                icon: Icons.help_outline_rounded,
                title: 'No situations match this kind',
                detail:
                    'Try All kinds to see the sample action queue. Missing reports are not proof that vehicles are operating normally.',
              )
            else
              for (final alert in visibleAlerts) ...[
                AlertCard(
                  key: ValueKey('alert-card-${alert.id}'),
                  title: alert.title,
                  detail: alert.detail,
                  severity: alert.severity,
                  icon: _alertIcon(alert),
                  reference:
                      '${_trips.firstWhere((trip) => trip.code == alert.tripCode).vehicle} · ${alert.tripCode}',
                  expanded: true,
                  presentationManageKey: _presentationActive &&
                          _presentationStep == 3 &&
                          alert.id == _presentationAlertId
                      ? _presentationPrimaryTargetKey
                      : null,
                  onAction: (_) => _openAlert(alert.id),
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
                      style:
                          TextStyle(color: _muted, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
            if (isHistory && history.isNotEmpty)
              for (final alert in history) ...[
                ListTile(
                  key: ValueKey('history-alert-${alert.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(alert.title),
                  subtitle: Text(
                    '${alert.tripCode} · Closed by a person\n${alert.resolution}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openAlert(alert.id),
                ),
                const SizedBox(height: 8),
              ]
            else
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
          const SizedBox(height: 8),
          PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UNDERSTANDING ALERTS',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Priority Flow: Critical safety hazards → Trip interruptions → Maintenance warnings → Informational telemetry updates.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
                ),
                const SizedBox(height: 12),
                Text(
                  explanation,
                  style:
                      const TextStyle(color: _muted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ], controller: _presentationAlertsScrollController);
  }

  void _openAlert(String id) {
    final isPresentationAlert = _presentationActive && _presentationStep == 3;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => AlertDetails(
          key: isPresentationAlert ? _presentationAlertDetailsKey : null,
          store: _demo,
          id: id,
          scrollController: _presentationDetailsScrollController,
          presentationAcknowledgeKey:
              isPresentationAlert ? _presentationSecondaryTargetKey : null,
          presentationBackKey:
              isPresentationAlert ? _presentationTertiaryTargetKey : null,
        ),
      ),
    );
  }

  IconData _alertIcon(DemoAlert alert) => alert.kind == 'Tracking'
      ? Icons.cell_tower_rounded
      : Icons.fact_check_outlined;

  Future<void> _saveDemo(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(
            'Demo could not be saved: $error. No changes were applied. Please retry.',
          ),
        ),
      );
    }
  }

  Future<void> _closeIncompleteVisit(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close this sample visit as incomplete?'),
        content: const Text(
          'This records an incomplete demo event. It does not report a real site departure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close incomplete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _saveDemo(
      () => _demo.closeSiteVisitIncomplete(id, DateTime.now()),
      'Sample visit closed as incomplete.',
    );
  }

  Future<void> _loadGuidedScenario() async {
    final scenario = _scenarioChoice;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Load ${scenario.label}?'),
        content: const Text(
          'This replaces the saved demo trips and alerts on this device with the selected sample scenario. This cannot be undone. Reset Demo restores the original samples. No production data is affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-load-guided-scenario'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Load scenario'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _saveDemo(() async {
      await _demo.loadScenario(scenario);
      if (!mounted) return;
      setState(() {
        _scenarioChoice = scenario;
        _selectedTripStatus = 'All statuses';
        _alertSection = 'Needs action';
        _situationKind = 'All kinds';
        _historyOutcome = 'All closed situations';
        _intelligenceDays = 30;
        _tab = 0;
        _morePage = null;
      });
    }, '${scenario.label} loaded and saved on this device.');
  }

  Future<void> _startPresentation() async {
    final scenario = _scenarioChoice;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start ${scenario.label}?'),
        content: const Text(
          'Starting replaces the saved demo trips, alerts, and visit events on this device with this fixed sample scenario. This cannot be undone. No production data is affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-start-presentation'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start presentation'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _presentationTimer?.cancel();
    var started = false;
    await _saveDemo(() async {
      await _demo.loadScenario(scenario);
      if (!mounted) return;
      setState(() {
        _presentationTouchGeneration++;
        _demoRole = _presentationRole;
        _selectedTripStatus = 'All statuses';
        _alertSection = 'Needs action';
        _situationKind = 'All kinds';
        _historyOutcome = 'All closed situations';
        _intelligenceDays = 30;
        _presentationStep = 0;
        _completedPresentationActions.clear();
        _presentationActionInProgress = false;
        _presentationSecondsRemaining =
            DemoPresentationStep.stepDuration(_presentationLength).inSeconds;
        _presentationActive = _presentationMode != DemoPresentationMode.explore;
        _presentationPlaying =
            _presentationMode == DemoPresentationMode.autoplay;
        _tab = _presentationMode == DemoPresentationMode.explore ? 0 : 4;
        _morePage = _presentationMode == DemoPresentationMode.explore
            ? null
            : 'Presentation';
      });
      started = true;
      if (_presentationPlaying) _armPresentationTimer();
    }, '${scenario.label} presentation started with locally saved sample data.');
    if (started && _presentationMode != DemoPresentationMode.explore) {
      _schedulePresentationActions(0);
    }
  }

  void _armPresentationTimer() {
    _presentationTimer?.cancel();
    if (!_presentationActive ||
        !_presentationPlaying ||
        _presentationMode != DemoPresentationMode.autoplay) {
      return;
    }
    _presentationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_presentationActive || !_presentationPlaying) {
        timer.cancel();
        return;
      }
      if (_presentationSecondsRemaining > 1) {
        setState(() => _presentationSecondsRemaining--);
        return;
      }
      timer.cancel();
      if (_presentationStep >= DemoPresentationStep.sequence.length - 1) {
        setState(() {
          _presentationSecondsRemaining = 0;
          _presentationPlaying = false;
        });
        return;
      }
      unawaited(_completePresentationStep());
    });
  }

  Future<void> _completePresentationStep() async {
    if (_presentationActionInProgress || !_presentationActive) return;
    final completedStep = _presentationStep;
    if (completedStep >= DemoPresentationStep.sequence.length - 1) return;
    _presentationTimer?.cancel();
    if (!_completedPresentationActions.contains(completedStep)) {
      await _demonstratePresentationStep(completedStep);
      if (!mounted ||
          !_presentationActive ||
          !_completedPresentationActions.contains(completedStep)) {
        return;
      }
    }
    setState(() {
      _presentationStep++;
      _presentationSecondsRemaining =
          DemoPresentationStep.stepDuration(_presentationLength).inSeconds;
    });
    if (_presentationPlaying) _armPresentationTimer();
    _schedulePresentationActions(_presentationStep);
  }

  void _schedulePresentationActions(int step) {
    final generation = _presentationTouchGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_presentationActive ||
          _presentationMode == DemoPresentationMode.explore ||
          generation != _presentationTouchGeneration ||
          step != _presentationStep) {
        return;
      }
      unawaited(_demonstratePresentationStep(step));
    });
  }

  Future<void> _performPresentationAction(
    GlobalKey target,
    String label,
    int generation, {
    Future<void> Function()? onActivate,
    ScrollController? scrollController,
  }) async {
    bool canContinue() =>
        mounted &&
        _presentationActive &&
        generation == _presentationTouchGeneration;
    if (!canContinue()) return;
    await DemoTouchPointer.showAndActivate(
      context,
      target,
      label: label,
      onActivate: onActivate,
      scrollController: scrollController,
      shouldContinue: canContinue,
    );
    if (!canContinue()) return;
  }

  Future<void> _waitForDemoSave(int generation) async {
    while (_demo.saving &&
        mounted &&
        _presentationActive &&
        generation == _presentationTouchGeneration) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
  }

  Future<void> _demonstratePresentationStep(int step) async {
    if (!_presentationActive ||
        _presentationMode == DemoPresentationMode.explore ||
        _presentationActionInProgress ||
        _completedPresentationActions.contains(step)) {
      return;
    }
    final generation = _presentationTouchGeneration;
    setState(() => _presentationActionInProgress = true);
    try {
      switch (step) {
        case 0:
          final trip = _presentationTrip;
          if (trip == null || !trip.canAdvance) {
            throw StateError(
                'The selected demo scenario has no active trip to advance.');
          }
          await _performPresentationAction(
              _presentationPrimaryTargetKey, 'Open trip', generation,
              onActivate: () async => _openTrip(trip.code),
              scrollController: _presentationHomeScrollController);
          await _performPresentationAction(
              _presentationSecondaryTargetKey, 'Advance stage', generation,
              onActivate: () async {
            final details = _presentationTripDetailsKey.currentState;
            if (details == null) {
              throw StateError(
                  'The presentation trip details are unavailable.');
            }
            await details.advanceForPresentation();
          }, scrollController: _presentationDetailsScrollController);
          await _waitForDemoSave(generation);
          if (generation == _presentationTouchGeneration &&
              _demo.trips.firstWhere((item) => item.code == trip.code).status ==
                  trip.status) {
            throw StateError('The simulated trip stage did not change.');
          }
          await _performPresentationAction(
            _presentationTertiaryTargetKey,
            'Back to overview',
            generation,
            onActivate: () async {
              final details = _presentationTripDetailsKey.currentState;
              if (details == null) {
                throw StateError(
                    'The presentation trip details are unavailable.');
              }
              details.backForPresentation();
            },
          );
        case 1:
          await _performPresentationAction(
              _presentationPrimaryTargetKey, 'Inspect trip', generation,
              onActivate: () async {
            final trip = _presentationTrip;
            if (trip == null) {
              throw StateError('The presentation trip is unavailable.');
            }
            _openTrip(trip.code);
          }, scrollController: _presentationTripsScrollController);
          await _performPresentationAction(
            _presentationSecondaryTargetKey,
            'Back to trips',
            generation,
            onActivate: () async {
              final details = _presentationTripDetailsKey.currentState;
              if (details == null) {
                throw StateError(
                    'The presentation trip details are unavailable.');
              }
              details.backForPresentation();
            },
          );
        case 2:
          await _performPresentationAction(
              _presentationPrimaryTargetKey, 'Open vehicle', generation,
              onActivate: () async {
            final map = _presentationMapPageKey.currentState;
            if (map == null) {
              throw StateError('The presentation fleet map is unavailable.');
            }
            map.openVehicleForPresentation();
          }, scrollController: _presentationMapScrollController);
          await _performPresentationAction(
              _presentationSecondaryTargetKey, 'Open assigned trip', generation,
              onActivate: () async {
            final map = _presentationMapPageKey.currentState;
            if (map == null) {
              throw StateError('The presentation fleet map is unavailable.');
            }
            map.openAssignedTripForPresentation();
          }, scrollController: _presentationVehicleSheetScrollController);
          await _performPresentationAction(
            _presentationFourthTargetKey,
            'Back to map',
            generation,
            onActivate: () async {
              final map = _presentationMapPageKey.currentState;
              if (map == null) {
                throw StateError('The presentation fleet map is unavailable.');
              }
              map.backFromTripForPresentation();
            },
          );
        case 3:
          final alert = _demo.alertById(_presentationAlertId);
          await _performPresentationAction(
              _presentationPrimaryTargetKey, 'Review alert', generation,
              onActivate: () async => _openAlert(alert.id),
              scrollController: _presentationAlertsScrollController);
          if (_presentationRole != _DemoRole.driver &&
              alert.isOpen &&
              !alert.acknowledged) {
            await _performPresentationAction(
                _presentationSecondaryTargetKey, 'Acknowledge', generation,
                onActivate: () async {
              final details = _presentationAlertDetailsKey.currentState;
              if (details == null) {
                throw StateError(
                    'The presentation alert details are unavailable.');
              }
              await details.acknowledgeForPresentation();
            }, scrollController: _presentationDetailsScrollController);
            await _waitForDemoSave(generation);
            if (generation == _presentationTouchGeneration &&
                !_demo.alertById(alert.id).acknowledged) {
              throw StateError('The demo alert was not acknowledged.');
            }
          }
          await _performPresentationAction(
            _presentationTertiaryTargetKey,
            'Back to alerts',
            generation,
            onActivate: () async {
              final details = _presentationAlertDetailsKey.currentState;
              if (details == null) {
                throw StateError(
                    'The presentation alert details are unavailable.');
              }
              details.backForPresentation();
            },
          );
        case 4:
          await _performPresentationAction(_presentationPrimaryTargetKey,
              'Open customer visits report', generation,
              scrollController: _presentationReportsScrollController);
      }
      if (mounted &&
          _presentationActive &&
          generation == _presentationTouchGeneration) {
        _completedPresentationActions.add(step);
      }
    } on StateError catch (error) {
      _showPresentationActionError(error);
    } on Exception catch (error) {
      _showPresentationActionError(error);
    } finally {
      if (mounted && generation == _presentationTouchGeneration) {
        setState(() => _presentationActionInProgress = false);
      }
    }
  }

  void _showPresentationActionError(Object error) {
    if (!mounted) return;
    setState(() => _presentationPlaying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Text(
          'Demo Director could not perform this simulated interaction: $error. No step was skipped; retry or stop the presentation.',
        ),
      ),
    );
  }

  void _setPresentationPlaying(bool playing) {
    if (!_presentationActive ||
        _presentationMode != DemoPresentationMode.autoplay) {
      return;
    }
    _presentationTimer?.cancel();
    setState(() => _presentationPlaying = playing);
    if (playing) _armPresentationTimer();
  }

  void _jumpPresentationTo(int index) {
    if (index < 0 || index >= DemoPresentationStep.sequence.length) return;
    _presentationTimer?.cancel();
    _presentationTouchGeneration++;
    setState(() {
      _presentationActionInProgress = false;
      _presentationStep = index;
      _presentationSecondsRemaining =
          DemoPresentationStep.stepDuration(_presentationLength).inSeconds;
      if (_presentationMode == DemoPresentationMode.autoplay &&
          index == DemoPresentationStep.sequence.length - 1) {
        _presentationPlaying = false;
      }
    });
    if (_presentationPlaying) _armPresentationTimer();
    _schedulePresentationActions(index);
  }

  void _stopPresentation() {
    _presentationTimer?.cancel();
    _presentationTouchGeneration++;
    setState(() {
      _presentationActive = false;
      _presentationPlaying = false;
      _presentationActionInProgress = false;
      _tab = 0;
      _morePage = null;
    });
  }

  String _presentationTimeLabel() {
    final minutes = _presentationSecondsRemaining ~/ 60;
    final seconds = _presentationSecondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _presentationScreenContent() {
    final screen = DemoPresentationStep.sequence[_presentationStep].screen;
    return switch (screen) {
      'Home' => _homePage(),
      'Trips' => _tripsPage(),
      'Map' => _mapPage(),
      'Alerts' => _alertsPage(),
      'Reports' => ReportsPage(
          onBack: () {
            if (_presentationStep > 0) {
              _jumpPresentationTo(_presentationStep - 1);
            } else {
              _stopPresentation();
            }
          },
          trips: _demo.trips,
          alerts: _demo.alerts,
          visits: _demo.visits,
          presentationCustomerVisitsKey:
              _presentationActive && _presentationStep == 4
                  ? _presentationPrimaryTargetKey
                  : null,
          scrollController: _presentationReportsScrollController,
        ),
      _ => throw StateError('Unknown presentation screen: $screen'),
    };
  }

  Widget _presentationPage() {
    final step = DemoPresentationStep.sequence[_presentationStep];
    final lastStep =
        _presentationStep == DemoPresentationStep.sequence.length - 1;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.present_to_all_rounded,
                        color: _blue, size: 19),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_presentationMode.label} · ${_presentationRole.name} · ${_presentationRole.label}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('stop-presentation'),
                      tooltip: 'Stop presentation',
                      onPressed: _stopPresentation,
                      icon: const Icon(Icons.close_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                LinearProgressIndicator(
                  value: (_presentationStep + 1) /
                      DemoPresentationStep.sequence.length,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'STEP ${_presentationStep + 1} OF ${DemoPresentationStep.sequence.length} · ${step.screen.toUpperCase()}',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    if (_presentationMode == DemoPresentationMode.autoplay)
                      Text(
                        _presentationTimeLabel(),
                        key: const ValueKey('presentation-countdown'),
                        style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  _presentationNarration(step),
                  style:
                      const TextStyle(color: _muted, fontSize: 12, height: 1.4),
                ),
                if (_presentationActionInProgress) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demonstrating with simulated actions…',
                          key: ValueKey('presentation-action-progress'),
                          style: TextStyle(
                              color: _blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ] else if (_completedPresentationActions
                    .contains(_presentationStep)) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 15, color: _green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demonstration complete · changes saved locally',
                          key: ValueKey('presentation-action-complete'),
                          style: TextStyle(
                              color: _green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      key: const ValueKey('presentation-previous'),
                      tooltip: 'Previous step',
                      onPressed: _presentationStep > 0
                          ? () => _jumpPresentationTo(_presentationStep - 1)
                          : null,
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    if (_presentationMode == DemoPresentationMode.autoplay)
                      IconButton.filled(
                        key: ValueKey(_presentationPlaying
                            ? 'presentation-pause'
                            : 'presentation-resume'),
                        tooltip: _presentationPlaying ? 'Pause' : 'Resume',
                        onPressed: () =>
                            _setPresentationPlaying(!_presentationPlaying),
                        icon: Icon(_presentationPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                      )
                    else
                      const Icon(Icons.touch_app_outlined,
                          size: 20, color: _muted),
                    const Spacer(),
                    if (_presentationMode == DemoPresentationMode.autoplay &&
                        lastStep)
                      TextButton.icon(
                        key: const ValueKey('replay-presentation'),
                        onPressed: _startPresentation,
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Replay'),
                      )
                    else if (_presentationMode == DemoPresentationMode.guided &&
                        lastStep)
                      FilledButton(
                        key: const ValueKey('finish-presentation'),
                        onPressed: _stopPresentation,
                        child: const Text('Finish'),
                      )
                    else
                      FilledButton.icon(
                        key: const ValueKey('presentation-next'),
                        onPressed: _presentationActionInProgress
                            ? null
                            : _completePresentationStep,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Next step'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _presentationScreenContent()),
      ],
    );
  }

  void _openWalkthroughScreen(String screen) {
    final destination = switch (screen) {
      'Home' => (0, null),
      'Trips' => (1, null),
      'Map' => (2, null),
      'Alerts' => (3, null),
      'Reports' => (4, 'Reports'),
      _ => throw StateError('Unknown walkthrough screen: $screen'),
    };
    setState(() {
      _tab = destination.$1;
      _morePage = destination.$2;
      if (screen == 'Trips') _selectedTripStatus = 'All statuses';
      if (screen == 'Alerts') _alertSection = 'Needs action';
    });
  }

  Widget _demoControls() {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeading(title: 'Demo controls'),
          const SizedBox(height: 10),
          const Text(
            'SIMULATED DATA ONLY\nAdvance every eligible trip by one stage. '
            'Changes are saved on this device only. Alerts remain open until '
            'explicitly resolved; completing a trip does not clear a vehicle issue.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 12),
          for (final trip in _trips)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${trip.code} · ${trip.status}',
                  style: const TextStyle(fontSize: 12)),
            ),
          if (_demo.saving) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('advance-demo'),
            onPressed: _demo.saving || !_demo.canAdvance
                ? null
                : () => _saveDemo(
                      () => _demo.advance(DateTime.now()),
                      'Simulated trips advanced and saved on this device.',
                    ),
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('Advance demo one step'),
          ),
          const SizedBox(height: 8),
          const Divider(height: 28),
          const SectionHeading(title: 'Customer visit demo events'),
          const SizedBox(height: 8),
          const Text(
            'Record sample arrival and departure events manually. These do not use GPS, geofences, or real customer locations.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('visit-vehicle-$_visitVehicle'),
            initialValue: _visitVehicle,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Sample vehicle'),
            items: [
              for (final vehicle in DemoVisitCatalog.vehicles)
                DropdownMenuItem(value: vehicle, child: Text(vehicle)),
            ],
            onChanged: _demo.saving
                ? null
                : (vehicle) {
                    if (vehicle != null) {
                      setState(() {
                        _visitVehicle = vehicle;
                        _visitTripCode = null;
                      });
                    }
                  },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey('visit-site-$_visitSite'),
            initialValue: _visitSite,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Sample site'),
            items: [
              for (final site in DemoVisitCatalog.sites)
                DropdownMenuItem(value: site, child: Text(site)),
            ],
            onChanged: _demo.saving
                ? null
                : (site) {
                    if (site != null) setState(() => _visitSite = site);
                  },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            key: ValueKey('visit-trip-${_visitTripCode ?? 'outside'}'),
            initialValue: _visitTripCode,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Link to active trip (optional)'),
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('Outside trip')),
              for (final trip in _demo.activeTrips
                  .where((trip) => trip.vehicle == _visitVehicle))
                DropdownMenuItem<String?>(
                  value: trip.code,
                  child: Text('${trip.code} · ${trip.status}'),
                ),
            ],
            onChanged: _demo.saving
                ? null
                : (tripCode) => setState(() => _visitTripCode = tripCode),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const ValueKey('record-site-arrival'),
            onPressed: _demo.saving
                ? null
                : () => _saveDemo(
                      () => _demo.recordSiteArrival(
                        vehicle: _visitVehicle,
                        site: _visitSite,
                        tripCode: _visitTripCode,
                        now: DateTime.now(),
                      ),
                      'Sample site arrival recorded and saved.',
                    ),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Record demo arrival'),
          ),
          const SizedBox(height: 12),
          if (_demo.openVisits.isEmpty)
            const Text('No open sample site visits.')
          else
            for (final visit in _demo.openVisits) ...[
              const Divider(height: 20),
              Text(
                '${visit.vehicle} · ${visit.site}\n${visit.customer} · ${visit.tripCode ?? 'Outside trip'}',
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: ValueKey('depart-site-${visit.id}'),
                onPressed: _demo.saving
                    ? null
                    : () => _saveDemo(
                          () => _demo.recordSiteDeparture(
                              visit.id, DateTime.now()),
                          'Sample site departure recorded.',
                        ),
                child: const Text('Record demo departure'),
              ),
              TextButton(
                key: ValueKey('incomplete-site-${visit.id}'),
                onPressed:
                    _demo.saving ? null : () => _closeIncompleteVisit(visit.id),
                child: const Text('Close as incomplete'),
              ),
            ],
          const SizedBox(height: 8),
          const Divider(height: 28),
          _guidedScenarios(),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('reset-demo'),
            onPressed: _demo.saving
                ? null
                : () async {
                    if (!await _confirmDemoReset(context) || !mounted) return;
                    await _saveDemo(() async {
                      await _demo.reset();
                      if (!mounted) return;
                      setState(() {
                        _selectedTripStatus = 'All statuses';
                        _scenarioChoice = DemoScenario.normal;
                        _tab = 4;
                        _morePage = null;
                        _alertSection = 'Needs action';
                        _situationKind = 'All kinds';
                        _historyOutcome = 'All closed situations';
                        _intelligenceDays = 30;
                      });
                    }, 'Original demo data restored and saved.');
                  },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset Demo'),
          ),
        ],
      ),
    );
  }

  Widget _guidedScenarios() {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeading(title: 'Guided scenarios'),
          const SizedBox(height: 8),
          const Text(
            'Choose a fixed sample walkthrough. Loading it replaces saved demo changes on this device; Reset Demo restores the original samples.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DemoScenario>(
            key: ValueKey('guided-scenario-${_scenarioChoice.name}'),
            initialValue: _scenarioChoice,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Scenario'),
            items: [
              for (final scenario in DemoScenario.values)
                DropdownMenuItem(
                  value: scenario,
                  child: Text(scenario.label),
                ),
            ],
            onChanged: _demo.saving
                ? null
                : (scenario) {
                    if (scenario != null) {
                      setState(() => _scenarioChoice = scenario);
                    }
                  },
          ),
          const SizedBox(height: 8),
          Text(
            _scenarioChoice.summary,
            key: const ValueKey('guided-scenario-summary'),
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('load-guided-scenario'),
            onPressed: _demo.saving ? null : _loadGuidedScenario,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('Load ${_scenarioChoice.label}'),
          ),
          const SizedBox(height: 8),
          for (var index = 0;
              index < _scenarioChoice.walkthrough.length;
              index++)
            ListTile(
              key: ValueKey('walkthrough-step-$index'),
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 14,
                child:
                    Text('${index + 1}', style: const TextStyle(fontSize: 12)),
              ),
              title: Text(_scenarioChoice.walkthrough[index].screen),
              subtitle: Text(_scenarioChoice.walkthrough[index].instruction),
              trailing: TextButton(
                onPressed: () => _openWalkthroughScreen(
                    _scenarioChoice.walkthrough[index].screen),
                child: const Text('Open'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _walkthroughPage() {
    return _pageScroll([
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _tab = 0;
            _morePage = null;
          }),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Home'),
        ),
      ),
      _pageHeading('Stakeholder walkthrough', 'A guided, simulated demo'),
      const DemoNotice(),
      const SizedBox(height: 16),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeading(title: 'Demo Director'),
            const SizedBox(height: 8),
            const Text(
              'Choose how to present the sample operation. Starting replaces saved demo records only after confirmation.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DemoPresentationMode>(
              key: ValueKey('presentation-mode-${_presentationMode.name}'),
              initialValue: _presentationMode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Presentation mode'),
              items: [
                for (final mode in DemoPresentationMode.values)
                  DropdownMenuItem(
                    value: mode,
                    child: Text(mode.label),
                  ),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  setState(() => _presentationMode = mode);
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              _presentationMode.description,
              key: const ValueKey('presentation-mode-description'),
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_DemoRole>(
              key: const ValueKey('presentation-role-switcher'),
              initialValue: _presentationRole,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Personnel perspective'),
              items: [
                for (final role in _DemoRole.values)
                  DropdownMenuItem(
                    value: role,
                    child: Text(role.label),
                  ),
              ],
              onChanged: (role) {
                if (role != null) {
                  setState(() => _presentationRole = role);
                }
              },
            ),
            if (_presentationMode == DemoPresentationMode.autoplay) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey('presentation-length-$_presentationLength'),
                initialValue: _presentationLength,
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Presentation length'),
                items: [
                  for (final minutes
                      in DemoPresentationStep.presentationLengths)
                    DropdownMenuItem(
                      value: minutes,
                      child: Text('$minutes minutes'),
                    ),
                ],
                onChanged: (minutes) {
                  if (minutes != null) {
                    setState(() => _presentationLength = minutes);
                  }
                },
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('start-presentation'),
              onPressed: _demo.saving ? null : _startPresentation,
              icon: Icon(_presentationMode == DemoPresentationMode.explore
                  ? Icons.explore_outlined
                  : Icons.play_arrow_rounded),
              label: Text(
                _presentationMode == DemoPresentationMode.explore
                    ? 'Explore ${_scenarioChoice.label}'
                    : 'Start ${_presentationMode.label.toLowerCase()}',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _guidedScenarios(),
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
          key: ValueKey('more-item-${item.title}'),
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
      const Text(
        'ACCOUNT',
        style: TextStyle(
          color: _muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 12),
      PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('DEMO ACCOUNT PERSPECTIVE',
                style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6)),
            const SizedBox(height: 10),
            Text(_demoRole.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_demoRole.organization, style: const TextStyle(color: _muted)),
            const SizedBox(height: 12),
            DropdownButtonFormField<_DemoRole>(
              key: const ValueKey('demo-role-switcher'),
              initialValue: _demoRole,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Switch demo role'),
              items: [
                for (final role in _DemoRole.values)
                  DropdownMenuItem(value: role, child: Text(role.label)),
              ],
              onChanged: (role) {
                if (role != null) setState(() => _demoRole = role);
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Display-only sample perspective. No permissions, account access, or actions are changed.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'GEUTech sign-in linking is not connected in this prototype.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _demoControls(),
    ]);
  }

  Widget _moreDetailPage() {
    final title = _morePage!;
    if (title == 'Walkthrough') return _walkthroughPage();
    if (title == 'Reports') {
      return ReportsPage(
        onBack: () => setState(() => _morePage = null),
        trips: _demo.trips,
        alerts: _demo.alerts,
        visits: _demo.visits,
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
              _partnerStatus(
                  'Held until a supervisor confirms the tonnes', '0'),
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
        border:
            Border.all(color: const Color(0xFFFF5C58).withValues(alpha: 0.4)),
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
    final trip = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => TripWizard(store: _demo),
      ),
    );
    if (trip == null || !mounted) return;
    setState(() => _selectedTripStatus = 'All statuses');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('${trip.code} created as Planned. Demo saved locally.')),
    );
  }

  void _openTrip(String code) {
    final isPresentationTrip = _presentationActive &&
        (_presentationStep == 0 || _presentationStep == 1);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => TripDetails(
          key: isPresentationTrip ? _presentationTripDetailsKey : null,
          store: _demo,
          code: code,
          presentationAdvanceKey: isPresentationTrip && _presentationStep == 0
              ? _presentationSecondaryTargetKey
              : null,
          presentationBackKey: isPresentationTrip
              ? _presentationStep == 0
                  ? _presentationTertiaryTargetKey
                  : _presentationSecondaryTargetKey
              : null,
          scrollController:
              isPresentationTrip ? _presentationDetailsScrollController : null,
        ),
      ),
    );
  }
}

class DemoNotice extends StatelessWidget {
  const DemoNotice({
    super.key,
    this.compact = false,
    this.title,
    this.message,
    this.neutral = false,
  });

  final bool compact;
  final String? title;
  final String? message;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 11 : 14),
      decoration: BoxDecoration(
        color: neutral ? _surface : _blue.withValues(alpha: 0.09),
        border: Border.all(
            color: neutral ? _border : _blue.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _blue, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!,
                      style: const TextStyle(
                          color: _blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                ],
                Text(
                  message ??
                      (compact
                          ? 'Prototype with sample data · Not connected to live operations'
                          : 'Presentation prototype. Sample records and actions are not connected to the live system.'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
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
    this.expanded = false,
    this.onAction,
    this.reference,
    this.onTap,
    this.presentationManageKey,
  });

  final String title;
  final String detail;
  final String severity;
  final IconData icon;
  final bool expanded;
  final ValueChanged<String>? onAction;
  final String? reference;
  final VoidCallback? onTap;
  final GlobalKey? presentationManageKey;

  @override
  Widget build(BuildContext context) {
    final color = severity == 'Warning' ? _amber : _blue;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        Text(
                          expanded
                              ? (reference ?? 'SIMULATED INCIDENT')
                              : detail,
                          style: TextStyle(
                            color: _muted,
                            fontSize: expanded ? 10 : 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  StatusPill(label: severity, color: color),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 16),
                Text(detail,
                    style: const TextStyle(
                        color: _muted, fontSize: 12, height: 1.6)),
                const SizedBox(height: 20),
                KeyedSubtree(
                  key: presentationManageKey,
                  child: FilledButton(
                    onPressed: () => onAction?.call(severity == 'Warning'
                        ? 'Reset Link'
                        : 'Verify Tonnage'),
                    child: const Text('Manage demo alert'),
                  ),
                ),
                if (severity != 'Warning')
                  TextButton(
                    onPressed: () => onAction?.call('Reassign Supervisor'),
                    child: const Text('Assign demo supervisor',
                        style: TextStyle(color: _muted, fontSize: 12)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    this.showProgress = false,
    this.onTap,
  });

  final Trip trip;
  final bool showProgress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (trip.status) {
      'In transit' ||
      'Approaching' ||
      'Arrived' =>
        showProgress ? _blue : _green,
      'At origin' || 'Exception' => _amber,
      _ => _blue,
    };

    final stops = trip.route.split(' → ');
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(showProgress ? 22 : 14),
        side: const BorderSide(color: _border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(
                        trip.code,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      )),
                      StatusPill(label: trip.status, color: color),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (showProgress) ...[
                    if (trip.project != null) ...[
                      Text('Project: ${trip.project}',
                          style: const TextStyle(color: _muted, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text('Driver: ${trip.driver}',
                          style: const TextStyle(color: _muted, fontSize: 12)),
                      const SizedBox(height: 14),
                    ],
                    _TripStop(label: 'ORIGIN', name: stops.first, color: color),
                    const SizedBox(height: 14),
                    _TripStop(
                        label: 'DESTINATION', name: stops.last, color: _blue),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TripFact(
                            label: 'VEHICLE',
                            value: trip.vehicle,
                            icon: Icons.local_shipping_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TripFact(
                            label: 'MATERIAL',
                            value: trip.material,
                            icon: Icons.category_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        Text(
                          trip.status == 'At origin'
                              ? 'LOADING STATUS'
                              : 'PROGRESS',
                          style: const TextStyle(
                              color: _muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(trip.eta,
                            style: TextStyle(color: color, fontSize: 11)),
                      ],
                    ),
                  ] else ...[
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
                      style: const TextStyle(
                          color: _muted, fontSize: 11, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
            if (showProgress)
              LinearProgressIndicator(
                value: trip.progress,
                minHeight: 4,
                backgroundColor: _surfaceRaised,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}

class _TripStop extends StatelessWidget {
  const _TripStop({
    required this.label,
    required this.name,
    required this.color,
  });

  final String label;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle_outlined, size: 10, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: _muted, fontSize: 9)),
              const SizedBox(height: 4),
              Text(name, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripFact extends StatelessWidget {
  const _TripFact({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 9)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: _blue),
              const SizedBox(width: 5),
              Expanded(
                  child: Text(value, style: const TextStyle(fontSize: 11))),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomTabs extends StatelessWidget {
  const _BottomTabs({
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _background,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: Semantics(
                  selected: index == selectedIndex,
                  child: TextButton(
                    key: ValueKey('main-tab-${items[index].label}'),
                    style: TextButton.styleFrom(
                      foregroundColor: index == selectedIndex ? _blue : _muted,
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
                      minimumSize: const Size(48, 64),
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: () => onSelected(index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 3,
                          decoration: BoxDecoration(
                            color: index == selectedIndex
                                ? _blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 11),
                        Icon(items[index].icon, size: 22),
                        const SizedBox(height: 5),
                        Text(items[index].label,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
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
