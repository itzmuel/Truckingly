part of 'main.dart';

extension _OperationsHomeView on _OperationsShellState {
  Widget _homePage() {
    final presentationAction =
        _presentationActive ? _presentationCurrentStep.action : '';
    final homeTripAction = const {
      'inspect-trip',
      'inspect-created-trip',
      'inspect-exception',
      'progress-trip',
      'edit-trip',
    }.contains(presentationAction);
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
            child: KeyedSubtree(
              key: _presentationActive &&
                      _presentationCurrentStep.action == 'inspect-home'
                  ? _presentationPrimaryTargetKey
                  : null,
              child: MetricCard(
                label: 'NEEDS ACTION',
                value: '${_demo.openAlerts.length}',
                icon: Icons.warning_amber_rounded,
                accent: _amber,
              ),
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
              onPressed: () => _setPresentationActionState(() {
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
          onPressed: () => _setPresentationActionState(() => _tab = 3),
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
          onPressed: () => _setPresentationActionState(() => _tab = 1),
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
                  homeTripAction &&
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
}
