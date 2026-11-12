import 'package:flutter/material.dart';

import 'demo_store.dart';

class AlertDetails extends StatefulWidget {
  const AlertDetails({
    super.key,
    required this.store,
    required this.id,
    this.presentationAcknowledgeKey,
    this.presentationAssignKey,
    this.presentationNoteKey,
    this.presentationResolveKey,
    this.presentationConfirmResolveKey,
    this.presentationBackKey,
    this.scrollController,
  });

  final DemoStore store;
  final String id;
  final GlobalKey? presentationAcknowledgeKey;
  final GlobalKey? presentationAssignKey;
  final GlobalKey? presentationNoteKey;
  final GlobalKey? presentationResolveKey;
  final GlobalKey? presentationConfirmResolveKey;
  final GlobalKey? presentationBackKey;
  final ScrollController? scrollController;

  @override
  AlertDetailsState createState() => AlertDetailsState();
}

class AlertDetailsState extends State<AlertDetails> {
  final _note = TextEditingController();
  final _reason = TextEditingController();
  String? _supervisor;
  String? _error;
  bool _saving = false;
  Future<void>? _presentationResolution;

  Future<void> acknowledgeForPresentation() => _acknowledge();

  Future<void> investigateForPresentation() async {
    final alert = widget.store.alertById(widget.id);
    if (!alert.isOpen) return;
    await _acknowledge();
    await assignForPresentation();
    await addNoteForPresentation();
  }

  Future<void> assignForPresentation() async {
    if (_saving || !widget.store.alertById(widget.id).isOpen) return;
    await _save(
      () => widget.store.assignAlert(widget.id, DemoAlert.supervisors.first),
    );
  }

  Future<void> addNoteForPresentation() async {
    if (_saving || !widget.store.alertById(widget.id).isOpen) return;
    await _save(
      () => widget.store.addAlertNote(
        widget.id,
        'Supervisor reviewed the simulated situation and linked trip details.',
      ),
    );
  }

  void openResolutionConfirmationForPresentation() {
    if (_saving || !widget.store.alertById(widget.id).isOpen) return;
    _reason.text =
        'Resolved for the stakeholder demonstration; underlying conditions are not verified.';
    _presentationResolution = _resolve();
  }

  void confirmResolutionForPresentation() => Navigator.of(context).pop(true);

  Future<void> waitForPresentationResolution() async {
    await _presentationResolution;
  }

  void backForPresentation() => _back();

  void _back() {
    if (_saving) return;
    Navigator.pop(context);
  }

  Future<void> _acknowledge() async {
    final alert = widget.store.alertById(widget.id);
    if (_saving || !alert.isOpen || alert.acknowledged) return;
    await _save(() => widget.store.acknowledgeAlert(widget.id));
  }

