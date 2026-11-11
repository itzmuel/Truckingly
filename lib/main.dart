import 'package:flutter/material.dart';

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
      status: 'Loading',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    return _pageScroll([
      _pageHeading('Trips', 'Monitor material movement'),
      const DemoNotice(compact: true),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _showCreateTrip,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create trip'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: _blue,
          foregroundColor: Colors.white,
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Text(
            '${_trips.length} active',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          const StatusPill(label: 'All statuses', color: _muted),
        ],
      ),
      const SizedBox(height: 12),
      if (_trips.isEmpty)
        const EmptyState(
          icon: Icons.alt_route_rounded,
          title: 'No trips yet',
          detail: 'Create a trip to start tracking material movement.',
        )
      else
        for (final trip in _trips) ...[
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
    return _pageScroll([
      _pageHeading('Alerts', 'Situations that may need your attention'),
      const DemoNotice(compact: true),
      const SizedBox(height: 18),
      const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StatusPill(label: 'Needs action · 2', color: _amber),
          StatusPill(label: 'Earlier detections · 5', color: _blue),
        ],
      ),
      const SizedBox(height: 16),
      const AlertCard(
        title: 'Vehicle reporting gap',
        detail: 'DT-03 · Last report 42 minutes ago · Current trip TR-2045',
        severity: 'Warning',
        icon: Icons.cell_tower_rounded,
      ),
      const SizedBox(height: 12),
      const AlertCard(
        title: 'Delivery confirmation needed',
        detail:
            'TR-2046 · Waiting for a supervisor to confirm delivered tonnes',
        severity: 'Action',
        icon: Icons.fact_check_outlined,
      ),
      const SizedBox(height: 22),
      const SectionHeading(title: 'Informational records'),
      const SizedBox(height: 10),
      const PanelCard(
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: _blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '5 earlier detections were reviewed this week.',
                style: TextStyle(height: 1.45),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    ]);
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
    const previews = <String, _SectionPreview>{
      'Compliance & documents': _SectionPreview(
        Icons.verified_user_outlined,
        'Keep chain-of-custody records and generated trip documents together.',
        'No compliance records in this demo.',
      ),
      'Reports': _SectionPreview(
        Icons.bar_chart_rounded,
        'Review customer visits, activity, and reporting coverage.',
        'Sample reporting period · Last 30 days',
      ),
      'Intelligence': _SectionPreview(
        Icons.insights_rounded,
        'Understand fleet condition and findings without mistaking missing data for a healthy fleet.',
        '4 of 12 sample vehicles evaluated',
      ),
      'Settlement': _SectionPreview(
        Icons.account_balance_wallet_outlined,
        'View work offers and completion evidence for settlement.',
        'GEUTech account linking required',
      ),
      'FleetOps': _SectionPreview(
        Icons.directions_car_filled_outlined,
        'Review vehicle movements and tracker activity.',
        'GEUTech account linking required',
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

  Future<void> _showCreateTrip() async {
    final trip = await showModalBottomSheet<Trip>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (context) => const CreateTripSheet(),
    );

    if (trip == null || !mounted) return;

    setState(() => _trips.insert(0, trip));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo trip added on this device only.')),
    );
  }
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

class CreateTripSheet extends StatefulWidget {
  const CreateTripSheet({super.key});

  @override
  State<CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends State<CreateTripSheet> {
  final _formKey = GlobalKey<FormState>();
  final _vehicle = TextEditingController();
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _material = TextEditingController();

  @override
  void dispose() {
    _vehicle.dispose();
    _origin.dispose();
    _destination.dispose();
    _material.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a trip',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'This trip is a local demo record, not a dispatch.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              _field(_vehicle, 'Vehicle', 'e.g. DT-21'),
              const SizedBox(height: 12),
              _field(_origin, 'Origin', 'Pickup location'),
              const SizedBox(height: 12),
              _field(_destination, 'Destination', 'Delivery location'),
              const SizedBox(height: 12),
              _field(_material, 'Material', 'e.g. Granite aggregate'),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: _blue,
                ),
                child: const Text('Add demo trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, String hint) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Enter $label' : null,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      Trip(
        code: 'DEMO-${DateTime.now().millisecondsSinceEpoch % 10000}',
        vehicle: _vehicle.text.trim(),
        route: '${_origin.text.trim()} → ${_destination.text.trim()}',
        material: _material.text.trim(),
        status: 'Dispatched · demo',
        progress: 0,
        eta: 'Not connected',
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
    final color = trip.status.startsWith('Loading') ? _amber : _green;

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
