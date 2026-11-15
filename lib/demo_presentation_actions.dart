part of 'main.dart';

extension _DemoPresentationTripActions on _OperationsShellState {
  Future<void> _createPresentationTrip(int generation) async {
    final existingCode = _presentation.tripCode;
    if (existingCode != null &&
        _demo.trips.any((trip) => trip.code == existingCode)) {
      return;
    }
    await _performPresentationAction(
      _presentationPrimaryTargetKey,
      'Open new trip wizard',
      generation,
      scrollController: _presentationTripsScrollController,
      onActivate: () async {
        final tripResult = _showCreateTrip(
          presentationNextKey: _presentationSecondaryTargetKey,
          onPresentationTripCreated: (trip) {
            _presentation.tripCode = trip.code;
          },
        );
        await _waitForPresentationState(
          () => _presentationTripWizardKey.currentState != null,
          generation,
          description: 'The new trip wizard did not open.',
        );
        final wizard = _presentationTripWizardKey.currentState!;
        wizard.prepareSampleAssignment();
        await WidgetsBinding.instance.endOfFrame;
        for (var index = 0; index < 3; index++) {
          if (!_presentationCanContinue(generation)) return;
          await _performPresentationAction(
            _presentationSecondaryTargetKey,
            index == 2 ? 'Create sample trip' : 'Continue trip setup',
            generation,
            onActivate: () async {
              final state = _presentationTripWizardKey.currentState;
              if (state == null) {
                throw StateError('The sample trip wizard was closed.');
              }
              await state.continueForPresentation();
            },
          );
          if (index < 2) await WidgetsBinding.instance.endOfFrame;
        }
        await _waitForDemoSave(generation);
        final createdTrip = await tripResult;
        if (!_presentationCanContinue(generation) || createdTrip == null) {
          return;
        }
        _presentation.tripCode = createdTrip.code;
        await _waitForPresentationState(
          () => _presentationTripWizardKey.currentState == null,
          generation,
          description: 'The trip wizard did not finish creating the trip.',
        );
      },
    );
  }

  Future<void> _inspectPresentationTrip(
    String action,
    int generation,
  ) async {
    final trip = action == 'inspect-exception'
        ? _demo.trips.where((item) => item.status == 'Exception').firstOrNull
        : _presentationTrip;
    if (trip == null) {
      throw StateError('No eligible sample trip is available to inspect.');
    }
    _presentation.tripCode = trip.code;
    await _performPresentationAction(
      _presentationPrimaryTargetKey,
      action == 'inspect-exception'
          ? 'Open exception details'
          : 'Open trip details',
      generation,
      onActivate: () async => _openTrip(trip.code),
      scrollController: _presentationTripsScrollController,
    );
    await _waitForPresentationState(
      () => _presentationTripDetailsKey.currentState != null,
      generation,
      description: 'The selected trip details did not open.',
    );
    if (!_presentationCanContinue(generation)) return;
    await _performPresentationAction(
      _presentationTertiaryTargetKey,
      'Return to trips',
      generation,
      onActivate: () async =>
          _presentationTripDetailsKey.currentState?.backForPresentation(),
    );
  }

