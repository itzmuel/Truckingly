part of 'main.dart';

extension _OperationsAlertsView on _OperationsShellState {
  Widget _alertsPage() {
    final presentationAction =
        _presentationActive ? _presentationCurrentStep.action : '';
    final inspectSelectedAlert = const {
      'inspect-alert',
      'acknowledge-alert',
      'investigate-alert',
      'resolve-alert',
    }.contains(presentationAction);
    final visibleAlerts = _demo.openAlerts
        .where((alert) =>
            _situationKind == 'All kinds' || alert.kind == _situationKind)
        .toList();
    final needsAction = _alertSection == 'Needs action';
    final isHistory = _alertSection == 'History';
    final history = _historyOutcome == 'All closed situations' ||
            _historyOutcome == 'Closed by a person'
        ? _demo.resolvedAlerts
        : <DemoAlert>[];
    final explanation = switch (_alertSection) {
      'Needs action' =>
        'Current trips first, then completed work whose figures are held back for confirmation, then vehicle condition with no trip waiting. Within each group: critical, warning and information, then ungraded situations, then longest-waiting first. The order is provisional.\n\nDumptrak alerts, overdue maintenance positions and completion evidence refused by Settlement are included. FleetOps asset economics is shown to administrators only.',
      'Earlier detections' =>
        'Conditions found on an earlier day, with no evidence from today that they continue, and findings without an explanation Dumptrak can show. None is resolved: each stays open until closed or seen again today, when it returns to Needs action.',
      'History' =>
        'How each situation left the queue. Nothing here is deleted; a closed or superseded situation does not mean the vehicle is now fine.',
      _ =>
        'Completed deliveries, published documents and manual overrides. These records are kept for later questions and are never counted as work.',
    };

    return _pageScroll([
      _pageHeading(
        'Alerts',
        'Real-time incident detection & fleet status',
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final section in _OperationsShellState._alertSections)
            KeyedSubtree(
              key: _presentationActive &&
                      _presentationCurrentStep.action ==
                          'inspect-alert-history' &&
                      section == _presentationAlertTargetSection
                  ? _presentationPrimaryTargetKey
                  : null,
              child: ChoiceChip(
                key: ValueKey('alert-section-$section'),
                showCheckmark: false,
                label: Text(switch (section) {
                  'Needs action' => 'Needs Action (${_demo.openAlerts.length})',
                  'Earlier detections' => 'Recent Detections',
                  'History' => 'System History',
                  _ => 'Info Records',
                }),
                selected: _alertSection == section,
                onSelected: (_) => _setPresentationActionState(
                  () => _alertSection = section,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      const DemoNotice(
        message:
            'Operating in simulation mode. All incidents are sample records and do not reflect real-time physical assets.',
        neutral: true,
      ),
      const SizedBox(height: 20),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: needsAction ? 'Pending Actions' : _alertSection,
            action: needsAction
                ? KeyedSubtree(
                    key: _presentationActive &&
                            _presentationCurrentStep.action == 'filter-alerts'
                        ? _presentationPrimaryTargetKey
                        : null,
                    child: PopupMenuButton<String>(
                      key: const ValueKey('situation-kind-filter'),
                      tooltip: 'Filter incidents by kind',
                      initialValue: _situationKind,
                      onSelected: (value) => _setPresentationActionState(
                        () => _situationKind = value,
                      ),
                      itemBuilder: (context) => [
                        for (final kind
                            in _OperationsShellState._situationKinds)
                          PopupMenuItem(value: kind, child: Text(kind)),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _situationKind == 'All kinds'
                                  ? 'All incidents'
                                  : 'Filtered',
                              style:
                                  const TextStyle(color: _blue, fontSize: 12),
                            ),
                            const Icon(Icons.expand_more_rounded,
                                size: 16, color: _blue),
                          ],
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            needsAction
                ? '${visibleAlerts.length} open sample situations'
                : '${isHistory ? history.length : 0} records',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          if (needsAction) ...[
            if (_situationKind != 'All kinds') ...[
              Text('Kind: $_situationKind',
                  style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 12),
            ],
            if (visibleAlerts.isEmpty)
              const EmptyState(
                icon: Icons.help_outline_rounded,
                title: 'No situations match this kind',
                detail:
                    'Try All kinds to see the sample action queue. Missing reports are not proof that vehicles are operating normally.',
              )
            else
              for (final alert in visibleAlerts) ...[
                AlertCard(
                  key: ValueKey('alert-card-${alert.id}'),
                  title: alert.title,
                  detail: alert.detail,
                  severity: alert.severity,
                  icon: _alertIcon(alert),
                  reference:
                      '${_trips.firstWhere((trip) => trip.code == alert.tripCode).vehicle} · ${alert.tripCode}',
                  expanded: true,
                  presentationManageKey:
                      inspectSelectedAlert && alert.id == _presentationAlertId
                          ? _presentationPrimaryTargetKey
                          : null,
                  onAction: (_) => _openAlert(alert.id),
                ),
                const SizedBox(height: 10),
              ],
          ] else ...[
            if (isHistory) ...[
              _alertFilter(
                filterKey: 'history-outcome-filter',
                label: 'How it left the queue (optional)',
                value: _historyOutcome,
                options: _OperationsShellState._historyOutcomes,
                onChanged: (value) => _setPresentationActionState(
                  () => _historyOutcome = value,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Shows how situations left the queue: superseded when their trip ended, closed by a person, or cleared by new evidence.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
              const ExpansionTile(
                key: PageStorageKey('history-guidance'),
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'More about how it left the queue',
                  style: TextStyle(fontSize: 13),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Superseded situations concerned a trip that was completed or cancelled. Closed situations were dealt with by a person; this does not say the condition cleared. Cleared situations ended because evidence changed, such as a tracker reporting again or tonnes being confirmed. Closed earlier means the way it ended was not recorded.',
                      style:
                          TextStyle(color: _muted, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
            if (isHistory && history.isNotEmpty)
              for (final alert in history) ...[
                ListTile(
                  key: ValueKey('history-alert-${alert.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(alert.title),
                  subtitle: Text(
                    '${alert.tripCode} · Closed by a person\n${alert.resolution}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openAlert(alert.id),
                ),
                const SizedBox(height: 8),
              ]
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  isHistory && _historyOutcome != 'All closed situations'
                      ? 'Nothing recorded for "$_historyOutcome".'
                      : 'Nothing recorded here.',
                  style: const TextStyle(color: _muted),
                ),
              ),
          ],
          const SizedBox(height: 8),
          PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UNDERSTANDING ALERTS',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Priority Flow: Critical safety hazards → Trip interruptions → Maintenance warnings → Informational telemetry updates.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
                ),
                const SizedBox(height: 12),
                Text(
                  explanation,
                  style:
                      const TextStyle(color: _muted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ], controller: _presentationAlertsScrollController);
  }

  IconData _alertIcon(DemoAlert alert) => alert.kind == 'Tracking'
      ? Icons.cell_tower_rounded
      : Icons.fact_check_outlined;

  Widget _alertFilter({
    required String filterKey,
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey(filterKey),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(option, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
