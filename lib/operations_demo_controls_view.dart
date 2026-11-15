part of 'main.dart';

extension _OperationsDemoControlsView on _OperationsShellState {
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
              child: Text(
                '${trip.code} · ${trip.status}',
                style: const TextStyle(fontSize: 12),
              ),
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
                      _setPresentationActionState(() {
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
                    if (site != null) {
                      _setPresentationActionState(() => _visitSite = site);
                    }
                  },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            key: ValueKey('visit-trip-${_visitTripCode ?? 'outside'}'),
            initialValue: _visitTripCode,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Link to active trip (optional)',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Outside trip'),
              ),
              for (final trip in _demo.activeTrips
                  .where((trip) => trip.vehicle == _visitVehicle))
                DropdownMenuItem<String?>(
                  value: trip.code,
                  child: Text('${trip.code} · ${trip.status}'),
                ),
            ],
            onChanged: _demo.saving
                ? null
                : (tripCode) => _setPresentationActionState(
                      () => _visitTripCode = tripCode,
                    ),
          ),
          const SizedBox(height: 10),
          KeyedSubtree(
            key: _presentationActive &&
                    _presentationCurrentStep.action == 'record-visit' &&
                    _demo.openVisits.isEmpty
                ? _presentationPrimaryTargetKey
                : null,
            child: FilledButton.icon(
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
              KeyedSubtree(
                key: _presentationActive &&
                        _presentationCurrentStep.action == 'record-visit' &&
                        visit.id == _demo.openVisits.first.id
                    ? _presentationPrimaryTargetKey
                    : null,
                child: OutlinedButton(
                  key: ValueKey('depart-site-${visit.id}'),
                  onPressed: _demo.saving
                      ? null
                      : () => _saveDemo(
                            () => _demo.recordSiteDeparture(
                              visit.id,
                              DateTime.now(),
                            ),
                            'Sample site departure recorded.',
                          ),
                  child: const Text('Record demo departure'),
                ),
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
                      _setPresentationActionState(() {
                        _selectedTripStatus = 'All statuses';
                        _presentation.scenario = DemoScenario.normal;
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
}
