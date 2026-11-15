part of 'main.dart';

extension _DemoPresentationDispatch on _OperationsShellState {
  Future<void> _demonstratePresentationStep(int step) async {
    if (!_presentationActive ||
        _presentation.mode == DemoPresentationMode.explore ||
        _completedPresentationActions.contains(step)) {
      return;
    }
    final generation = _presentationTouchGeneration;
    final currentStep = _presentation.steps[step];
      final action = currentStep.action;
      final role = currentStep.role;
      final mappedRole = switch (role) {
        DemoPathAudience.administrator => _DemoRole.administrator,
        DemoPathAudience.dispatcher => _DemoRole.dispatcher,
        DemoPathAudience.driver => _DemoRole.driver,
        DemoPathAudience.supervisor => _DemoRole.supervisor,
        DemoPathAudience.allPersonnel => _demoRole,
      };
      if (_demoRole != mappedRole) {
        _setPresentationActionState(() => _demoRole = mappedRole);
      }

      switch (action) {
        case 'inspect-home':
          await _performPresentationAction(
            _presentationPrimaryTargetKey,
            'Review attention indicators',
            generation,
            scrollController: _presentationHomeScrollController,
          );
        case 'inspect-trips':
          for (final status in ['In transit', 'Completed']) {
            await _performPresentationAction(
              _presentationSecondaryTargetKey,
              'Filter trips by $status',
              generation,
              onActivate: () async => _setPresentationActionState(
                () => _selectedTripStatus = status,
              ),
              scrollController: _presentationTripsScrollController,
            );
            if (!_presentationCanContinue(generation)) return;
          }
          _setPresentationActionState(
            () => _selectedTripStatus = 'All statuses',
          );
          await WidgetsBinding.instance.endOfFrame;
          final sampleTrip = _presentationTrip;
          if (sampleTrip == null) {
            throw StateError('No sample trip is available to inspect.');
          }
          await _performPresentationAction(
            _presentationPrimaryTargetKey,
            'Open trip timeline',
            generation,
            onActivate: () async => _openTrip(sampleTrip.code),
            scrollController: _presentationTripsScrollController,
          );
          await _waitForPresentationState(
            () => _presentationTripDetailsKey.currentState != null,
            generation,
          );
          if (!_presentationCanContinue(generation)) return;
          await _performPresentationAction(
            _presentationTertiaryTargetKey,
            'Return to trips',
            generation,
            onActivate: () async =>
                _presentationTripDetailsKey.currentState?.backForPresentation(),
          );
        case 'create-trip':
          await _createPresentationTrip(generation);
        case 'inspect-created-trip':
        case 'inspect-trip':
        case 'inspect-exception':
          await _inspectPresentationTrip(action, generation);
        case 'edit-trip':
          await _editPresentationTripAssignment(generation);
        case 'progress-trip':
          await _progressPresentationTrip(currentStep, role, generation);
        case 'inspect-map':
          await _inspectPresentationMap(generation);
        case 'inspect-alert-history':
          await _inspectPresentationAlertHistory(generation);
        case 'filter-alerts':
          await _filterPresentationAlerts(generation);
        case 'acknowledge-alert':
        case 'inspect-alert':
        case 'investigate-alert':
        case 'resolve-alert':
          await _runPresentationAlertAction(action, generation);
        case 'record-visit':
          await _recordPresentationVisit(generation);
        case 'inspect-reports':
          await _inspectPresentationReports(role, generation);
        case 'inspect-intelligence':
          await _inspectPresentationIntelligence(generation);
        case 'inspect-compliance':
        case 'inspect-settlement':
        case 'inspect-fleetops':
        case 'inspect-workspace':
          await _inspectPresentationWorkspace(generation);
        case 'inspect-visits':
        case 'inspect-visits-report':
          await _inspectPresentationVisitsReport(generation);
        default:
          throw StateError('Unsupported presentation action: $action');
      }
    _presentation.playback.completeAction(step, generation);
  }
}