  @override
  void dispose() {
    _note.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save(Future<void> Function() action,
      {VoidCallback? onSaved}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      onSaved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulated alert change saved locally.')),
      );
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _error =
            'Could not save demo alert: $error. No changes were applied. Review and retry.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resolve() async {
    if (_reason.text.trim().isEmpty || _reason.text.trim().length > 500) {
      setState(() => _error = 'Enter a resolution summary (1–500 characters).');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve simulated alert?'),
        content: const Text(
          'This moves the demo alert into History. It does not repair telemetry, verify tonnage, '
          'notify a real supervisor, or prove that a vehicle is safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          KeyedSubtree(
            key: widget.presentationConfirmResolveKey,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Resolve demo alert'),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _save(() =>
          widget.store.resolveAlert(widget.id, _reason.text, DateTime.now()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, child) {
        final matching =
            widget.store.alerts.where((alert) => alert.id == widget.id);
        final alert = matching.isEmpty ? null : matching.first;
        final busy = _saving || widget.store.saving;
        return PopScope<void>(
          canPop: !busy,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Demo alert'),
              leading: widget.presentationBackKey == null
                  ? IconButton(
                      tooltip: 'Back to alerts',
                      onPressed: busy ? null : _back,
                      icon: const Icon(Icons.arrow_back),
                    )
                  : KeyedSubtree(
                      key: widget.presentationBackKey,
                      child: IconButton(
                        tooltip: 'Back to alerts',
                        onPressed: busy ? null : _back,
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
            ),
            body: SafeArea(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('DEMO / SIMULATED DATA',
                      style: TextStyle(
                          color: Color(0xFF0088FF),
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const Text(
                    'Local demonstration only. No real operational action, notification, '
                    'telemetry reset, delivery verification, or financial transaction occurs.',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  if (alert == null)
                    const Text('This alert is no longer in the saved demo.')
                  else ...[
                    Text(alert.title,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(
                        '${alert.tripCode} · ${alert.kind} · ${alert.severity}'),
                    const SizedBox(height: 12),
                    Text(alert.detail, style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 20),
                    Text(
                      'Status: ${!alert.isOpen ? 'Resolved · Closed by a person' : alert.acknowledged ? 'Acknowledged · Still open' : 'Open · Not acknowledged'}',
                      key: const ValueKey('alert-detail-status'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        'Assigned supervisor: ${alert.supervisor ?? 'Unassigned'}'),
                    const SizedBox(height: 20),
                    if (alert.isOpen) ...[
                      KeyedSubtree(
                        key: widget.presentationAcknowledgeKey,
                        child: FilledButton(
                          key: const ValueKey('acknowledge-alert'),
                          onPressed:
                              busy || alert.acknowledged ? null : _acknowledge,
                          child: Text(alert.acknowledged
                              ? 'Acknowledged'
                              : 'Acknowledge demo alert'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        key: const ValueKey('alert-supervisor'),
                        initialValue: _supervisor ?? alert.supervisor,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Sample supervisor'),
                        items: [
                          for (final name in DemoAlert.supervisors)
                            DropdownMenuItem(value: name, child: Text(name)),
                        ],
                        onChanged: busy
                            ? null
                            : (value) => setState(() => _supervisor = value),
                      ),
                      const SizedBox(height: 8),
                      KeyedSubtree(
                        key: widget.presentationAssignKey,
                        child: OutlinedButton(
                          key: const ValueKey('assign-alert'),
                          onPressed: busy ||
                                  (_supervisor ?? alert.supervisor) == null
                              ? null
                              : () => _save(() => widget.store.assignAlert(
                                  widget.id, _supervisor ?? alert.supervisor!)),
                          child: const Text('Save demo assignment'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        key: const ValueKey('alert-note'),
                        controller: _note,
                        enabled: !busy,
                        maxLength: 500,
                        minLines: 2,
                        maxLines: 5,
                        decoration:
                            const InputDecoration(labelText: 'Add a demo note'),
                      ),
                      KeyedSubtree(
                        key: widget.presentationNoteKey,
                        child: OutlinedButton(
                          key: const ValueKey('save-alert-note'),
                          onPressed: busy
                              ? null
                              : () => _save(
                                  () => widget.store
                                      .addAlertNote(widget.id, _note.text),
                                  onSaved: _note.clear),
                          child: const Text('Save note'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text('Saved notes',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (alert.notes.isEmpty) const Text('No demo notes yet.'),
                    for (final note in alert.notes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(note, style: const TextStyle(height: 1.5)),
                      ),
                    const SizedBox(height: 20),
                    if (alert.isOpen) ...[
                      TextField(
                        key: const ValueKey('alert-resolution'),
                        controller: _reason,
                        enabled: !busy,
                        maxLength: 500,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                            labelText: 'Resolution summary (required)'),
                      ),
                      KeyedSubtree(
                        key: widget.presentationResolveKey,
                        child: FilledButton(
                          key: const ValueKey('resolve-alert'),
                          onPressed: busy ? null : _resolve,
                          child: const Text('Resolve in demo'),
                        ),
                      ),
                    ] else ...[
                      Text('Resolution: ${alert.resolution}'),
                      const SizedBox(height: 12),
                      Text(
                          'Simulated closure time (UTC): ${alert.resolvedAt!.toUtc().toIso8601String()}'),
                      const SizedBox(height: 12),
                      const Text(
                          'History is read-only. Closure does not demonstrate that the underlying condition cleared.'),
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
                    if (busy) const LinearProgressIndicator(),
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
