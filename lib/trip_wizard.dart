import 'package:flutter/material.dart';

import 'demo_store.dart';
import 'demo_trip_catalog.dart';

class TripWizard extends StatefulWidget {
  const TripWizard({super.key, required this.store, this.trip});

  final DemoStore store;
  final Trip? trip;

  @override
  State<TripWizard> createState() => _TripWizardState();
}

class _TripWizardState extends State<TripWizard> {
  final _form = GlobalKey<FormState>();
  int _step = 0;
  String? _project;
  String? _origin;
  String? _destination;
  String? _driver;
  String? _vehicle;
  String? _material;
  String? _error;
  bool _saving = false;
  bool get _editing => widget.trip != null;
  List<String> get _drivers => widget.store.driversFor(widget.trip?.code);
  List<String> get _vehicles => widget.store.vehiclesFor(widget.trip?.code);

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    if (trip != null) {
      _project = trip.project;
      final stops = trip.route.split(' → ');
      _origin = stops.first;
      _destination = stops.last;
      _driver = trip.driver;
      _vehicle = trip.vehicle;
      _material = trip.material;
    }
  }

  Future<void> _create() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final draft = DemoTripDraft(
        project: _project!,
        origin: _origin!,
        destination: _destination!,
        driver: _driver!,
        vehicle: _vehicle!,
        material: _material!,
      );
      final trip = _editing
          ? await widget.store.editTrip(widget.trip!.code, draft)
          : await widget.store.createTrip(draft);
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).pop(trip);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _editing
            ? 'Could not save demo trip: $error. No changes were applied. Review your selections or retry.'
            : 'Could not create demo trip: $error. No trip was added. Review your selections or retry.';
      });
    }
  }

  Widget _select(String key, String label, String? value, List<String> options,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        key: ValueKey('new-trip-$key'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: '$label (required)'),
        items: [
          for (final option in options)
            DropdownMenuItem(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
        ],
        validator: (selected) =>
            selected == null ? 'Choose a sample ${label.toLowerCase()}.' : null,
        onChanged: _saving ? null : onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Trip>(
      canPop: !_saving && _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saving) setState(() => _step--);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editing ? 'Edit ${widget.trip!.code}' : 'New demo trip'),
          leading: IconButton(
            tooltip: _step == 0 ? 'Close wizard' : 'Previous step',
            onPressed: _saving
                ? null
                : () {
                    if (_step == 0) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() => _step--);
                    }
                  },
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
              const SizedBox(height: 8),
              const Text(
                'Sample assignments only. Nothing is dispatched to a real driver or production system.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(value: (_step + 1) / 3),
              const SizedBox(height: 16),
              Text(
                'Step ${_step + 1} of 3 · ${['Route & project', 'Assignments', 'Review'][_step]}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_step == 0) ...[
                      _select('project', 'Project', _project,
                          DemoTripCatalog.projects,
                          (value) => setState(() => _project = value)),
                      _select('origin', 'Origin', _origin,
                          DemoTripCatalog.origins,
                          (value) => setState(() => _origin = value)),
                      _select('destination', 'Destination', _destination,
                          DemoTripCatalog.destinations,
                          (value) => setState(() => _destination = value)),
                    ] else if (_step == 1) ...[
                      if (_vehicles.isEmpty || _drivers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Text(
                            'No free demo assignments remain. Close this wizard and complete existing trips using Demo controls, or reset the demo.',
                          ),
                        ),
                      _select('driver', 'Driver', _driver,
                          _drivers,
                          (value) => setState(() => _driver = value)),
                      _select('vehicle', 'Vehicle', _vehicle,
                          _vehicles,
                          (value) => setState(() => _vehicle = value)),
                      _select('material', 'Material', _material,
                          DemoTripCatalog.materials,
                          (value) => setState(() => _material = value)),
                      const Text(
                        'Only sample drivers and vehicles without an active demo trip are available.',
                      ),
                    ] else ...[
                      for (final (label, value) in [
                        ('Project', _project),
                        ('Origin', _origin),
                        ('Destination', _destination),
                        ('Driver', _driver),
                        ('Vehicle', _vehicle),
                        ('Material', _material),
                        (_editing ? 'Status (unchanged)' : 'Initial status',
                            widget.trip?.status ?? 'Planned'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text('$label: $value',
                              style: const TextStyle(height: 1.5)),
                        ),
                      const Text(
                        'The trip will be saved on this device. Open trip details to advance its simulated journey.',
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_saving) const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const ValueKey('wizard-next'),
                      onPressed: _saving
                          ? null
                          : () {
                              if (_step == 2) {
                                _create();
                              } else if (_form.currentState!.validate()) {
                                setState(() {
                                  _step++;
                                  _error = null;
                                });
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_saving
                            ? 'Saving demo trip…'
                            : _step == 2
                                ? (_editing ? 'Save demo changes' : 'Create demo trip')
                                : 'Continue'),
                      ),
                    ),
                    if (_step > 0)
                      TextButton(
                        onPressed:
                            _saving ? null : () => setState(() => _step--),
                        child: const Text('Back'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