  Future<void> _editPresentationTripAssignment(int generation) async {
    final trip = _presentationTrip;
    if (trip == null || !trip.canEdit) {
      throw StateError('The selected demo trip cannot be edited.');
    }
    final originalDriver = trip.driver;
    final originalVehicle = trip.vehicle;
    await _performPresentationAction(
      _presentationPrimaryTargetKey,
      'Open trip assignments',
      generation,
      onActivate: () async => _openTrip(trip.code),
      scrollController: _presentationTripsScrollController,
    );
    await _waitForPresentationState(
      () => _presentationTripDetailsKey.currentState != null,
      generation,
    );
    if (!_presentationCanContinue(generation)) return;
    await _performPresentationAction(
      _presentationSecondaryTargetKey,
      'Edit demo assignments',
      generation,
      onActivate: () async =>
          _presentationTripDetailsKey.currentState?.editForPresentation(),
    );
    await _waitForPresentationState(
      () => _presentationTripWizardKey.currentState != null,
      generation,
      description: 'The trip assignment wizard did not open.',
    );
    _presentationTripWizardKey.currentState!.prepareSampleAssignment();
    await WidgetsBinding.instance.endOfFrame;
    for (var index = 0; index < 3; index++) {
      if (!_presentationCanContinue(generation)) return;
      await _performPresentationAction(
        _presentationFourthTargetKey,
        index == 2 ? 'Save sample assignment' : 'Continue assignment setup',
        generation,
        onActivate: () async {
          final wizard = _presentationTripWizardKey.currentState;
          if (wizard == null) {
            throw StateError('The assignment wizard was closed.');
          }
          await wizard.continueForPresentation();
        },
      );
      if (index < 2) await WidgetsBinding.instance.endOfFrame;
    }
    await _waitForDemoSave(generation);
    await _waitForPresentationState(
      () => _presentationTripWizardKey.currentState == null,
      generation,
      description: 'The assignment wizard did not finish.',
    );
    final updatedTrip =
        _demo.trips.firstWhere((item) => item.code == trip.code);
    if (updatedTrip.driver == originalDriver &&
        updatedTrip.vehicle == originalVehicle) {
      throw StateError('The sample trip assignment did not change.');
    }
    if (!_presentationCanContinue(generation)) return;
    await _performPresentationAction(
      _presentationTertiaryTargetKey,
      'Return to trips',
      generation,
      onActivate: () async =>
          _presentationTripDetailsKey.currentState?.backForPresentation(),
    );
  }

  Future<void> _progressPresentationTrip(
    DemoPathStep step,
    DemoPathAudience role,
    int generation,
  ) async {
    final initialTrip = _presentationTrip;
    if (initialTrip == null) {
      throw StateError('No sample trip is available to progress.');
    }
    final targetStatus = step.targetStatus ??
        (role == DemoPathAudience.driver ? 'Completed' : 'In transit');
    if (!Trip.journey.contains(targetStatus)) {
      throw StateError('Unsupported trip target status: $targetStatus.');
    }
    _presentation.tripCode = initialTrip.code;
    await _performPresentationAction(
      _presentationPrimaryTargetKey,
      'Open assigned trip',
      generation,
      onActivate: () async => _openTrip(initialTrip.code),
      scrollController: _presentationTripsScrollController,
    );
    await _waitForPresentationState(
      () => _presentationTripDetailsKey.currentState != null,
      generation,
    );
    var trip = _demo.tripByCode(initialTrip.code);
    if (Trip.journey.indexOf(trip.status) >
        Trip.journey.indexOf(targetStatus)) {
      throw StateError(
        'Trip ${trip.code} is already at ${trip.status}, beyond target $targetStatus.',
      );
    }
    while (trip.status != targetStatus && trip.canAdvance) {
      final beforeStatus = trip.status;
      final nextStatus = Trip.journey[Trip.journey.indexOf(beforeStatus) + 1];
      await _performPresentationAction(
        _presentationSecondaryTargetKey,
        'Advance to $nextStatus',
        generation,
        onActivate: () async {
          final details = _presentationTripDetailsKey.currentState;
          if (details == null) {
            throw StateError('The trip progression control is unavailable.');
          }
          await details.advanceForPresentation();
        },
        scrollController: _presentationDetailsScrollController,
      );
      await _waitForDemoSave(generation);
      if (!_presentationCanContinue(generation)) return;
      trip = _demo.tripByCode(initialTrip.code);
      if (trip.status == beforeStatus) {
        throw StateError('The simulated trip stage did not change.');
      }
    }
    if (trip.status != targetStatus) {
      throw StateError(
        'Trip ${trip.code} cannot reach target $targetStatus from ${trip.status}.',
      );
    }
    if (!_presentationCanContinue(generation)) return;
    await _performPresentationAction(
      _presentationTertiaryTargetKey,
      'Return to trip list',
      generation,
      onActivate: () async =>
          _presentationTripDetailsKey.currentState?.backForPresentation(),
    );
  }
}

