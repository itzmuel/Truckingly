part of 'main.dart';

extension _OperationsShellActions on _OperationsShellState {
  Widget _mapPage() {
    final isPresentationMap =
        _presentationActive && _presentationCurrentStep.action == 'inspect-map';
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

  void _openAlert(String id) {
    final isPresentationAlert =
        _presentationActive && _presentationCurrentStep.screen == 'Alerts';
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => AlertDetails(
          key: isPresentationAlert ? _presentationAlertDetailsKey : null,
          store: _demo,
          id: id,
          scrollController: _presentationDetailsScrollController,
          presentationAcknowledgeKey:
              isPresentationAlert ? _presentationSecondaryTargetKey : null,
          presentationAssignKey:
              isPresentationAlert ? _presentationTertiaryTargetKey : null,
          presentationNoteKey:
              isPresentationAlert ? _presentationFourthTargetKey : null,
          presentationResolveKey:
              isPresentationAlert ? _presentationFifthTargetKey : null,
          presentationConfirmResolveKey:
              isPresentationAlert ? _presentationSeventhTargetKey : null,
          presentationBackKey:
              isPresentationAlert ? _presentationSixthTargetKey : null,
        ),
      ),
    );
  }

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

  Future<Trip?> _showCreateTrip({
    GlobalKey? presentationNextKey,
    ValueChanged<Trip>? onPresentationTripCreated,
  }) async {
    final trip = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => TripWizard(
          key: presentationNextKey == null ? null : _presentationTripWizardKey,
          store: _demo,
          presentationNextKey: presentationNextKey,
          onPresentationTripCreated: onPresentationTripCreated,
        ),
      ),
    );
    if (trip == null || !mounted) return null;
    _setPresentationActionState(
      () => _selectedTripStatus = 'All statuses',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${trip.code} created as Planned. Demo saved locally.'),
      ),
    );
    return trip;
  }

  void _openTrip(String code) {
    final isPresentationTrip =
        _presentationActive && _presentationCurrentStep.screen == 'Trips';
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => TripDetails(
          key: isPresentationTrip ? _presentationTripDetailsKey : null,
          store: _demo,
          code: code,
          presentationEditKey: isPresentationTrip &&
                  _presentationCurrentStep.action == 'edit-trip'
              ? _presentationSecondaryTargetKey
              : null,
          presentationAdvanceKey: isPresentationTrip &&
                  _presentationCurrentStep.action == 'progress-trip'
              ? _presentationSecondaryTargetKey
              : null,
          presentationWizardKey: isPresentationTrip &&
                  _presentationCurrentStep.action == 'edit-trip'
              ? _presentationTripWizardKey
              : null,
          presentationWizardNextKey: isPresentationTrip &&
                  _presentationCurrentStep.action == 'edit-trip'
              ? _presentationFourthTargetKey
              : null,
          presentationBackKey:
              isPresentationTrip ? _presentationTertiaryTargetKey : null,
          scrollController:
              isPresentationTrip ? _presentationDetailsScrollController : null,
        ),
      ),
    );
  }
}
