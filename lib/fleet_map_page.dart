import 'package:flutter/material.dart';

import 'demo_fleet.dart';
import 'demo_store.dart';
import 'trip_details.dart';

const _blue = Color(0xFF0088FF);
const _muted = Color(0xFF9B9DA5);

Color _statusColor(DemoVehicleStatus status) => switch (status) {
      DemoVehicleStatus.moving => const Color(0xFF22C55E),
      DemoVehicleStatus.loading => const Color(0xFFFFAA00),
      DemoVehicleStatus.idle => _muted,
      DemoVehicleStatus.reportingGap => const Color(0xFFFF7676),
    };

class FleetMapPage extends StatefulWidget {
  const FleetMapPage({
    super.key,
    required this.store,
    this.presentationVehicleId,
    this.presentationMarkerKey,
    this.presentationOpenTripKey,
    this.presentationBackKey,
    this.scrollController,
    this.vehicleDetailsScrollController,
    this.tripDetailsScrollController,
  });

  final DemoStore store;
  final String? presentationVehicleId;
  final GlobalKey? presentationMarkerKey;
  final GlobalKey? presentationOpenTripKey;
  final GlobalKey? presentationBackKey;
  final ScrollController? scrollController;
  final ScrollController? vehicleDetailsScrollController;
  final ScrollController? tripDetailsScrollController;

  @override
  State<FleetMapPage> createState() => _FleetMapPageState();
}

class _FleetMapPageState extends State<FleetMapPage> {
  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Future<void> _showVehicle(String id) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ListenableBuilder(
        listenable: widget.store,
        builder: (context, child) {
          final vehicle =
              demoFleet(widget.store).firstWhere((vehicle) => vehicle.id == id);
          return SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.8,
              child: ListView(
                controller: widget.vehicleDetailsScrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Vehicle $id',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        tooltip: 'Close vehicle details',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _SimulationNotice(),
                  const SizedBox(height: 20),
                  for (final (label, value) in [
                    ('Vehicle status', vehicle.status.label),
                    ('Driver', vehicle.driver),
                    (
                      'Assigned trip',
                      vehicle.trip?.code ?? 'No assigned demo trip'
                    ),
                    (
                      'Trip status',
                      vehicle.trip?.status ?? 'Not on a demo trip'
                    ),
                    ('Route', vehicle.trip?.route ?? 'No assigned demo route'),
                    (
                      'Simulated speed',
                      vehicle.speed == null
                          ? 'Unknown · Reporting gap'
                          : '${vehicle.speed} km/h'
                    ),
                    ('Last sample location', vehicle.location),
                    ('Sample reporting', vehicle.report),
                    (
                      'Maintenance',
                      'Not evaluated · No maintenance data connected'
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text('$label: $value',
                          style: const TextStyle(height: 1.5)),
                    ),
                  if (vehicle.status == DemoVehicleStatus.reportingGap)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Marker shows a stage-based simulation, not a current vehicle fix. '
                        'Advancing the trip does not clear the reporting gap.',
                        style: TextStyle(height: 1.5),
                      ),
                    ),
                  if (vehicle.trip != null)
                    KeyedSubtree(
                      key: widget.presentationOpenTripKey,
                      child: FilledButton.icon(
                        key: const ValueKey('vehicle-open-trip'),
                        onPressed: () =>
                            Navigator.pop(context, vehicle.trip!.code),
                        icon: const Icon(Icons.route),
                        label: const Text('Open demo trip'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || code == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => TripDetails(
          store: widget.store,
          code: code,
          presentationBackKey: widget.presentationBackKey,
          scrollController: widget.tripDetailsScrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, child) {
        final fleet = demoFleet(widget.store);
        return ListView(
          key: const PageStorageKey('fleet-map-scroll'),
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const Text('Fleet map',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Sample routes & vehicle activity',
                style: TextStyle(color: _muted)),
            const SizedBox(height: 18),
            const _SimulationNotice(),
            const SizedBox(height: 16),
            const Text(
              'Route schematic · Not to scale\nPinch to zoom and drag to explore. Tap a vehicle for details.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('reset-map-view'),
                onPressed: () => _transform.value = Matrix4.identity(),
                icon: const Icon(Icons.center_focus_strong),
                label: const Text('Reset view'),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 380,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return InteractiveViewer(
                      transformationController: _transform,
                      minScale: 1,
                      maxScale: 3,
                      child: SizedBox(
                        width: width,
                        height: 380,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _RoutesPainter(fleet: fleet),
                              ),
                            ),
                            for (var index = 0; index < fleet.length; index++)
                              Positioned(
                                left: 12,
                                right: 12,
                                top: 8 + index * 88,
                                child: Text(
                                  fleet[index].trip?.route ??
                                      'Demo depot · No route',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 10),
                                ),
                              ),
                            for (var index = 0; index < fleet.length; index++)
                              Positioned(
                                left: 12 +
                                    fleet[index].routePosition * (width - 100),
                                top: 28 + index * 88,
                                child: Semantics(
                                  label:
                                      '${fleet[index].id}, ${fleet[index].status.label}, simulated location',
                                  child: KeyedSubtree(
                                    key: fleet[index].id ==
                                            widget.presentationVehicleId
                                        ? widget.presentationMarkerKey
                                        : null,
                                    child: FilledButton(
                                      key: ValueKey(
                                          'map-marker-${fleet[index].id}'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            _statusColor(fleet[index].status),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        minimumSize: const Size(76, 48),
                                      ),
                                      onPressed: () =>
                                          _showVehicle(fleet[index].id),
                                      child: Text(fleet[index].id,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final status in DemoVehicleStatus.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: _statusColor(status)),
                      const SizedBox(width: 6),
                      Text(status.label, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Demo vehicles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Each lane represents one vehicle. Positions and speeds are derived from saved trip stages, '
              'not road distances or elapsed travel time. Use trip details to advance a journey.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 12),
            for (final vehicle in fleet) ...[
              Card(
                child: ListTile(
                  key: ValueKey('fleet-vehicle-${vehicle.id}'),
                  contentPadding: const EdgeInsets.all(14),
                  leading: Icon(Icons.local_shipping,
                      color: _statusColor(vehicle.status)),
                  title: Text('${vehicle.id} · ${vehicle.status.label}'),
                  subtitle: Text(
                    '${vehicle.trip?.code ?? 'No trip'} · ${vehicle.location}',
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showVehicle(vehicle.id),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _SimulationNotice extends StatelessWidget {
  const _SimulationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.1),
        border: Border.all(color: _blue.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'SIMULATED — NOT LIVE GPS\nIllustrative data only. No location permissions or production telemetry.',
        style: TextStyle(fontSize: 12, height: 1.6),
      ),
    );
  }
}

class _RoutesPainter extends CustomPainter {
  const _RoutesPainter({required this.fleet});

  final List<DemoVehicle> fleet;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF141E26));
    final grid = Paint()..color = const Color(0xFF21303C);
    for (var x = 0.0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var index = 0; index < fleet.length; index++) {
      final y = 52.0 + index * 88;
      final paint = Paint()
        ..color = _statusColor(fleet[index].status).withValues(alpha: 0.55)
        ..strokeWidth = 3;
      canvas.drawLine(Offset(30, y), Offset(size.width - 30, y), paint);
      canvas.drawCircle(Offset(30, y), 6, paint);
      canvas.drawCircle(Offset(size.width - 30, y), 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutesPainter oldDelegate) => true;
}