extension _DemoPresentationOperationsActions on _OperationsShellState {
  Future<void> _inspectPresentationMap(int generation) async {
    if (_presentationTrip == null) {
      throw StateError('No sample vehicle is available to inspect.');
    }
    await _performPresentationAction(
      _presentationPrimaryTargetKey,
      'Open assigned vehicle',
      generation,
      onActivate: () async {
        final map = _presentationMapPageKey.currentState;
        if (map == null) {
          throw StateError('The presentation fleet map is unavailable.');
        }
        map.openVehicleForPresentation();
      },
      scrollController: _presentationMapScrollController,
    );
    await WidgetsBinding.instance.endOfFrame;
    if (!_presentationCanContinue(generation)) return;
    await _performPresentationAction(
      _presentationSecondaryTargetKey,
      'Open its assigned trip',
      generation,
      onActivate: () async {
        final map = _presentationMapPageKey.currentState;
        if (map == null) {
          throw StateError('The vehicle details are unavailable.');
        }
        map.openAssignedTripForPresentation();
      },
      scrollController: _presentationVehicleSheetScrollController,
    );
    await _waitForPresentationState(
      () => _presentationMapTripDetailsKey.currentState != null,
      generation,
      description: 'The vehicle trip details did not open.',
    );
    if (!_presentationCanContinue(generation)) return;
    await _performPresentationAction(
      _presentationFourthTargetKey,
      'Return to fleet map',
      generation,
      onActivate: () async =>
          _presentationMapPageKey.currentState?.backFromTripForPresentation(),
    );
  }

  Future<void> _inspectPresentationAlertHistory(int generation) async {
    for (final section in ['Earlier detections', 'History']) {
      _setPresentationActionState(
        () => _presentation.alertTargetSection = section,
      );
      await WidgetsBinding.instance.endOfFrame;
      await _performPresentationAction(
        _presentationPrimaryTargetKey,
        'Open $section',
        generation,
        onActivate: () async =>
            _setPresentationActionState(() => _alertSection = section),
        scrollController: _presentationAlertsScrollController,
      );
      if (!_presentationCanContinue(generation)) return;
    }
  }

  Future<void> _filterPresentationAlerts(int generation) async {
    final alert = _demo.alertById(_presentationAlertId);
    await _performPresentationAction(
      _presentationPrimaryTargetKey,
      'Filter by ${alert.kind}',
      generation,
      onActivate: () async {
        _setPresentationActionState(() {
          _alertSection = 'Needs action';
          _situationKind = alert.kind;
        });
      },
      scrollController: _presentationAlertsScrollController,
    );
  }

  Future<void> _runPresentationAlertAction(
    String action,
    int generation,
  ) async {
    final alert = _demo.alertById(_presentationAlertId);
    if (alert.isOpen) {
      _setPresentationActionState(() {
        _alertSection = 'Needs action';
        _situationKind = 'All kinds';
      });
      await WidgetsBinding.instance.endOfFrame;
      if (!_presentationCanContinue(generation)) return;
    }
    await _performPresentationAction(
      _presentationPrimaryTargetKey,
      'Open ${alert.title}',
      generation,
      onActivate: () async => _openAlert(alert.id),
      scrollController: _presentationAlertsScrollController,
    );
    await _waitForPresentationState(
      () => _presentationAlertDetailsKey.currentState != null,
      generation,
      description: 'The selected alert details did not open.',
    );

    if (action == 'acknowledge-alert' && alert.isOpen && !alert.acknowledged) {
      await _performPresentationAction(
        _presentationSecondaryTargetKey,
        'Acknowledge alert',
        generation,
        onActivate: () async => _presentationAlertDetailsKey.currentState
            ?.acknowledgeForPresentation(),
        scrollController: _presentationDetailsScrollController,
      );
      await _waitForDemoSave(generation);
      if (_presentationCanContinue(generation) &&
          !_demo.alertById(alert.id).acknowledged) {
        throw StateError('The demo alert was not acknowledged.');
      }
    } else if (action == 'investigate-alert' && alert.isOpen) {
      await _investigatePresentationAlert(alert, generation);
    } else if (action == 'resolve-alert' && alert.isOpen) {
      await _resolvePresentationAlert(alert, generation);
    }

    if (!_presentationCanContinue(generation)) return;
    await _performPresentationAction(
      _presentationSixthTargetKey,
      'Return to alerts',
      generation,
      onActivate: () async =>
          _presentationAlertDetailsKey.currentState?.backForPresentation(),
    );
    if (action == 'resolve-alert' && _presentationCanContinue(generation)) {
      _setPresentationActionState(() => _alertSection = 'History');
    }
  }

