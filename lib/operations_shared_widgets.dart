part of 'main.dart';

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
