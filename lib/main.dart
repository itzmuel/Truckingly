import 'dart:async';

import 'package:flutter/material.dart';

import 'demo_director.dart';
import 'demo_paths.dart';
import 'demo_presentation_controller.dart';
import 'demo_store.dart';
import 'reports_page.dart';
import 'trip_wizard.dart';
import 'trip_details.dart';
import 'fleet_map_page.dart';
import 'alert_details.dart';
import 'demo_visit_catalog.dart';
import 'demo_touch_pointer.dart';

part 'demo_presentation_actions.dart';
part 'demo_presentation_dispatch.dart';
part 'demo_presentation_view.dart';
part 'demo_presentation_setup.dart';
part 'demo_presentation_runtime.dart';
part 'operations_alerts_view.dart';
part 'operations_more_view.dart';
part 'operations_partner_intelligence_view.dart';
part 'operations_home_view.dart';
part 'operations_trips_view.dart';
part 'operations_demo_controls_view.dart';
part 'operations_shell_actions.dart';
part 'operations_shell_layout.dart';
part 'operations_shared_widgets.dart';
part 'operations_app.dart';
part 'demo_presentation_session.dart';

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
  final DemoPresentationSession _presentation = DemoPresentationSession();
  final GlobalKey<TripWizardState> _presentationTripWizardKey = GlobalKey();
  final GlobalKey<ReportsPageState> _presentationReportsPageKey = GlobalKey();
  final GlobalKey<TripDetailsState> _presentationTripDetailsKey = GlobalKey();
  final GlobalKey<TripDetailsState> _presentationMapTripDetailsKey =
      GlobalKey();
  final GlobalKey<FleetMapPageState> _presentationMapPageKey = GlobalKey();
  final GlobalKey<AlertDetailsState> _presentationAlertDetailsKey = GlobalKey();
  final GlobalKey _presentationPageTargetKey = GlobalKey();
  final GlobalKey _presentationPrimaryTargetKey = GlobalKey();
  final GlobalKey _presentationSecondaryTargetKey = GlobalKey();
  final GlobalKey _presentationTertiaryTargetKey = GlobalKey();
  final GlobalKey _presentationFourthTargetKey = GlobalKey();
  final GlobalKey _presentationFifthTargetKey = GlobalKey();
  final GlobalKey _presentationSixthTargetKey = GlobalKey();
  final GlobalKey _presentationSeventhTargetKey = GlobalKey();
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
  final ScrollController _presentationMoreScrollController = ScrollController();
  int get _presentationStep => _presentation.playback.stepIndex;
  bool get _presentationActive => _presentation.playback.active;
  bool get _presentationPlaying => _presentation.playback.playing;
  bool get _presentationActionInProgress =>
      _presentation.playback.actionInProgress;
  int get _presentationTouchGeneration => _presentation.playback.generation;
  Set<int> get _completedPresentationActions =>
      _presentation.playback.completedActions;

  @override
  void initState() {
    super.initState();
    _presentation.scenario = _demo.scenario;
    _presentation.playback.addListener(_refreshPresentationPlayback);
    _demo.addListener(_refreshDemo);
  }

  void _refreshPresentationPlayback() {
    if (mounted) setState(() {});
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
    _presentation.playback
      ..removeListener(_refreshPresentationPlayback)
      ..dispose();
    _presentationHomeScrollController.dispose();
    _presentationTripsScrollController.dispose();
    _presentationMapScrollController.dispose();
    _presentationAlertsScrollController.dispose();
    _presentationReportsScrollController.dispose();
    _presentationDetailsScrollController.dispose();
    _presentationVehicleSheetScrollController.dispose();
    _presentationMoreScrollController.dispose();
    _demo.removeListener(_refreshDemo);
    if (widget.store == null) _demo.dispose();
    super.dispose();
  }

  List<Trip> get _trips => _demo.trips;
  DemoPathStep get _presentationCurrentStep =>
      _presentation.steps[_presentationStep];

  Trip? get _presentationTrip {
    final selectedCode = _presentation.tripCode;
    if (selectedCode != null) {
      return _demo.trips.firstWhere((trip) => trip.code == selectedCode);
    }
    if (_demo.scenario == DemoScenario.vehicleIncident) {
      for (final trip in _demo.trips) {
        if (trip.status == 'Exception') return trip;
      }
    }
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

  void _setPresentationActionState(VoidCallback callback) {
    setState(callback);
  }
}