  Future<void> _investigatePresentationAlert(
    DemoAlert alert,
    int generation,
  ) async {
    final details = _presentationAlertDetailsKey.currentState;
    if (details == null) {
      throw StateError('The alert investigation controls are unavailable.');
    }
    if (!alert.acknowledged) {
      await _performPresentationAction(
        _presentationSecondaryTargetKey,
        'Acknowledge alert',
        generation,
        onActivate: details.acknowledgeForPresentation,
      );
      await _waitForDemoSave(generation);
    }
    if (!_presentationCanContinue(generation)) return;
    await _performPresentationAction(
      _presentationTertiaryTargetKey,
      'Assign to supervisor',
      generation,
      onActivate: details.assignForPresentation,
      scrollController: _presentationDetailsScrollController,
    );
    await _waitForDemoSave(generation);
    if (_presentationCanContinue(generation) &&
        _demo.alertById(alert.id).supervisor != DemoAlert.supervisors.first) {
      throw StateError('The demo alert assignment was not saved.');
    }
    if (!_presentationCanContinue(generation)) return;
    const presentationNote =
        'Supervisor reviewed the simulated situation and linked trip details.';
    if (!_demo.alertById(alert.id).notes.contains(presentationNote)) {
      await _performPresentationAction(
        _presentationFourthTargetKey,
        'Add investigation note',
        generation,
        onActivate: details.addNoteForPresentation,
        scrollController: _presentationDetailsScrollController,
      );
      await _waitForDemoSave(generation);
      if (_presentationCanContinue(generation) &&
          !_demo.alertById(alert.id).notes.contains(presentationNote)) {
        throw StateError('The investigation note was not saved.');
      }
    }
  }

  Future<void> _resolvePresentationAlert(
    DemoAlert alert,
    int generation,
  ) async {
    if (!alert.acknowledged) {
      await _performPresentationAction(
        _presentationSecondaryTargetKey,
        'Acknowledge before resolution',
        generation,
        onActivate: () async => _presentationAlertDetailsKey.currentState
            ?.acknowledgeForPresentation(),
      );
      await _waitForDemoSave(generation);
    }
    if (!_presentationCanContinue(generation)) return;
    await _performPresentationAction(
      _presentationFifthTargetKey,
      'Resolve simulated situation',
      generation,
      onActivate: () async => _presentationAlertDetailsKey.currentState
          ?.openResolutionConfirmationForPresentation(),
      scrollController: _presentationDetailsScrollController,
    );
    await _waitForPresentationState(
      () => _presentationSeventhTargetKey.currentContext != null,
      generation,
      description: 'The alert resolution confirmation did not open.',
    );
    if (!_presentationCanContinue(generation)) return;
    await _performPresentationAction(
      _presentationSeventhTargetKey,
      'Confirm simulated resolution',
      generation,
      onActivate: () async => _presentationAlertDetailsKey.currentState
          ?.confirmResolutionForPresentation(),
    );
    await _presentationAlertDetailsKey.currentState
        ?.waitForPresentationResolution();
    await _waitForDemoSave(generation);
    if (_presentationCanContinue(generation) &&
        _demo.alertById(alert.id).isOpen) {
      throw StateError('The demo alert was not resolved.');
    }
  }

