part of 'main.dart';

extension _OperationsTripsView on _OperationsShellState {
  Widget _tripsPage() {
    final visibleTrips = _visibleTrips;
    final presentationAction =
        _presentationActive ? _presentationCurrentStep.action : '';
    final tripAction = const {
      'inspect-trips',
      'inspect-trip',
      'inspect-created-trip',
      'inspect-exception',
      'progress-trip',
      'edit-trip',
    }.contains(presentationAction);
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
              key: _presentationActive && presentationAction == 'inspect-trips'
                  ? _presentationSecondaryTargetKey
                  : ValueKey('trip-filter-$_selectedTripStatus'),
              child: DropdownButtonFormField<String>(
                key: const ValueKey('trip-status-filter'),
                initialValue: _selectedTripStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Trip status',
                  fillColor: _surface,
                ),
                items: [
                  for (final status in _OperationsShellState._tripStatuses)
                    DropdownMenuItem(value: status, child: Text(status)),
                ],
                onChanged: (status) {
                  if (status != null) {
                    _setPresentationActionState(
                      () => _selectedTripStatus = status,
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          KeyedSubtree(
            key: _presentationActive && presentationAction == 'create-trip'
                ? _presentationPrimaryTargetKey
                : null,
            child: IconButton.filled(
              tooltip: 'New trip',
              onPressed: () async {
                await _showCreateTrip();
              },
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
          ),
        ],
      ),
      const SizedBox(height: 16),
      SectionHeading(
        title: 'DEMO TRIPS (${visibleTrips.length})',
        action: TextButton(
          onPressed: () => _setPresentationActionState(
            () => _selectedTripStatus = 'Completed',
          ),
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
                    tripAction &&
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
}
