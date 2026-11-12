import 'package:flutter/material.dart';

import 'demo_store.dart';
import 'trip_wizard.dart';

class TripDetails extends StatefulWidget {
  const TripDetails({super.key, required this.store, required this.code});

  final DemoStore store;
  final String code;

  @override
  State<TripDetails> createState() => _TripDetailsState();
}

class _TripDetailsState extends State<TripDetails> {
  bool _saving = false;
  String? _error;

  Future<void> _advance() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.advanceTrip(widget.code, DateTime.now());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulated trip stage saved locally.')),
      );
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _error =
            'Could not advance demo trip: $error. No changes were applied. Retry when ready.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit(Trip trip) async {
    final updated = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(
        builder: (context) => TripWizard(store: widget.store, trip: trip),
        fullscreenDialog: true,
      ),
    );
    if (!mounted || updated == null) return;
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo assignments updated and saved locally.')),
    );
  }

  String _timestamp(DateTime at) {
    final local = at.toUtc().add(const Duration(hours: 1));
    String pad(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${pad(local.month)}-${pad(local.day)} '
        '${pad(local.hour)}:${pad(local.minute)}:${pad(local.second)} · Africa/Lagos';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, child) {
        final matching =
            widget.store.trips.where((trip) => trip.code == widget.code);
        final trip = matching.isEmpty ? null : matching.first;
        final busy = _saving || widget.store.saving;
        return PopScope<void>(
          canPop: !busy,
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.code),
              leading: IconButton(
                tooltip: 'Back to trips',
                onPressed: busy ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'DEMO / SIMULATED DATA',
                    style: TextStyle(
                        color: Color(0xFF0088FF), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (trip == null)
                    const Text('This trip is no longer in the saved demo. '
                        'It may have been removed by Reset Demo.')
                  else ...[
                    Text('Status: ${trip.status}',
                        key: const ValueKey('trip-detail-status'),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final (label, value) in [
                              ('Route', trip.route),
                              ('Project', trip.project ?? 'Not assigned in this sample'),
                              ('Driver', trip.driver ?? 'Not assigned in this sample'),
                              ('Vehicle', trip.vehicle),
                              ('Material', trip.material),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text('$label: $value',
                                    style: const TextStyle(height: 1.5)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const ValueKey('edit-trip'),
                      onPressed: busy || !trip.canEdit ? null : () => _edit(trip),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit demo assignments'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Assignments can be edited while Planned, Dispatched, or At origin. '
                      'Once the trip leaves its origin, assignments are read-only.',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    const Text('Journey timeline',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'Stages are simulated, not GPS observations or proof of delivery. '
                      'Past stages without a saved event are not verified history.',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    for (final status in Trip.journey)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          status == trip.status
                              ? Icons.radio_button_checked
                              : trip.events.any((event) => event.status == status)
                                  ? Icons.check_circle_outline
                                  : Icons.radio_button_unchecked,
                          color: status == trip.status
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        title: Text(status),
                        subtitle: Text(
                          trip.events.any((event) => event.status == status)
                              ? _timestamp(trip.events
                                  .lastWhere((event) => event.status == status).at)
                              : status == trip.status
                                  ? 'Current sample stage · Timestamp not recorded'
                                  : 'No simulated event recorded',
                        ),
                      ),
                    if (trip.completedAt != null)
                      Text(
                        'Simulated completion: ${_timestamp(trip.completedAt!)}',
                      ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
                    if (busy) const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('advance-trip'),
                      onPressed: busy || !trip.canAdvance ? null : _advance,
                      icon: const Icon(Icons.skip_next_rounded),
                      label: Text(trip.canAdvance
                          ? 'Simulate: ${Trip.journey[Trip.journey.indexOf(trip.status) + 1]}'
                          : 'No further journey stages'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Advances only this trip and saves on this device. '
                      'No driver is notified, no funds move, and open alerts are not automatically resolved.',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