  Future<void> _recordPresentationVisit(int generation) async {
    final trip = _presentationTrip;
    final vehicle = trip?.vehicle ?? _demo.availableVehicles.firstOrNull;
    if (vehicle == null) {
      throw StateError('No sample vehicle is available for a site visit.');
    }
    final assignedTrip =
        _demo.trips.where((item) => item.vehicle == vehicle).firstOrNull;
    _setPresentationActionState(() {
      _visitVehicle = vehicle;
      _visitTripCode = trip?.code ?? assignedTrip?.code;
    });
    var presentationVisit = _presentation.visitId == null
        ? null
        : _demo.visits
            .where((visit) => visit.id == _presentation.visitId)
            .firstOrNull;
    if (presentationVisit == null) {
      presentationVisit = _demo.visits
          .where((visit) =>
              visit.vehicle == vehicle &&
              visit.site == _visitSite &&
              visit.tripCode == (trip?.code ?? assignedTrip?.code))
          .toList()
          .lastOrNull;
      if (presentationVisit != null) {
        _presentation.visitId = presentationVisit.id;
      }
    }
    if (presentationVisit == null) {
      await _performPresentationAction(
        _presentationPrimaryTargetKey,
        'Record site arrival',
        generation,
        onActivate: () async {
          await _saveDemo(
            () => _demo.recordSiteArrival(
              vehicle: vehicle,
              site: _visitSite,
              tripCode: _visitTripCode,
              now: DateTime.now(),
            ),
            'Sample site arrival recorded and saved.',
          );
        },
        scrollController: _presentationMoreScrollController,
      );
      await _waitForDemoSave(generation);
      if (!_presentationCanContinue(generation)) return;
      presentationVisit = _demo.openVisits
          .where((visit) =>
              visit.vehicle == vehicle &&
              visit.site == _visitSite &&
              visit.tripCode == _visitTripCode)
          .firstOrNull;
      if (presentationVisit == null) {
        throw StateError('The simulated site arrival was not recorded.');
      }
      _presentation.visitId = presentationVisit.id;
    }
    if (!presentationVisit.isOpen) {
      if (!presentationVisit.isCompleted) {
        throw StateError('The simulated site visit is incomplete.');
      }
      return;
    }
    final openVisit = presentationVisit;
    await _performPresentationAction(
      _presentationPrimaryTargetKey,
      'Record site departure',
      generation,
      onActivate: () async {
        await _saveDemo(
          () => _demo.recordSiteDeparture(openVisit.id, DateTime.now()),
          'Sample site departure recorded.',
        );
      },
      scrollController: _presentationMoreScrollController,
    );
    await _waitForDemoSave(generation);
    if (_presentationCanContinue(generation) &&
        _demo.visits
            .where((visit) => visit.id == openVisit.id)
            .any((visit) => !visit.isCompleted)) {
      throw StateError('The simulated site departure was not recorded.');
    }
  }

  Future<void> _inspectPresentationReports(
    DemoPathAudience role,
    int generation,
  ) async {
    final sections = role == DemoPathAudience.administrator
        ? const [
            'Demo analytics',
            'Customer visits',
            'Maintenance',
            'Fleet assets and instruments',
            'Guided questions',
          ]
        : const ['Demo analytics', 'Customer visits'];
    for (final section in sections) {
      if (!_presentationCanContinue(generation)) return;
      _setPresentationActionState(
        () => _presentation.reportSection = section,
      );
      await WidgetsBinding.instance.endOfFrame;
      final reports = _presentationReportsPageKey.currentState;
      if (reports == null) {
        throw StateError('The reports workspace is unavailable.');
      }
      await _performPresentationAction(
        _presentationPrimaryTargetKey,
        'Review $section report',
        generation,
        onActivate: () async => reports.selectSectionForPresentation(section),
        scrollController: _presentationReportsScrollController,
      );
    }
  }

  Future<void> _inspectPresentationIntelligence(int generation) async {
    for (final days in [7, 30, 90]) {
      if (!_presentationCanContinue(generation)) return;
      await _performPresentationAction(
        _presentationPrimaryTargetKey,
        'Review $days-day intelligence',
        generation,
        onActivate: () async =>
            _setPresentationActionState(() => _intelligenceDays = days),
        scrollController: _presentationMoreScrollController,
      );
    }
  }

  Future<void> _inspectPresentationWorkspace(int generation) =>
      _performPresentationAction(
        _presentationPageTargetKey,
        'Review informational workspace',
        generation,
        scrollController: _presentationMoreScrollController,
      );

  Future<void> _inspectPresentationVisitsReport(int generation) async {
    _setPresentationActionState(
      () => _presentation.reportSection = 'Customer visits',
    );
    await WidgetsBinding.instance.endOfFrame;
    await _performPresentationAction(
      _presentationPrimaryTargetKey,
      'Review recorded customer visits',
      generation,
      scrollController: _presentationReportsScrollController,
    );
  }
}
